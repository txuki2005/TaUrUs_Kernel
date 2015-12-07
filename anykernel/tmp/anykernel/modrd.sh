#!/sbin/sh
# modrd.sh initially made by Ziddey
#
# Updated for Marshmallow
#

### remove unncessary binaries and stuff
## init.rc
# Files that interfere with synapse
sed '/# Run sysinit/d' -i init.rc
sed ' /start sysinit/d' -i init.rc
sed ':a;N;$!ba;s/service sysinit \/system\/bin\/sysinit\n[ ]\+user root\n[ ]\+oneshot\n[ ]\+disabled//g' -i init.rc
## init.mako.rc
# Not needed on M
sed '/import init.mako_tiny.rc/d' -i init.mako.rc
sed '/import init.mako_svelte.rc/d' -i init.mako.rc
# Mpdecision and Thermald services
sed ':a;N;$!ba;s/service mpdecision \/system\/bin\/mpdecision --no_sleep --avg_comp\n[ ]\+class main\n[ ]\+user root\n[ ]\+group root system//g' -i init.mako.rc
sed ':a;N;$!ba;s/service thermald \/system\/bin\/thermald\n[ ]\+class main\n[ ]\+group radio system//g' -i init.mako.rc
sed '/mpdecision/d' -i init.mako.rc
sed '/thermald/d' -i init.mako.rc
## Add my configs
sed '/import init.mako.usb.rc/ a\import init.txuki_confg.rc' -i init.mako.rc
cp ../init.txuki_confg.rc ./
chmod 0750 init.txuki_confg.rc
## system binaries if not deleted yet
rm /system/bin/mpdecision
rm /system/bin/thermald
rm /system/lib/hw/power.msm8960.so
rm /system/lib/hw/power.mako.so