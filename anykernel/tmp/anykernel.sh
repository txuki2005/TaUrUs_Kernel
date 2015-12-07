#!/sbin/sh
#
#
# Anykernel inline kernel patching script
#
# Adapted for easier use by zaclimon
#


# Define the basic attributes now
FSTAB=`find fstab.*`
BOOT_PARTITION=`grep /boot $FSTAB | cut -d " " -f1`

# Preparing...
cd /tmp/anykernel
chmod 0755 unpackbootimg
chmod 0755 mkbootimg

# Unpack the kernel.
dd if=$BOOT_PARTITION of=boot.img
./unpackbootimg -i boot.img

# Define the kernel's attributes for the repacking.
KERNEL_CMDLINE=`cat boot.img-cmdline | sed 's/.*/"&"/'`
KERNEL_BASE=`cat boot.img-base`
KERNEL_PAGESIZE=`cat boot.img-pagesize`
KERNEL_OFFSET=`cat boot.img-kerneloff`
RAMDISK_OFFSET=`cat boot.img-ramdiskoff`

# Modify ramdisk
mkdir ramdisk
cd ramdisk
gzip -dc ../boot.img-ramdisk.gz | cpio -i
chmod 0755 ../modrd.sh
../modrd.sh
../smart-fstab-generator.sh $FSTAB

find . | cpio --create --format='newc' | gzip > ../ramdisk.gz
cd ..

echo \#!/sbin/sh > createnewboot.sh
echo "./mkbootimg --kernel zImage --ramdisk ramdisk.gz --cmdline $KERNEL_CMDLINE --base $KERNEL_BASE --pagesize $KERNEL_PAGESIZE --kernel_offset $KERNEL_OFFSET --ramdisk_offset $RAMDISK_OFFSET -o newboot.img" >> createnewboot.sh
chmod 0755 createnewboot.sh
./createnewboot.sh

echo Flashing boot.img...
dd if=newboot.img of=$BOOT_PARTITION

exit 0
