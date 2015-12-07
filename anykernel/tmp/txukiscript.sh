#!/sbin/sh


mount -o rw /system;


# disable the PowerHAL since there is a kernel-side touch boost implemented
 [ -e /system/lib/hw/power.msm8960.so ] && mv /system/lib/hw/power.msm8960.so /system/lib/hw/power.msm8960.so.bak;

# disable mpd and thermald

 [ -e /system/lib/hw/power.mako.so ] && mv /system/lib/hw/power.mako.so /system/lib/hw/power.mako.so.bak;
 [ -e /system/bin/mpdecision ] && mv /system/bin/mpdecision /system/bin/mpdecision.bak;

 [ -e /system/bin/thermal-engine-hh ] && mv /system/bin/thermal-engine-hh /system/bin/thermal-engine-hh.bak;
 [ -e /system/bin/thermald ] && mv /system/bin/thermald /system/bin/thermald.bak;

umount /system;
