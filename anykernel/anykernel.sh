# AnyKernel 2.0 Ramdisk Mod Script 
# osm0sis @ xda-developers

## AnyKernel setup
# EDIFY properties
kernel.string=Installation Start
do.devicecheck=1
do.initd=1
do.modules=0
do.cleanup=1
device.name1=MAKO
device.name2=mako
device.name3=Nexus 4
device.name4=4
device.name5=Nexus

# shell variables
block=/dev/block/platform/msm_sdcc.1/by-name/boot;
initd=/system/etc/init.d;
## end setup


## AnyKernel methods (DO NOT CHANGE)
# set up extracted files and directories
ramdisk=/tmp/anykernel/ramdisk;
bin=/tmp/anykernel/tools;
split_img=/tmp/anykernel/split_img;
patch=/tmp/anykernel/patch;

chmod -R 755 $bin;
mkdir -p $ramdisk $split_img;
cd $ramdisk;

OUTFD=`ps | grep -v "grep" | grep -oE "update(.*)" | cut -d" " -f3`;
ui_print() { echo "ui_print $1" >&$OUTFD; echo "ui_print" >&$OUTFD; }

# dump boot and extract ramdisk
dump_boot() {
  dd if=$block of=/tmp/anykernel/boot.img;
  $bin/unpackbootimg -i /tmp/anykernel/boot.img -o $split_img;
  if [ $? != 0 ]; then
    ui_print " "; ui_print "Dumping/unpacking image failed. Aborting...";
    echo 1 > /tmp/anykernel/exitcode; exit;
  fi;
  gunzip -c $split_img/boot.img-ramdisk.gz | cpio -i;
}

# repack ramdisk then build and write image
write_boot() {
  cd $split_img;
  cmdline=`cat *-cmdline`;
  board=`cat *-board`;
  base=`cat *-base`;
  pagesize=`cat *-pagesize`;
  kerneloff=`cat *-kerneloff`;
  ramdiskoff=`cat *-ramdiskoff`;
  tagsoff=`cat *-tagsoff`;
  if [ -f *-second ]; then
    second=`ls *-second`;
    second="--second $split_img/$second";
    secondoff=`cat *-secondoff`;
    secondoff="--second_offset $secondoff";
  fi;
  if [ -f /tmp/anykernel/dtb ]; then
    dtb="--dt /tmp/anykernel/dtb";
  elif [ -f *-dtb ]; then
    dtb=`ls *-dtb`;
    dtb="--dt $split_img/$dtb";
  fi;
  cd $ramdisk;
  find . | cpio -H newc -o | gzip > /tmp/anykernel/ramdisk-new.cpio.gz;
  $bin/mkbootimg --kernel /tmp/anykernel/zImage --ramdisk /tmp/anykernel/ramdisk-new.cpio.gz $second --cmdline "$cmdline" --board "$board" --base $base --pagesize $pagesize --kernel_offset $kerneloff --ramdisk_offset $ramdiskoff $secondoff --tags_offset $tagsoff $dtb --output /tmp/anykernel/boot-new.img;
  if [ $? != 0 -o `wc -c < /tmp/anykernel/boot-new.img` -gt `wc -c < /tmp/anykernel/boot.img` ]; then
    ui_print " "; ui_print "Repacking image failed. Aborting...";
    echo 1 > /tmp/anykernel/exitcode; exit;
  fi;
  dd if=/tmp/anykernel/boot-new.img of=$block;
}

# backup_file <file>
backup_file() { cp $1 $1~; }

# replace_string <file> <if search string> <original string> <replacement string>
replace_string() {
  if [ -z "$(grep "$2" $1)" ]; then
      sed -i "s;${3};${4};" $1;
  fi;
}

# insert_line <file> <if search string> <before/after> <line match string> <inserted line>
insert_line() {
  if [ -z "$(grep "$2" $1)" ]; then
    case $3 in
      before) offset=0;;
      after) offset=1;;
    esac;
    line=$((`grep -n "$4" $1 | cut -d: -f1` + offset));
    sed -i "${line}s;^;${5};" $1;
  fi;
}

# replace_line <file> <line replace string> <replacement line>
replace_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | cut -d: -f1`;
    sed -i "${line}s;.*;${3};" $1;
  fi;
}

# remove_line <file> <line match string>
remove_line() {
  if [ ! -z "$(grep "$2" $1)" ]; then
    line=`grep -n "$2" $1 | cut -d: -f1`;
    sed -i "${line}d" $1;
  fi;
}

# prepend_file <file> <if search string> <patch file>
prepend_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo "$(cat $patch/$3 $1)" > $1;
  fi;
}

# append_file <file> <if search string> <patch file>
append_file() {
  if [ -z "$(grep "$2" $1)" ]; then
    echo -ne "\n" >> $1;
    cat $patch/$3 >> $1;
    echo -ne "\n" >> $1;
  fi;
}

# replace_file <file> <permissions> <patch file>
replace_file() {
  cp -fp $patch/$3 $1;
  chmod $2 $1;
}

## end methods

## AnyKernel permissions
# set permissions for included files
chmod -R 755 $ramdisk

## AnyKernel install
dump_boot;

# begin ramdisk changes

# insert initd scripts
#cp -fp $patch/init.d/* $initd
#chmod -R 766 $initd

# adb secure
replace_string default.prop "ro.adb.secure=0" "ro.adb.secure=1" "ro.adb.secure=0";
replace_string default.prop "ro.secure=0" "ro.secure=1" "ro.secure=0";

## remove unncessary binaries and stuff
# init.rc
sed -i "/# Run sysinit/d" init.rc;
sed -i "/start sysinit/d" init.rc;
sed -i ':a;N;$!ba;s/service sysinit \/system\/bin\/sysinit\n[ ]\+user root\n[ ]\+oneshot\n[ ]\+disabled//g' init.rc;
# system binaries
rm /system/bin/mpdecision
rm /system/bin/thermald
rm /system/lib/hw/power.msm8960.so
rm /system/lib/hw/power.mako.so
# init.mako.rc
sed -i "/import init.mako_tiny.rc/d" init.mako.rc;
sed -i "/import init.mako_svelte.rc/d" init.mako.rc;
sed -i ':a;N;$!ba;s/service mpdecision \/system\/bin\/mpdecision --no_sleep --avg_comp\n[ ]\+class main\n[ ]\+user root\n[ ]\+group root system//g' init.mako.rc;
sed -i ':a;N;$!ba;s/service thermald \/system\/bin\/thermald\n[ ]\+class main\n[ ]\+group radio system//g' init.mako.rc;
sed -i "/mpdecision/d" init.mako.rc;
sed -i "/thermald/d" init.mako.rc;
sed -i "/scaling_governor/ s/ondemand/interactive/g" init.mako.rc;

## Kernel tunables
insert_line init.mako.rc "txuki_confg" after "import init.mako.usb.rc" "import init.txuki_confg.rc\n";

# adjust vibrator amplitude
replace_line init.mako.rc "write /sys/class/timed_output/vibrator/amp 70" "    write /sys/class/timed_output/vibrator/amp 65";

# Enable Power modes and set the CPU Freq Sampling rates
replace_string init.mako.rc "/cpufreq/interactive/" "/cpufreq/ondemand/" "/cpufreq/interactive/";
replace_string init.mako.rc "conservative" "powersave" "conservative";
replace_string init.mako.rc "go_hispeed_load" "up_threshold" "go_hispeed_load";
replace_string init.mako.rc "min_sample_time" "sampling_rate" "min_sample_time";
replace_string init.mako.rc "target_loads" "sampling_down_factor" "target_loads";
replace_string init.mako.rc "/interactive/io_is_busy 0" "/interactive/io_is_busy 1" "/interactive/io_is_busy 0";
replace_string init.mako.rc "/interactive/target_loads 65" "/interactive/target_loads 4" "/interactive/target_loads 65";
replace_string init.mako.rc "192000" "384000" "192000";

replace_line init.mako.rc "restorecon_recursive /sys/devices/system/cpu/cpufreq/ondemand" "    restorecon_recursive /sys/devices/system/cpu/cpufreq/interactive";

# end ramdisk changes

write_boot;

## end install


