#!/bin/bash
printf "\n***********************************\n"
printf "  Pure Storage Best Practice Check"
printf "       v0.9.5 - 13 March 2020"
printf "***********************************\n"
printf "[1] OS information\n"
prettyname=$(cat /etc/*release | grep -w PRETTY_NAME | sed "s/PRETTY_NAME=\"/""/g" | sed "s/\"/""/g")
#buildversion=$(cat /etc/*release | grep -w VERSION= | sed "s/VERSION=\"/""/g" | sed "s/\"/""/g")
buildversion=$(cat /etc/*release | grep -i release | head -n1 | sed 's/.*=//')
printf "OS Name: \t\t\033[0;32m$prettyname\n\033[0m"
printf "OS Version: \t\t\033[0;32m$buildversion\n\033[0m"
kernelversion=$(uname -r)
printf "Kernel version: \t\033[0;32m$kernelversion\n\033[0m"

printf "\n***********************************\n"
printf "\n[2] Config File - Block Devices (UDEV File)\n"
blockdevicefile="NOK"
if [ -f "/etc/udev/rules.d/99-pure-storage.rules" ]; then
        #cat /etc/udev/rules.d/99-pure-storage.rules > ./99-pure-storage.rules
        blockdevicefile="/etc/udev/rules.d/99-pure-storage.rules"
fi
if [ -f "/lib/udev/rules.d/99-pure-storage.rules" ]; then 
        #cat /lib/udev/rules.d/99-pure-storage.rules > ./99-pure-storage.rules
        blockdevicefile="/lib/udev/rules.d/99-pure-storage.rules"
fi
if [[ $blockdevicefile == "NOK" ]]; then
        printf " FILE NOT FOUND\n"
else
        printf " File found at [$blockdevicefile]\n"
fi

printf "\n***********************************\n"
printf "\n[3] Connected Devices - Current Block Device Settings\n"
blocksettings="OK"
blockdevices=$(for device in `ls /sys/block/ | grep sd`; do echo $device; done)
for device in $blockdevices
do
        # Get the vendor details of the block device, to only check Pure connected volumes
        printf " $device \t"
        vendor=$(cat /sys/block/$device/device/vendor | sed -e 's/[[:space:]]*$//' | awk '{print toupper($0)}')
        if [[ $vendor == "PURE" ]]; then
                printf "[$vendor]\t\t - "
                timeoutval=$(cat /sys/block/$device/device/timeout)
                if [[ $timeoutval == "60" ]]; then
                        printf "HBA Timeout[OK]"
                else
                		blocksettings="NOK"
                        printf "\033[0;31mHBA Timeout[NOT OK]\033[0m,"
                fi
                scheduler=$(cat /sys/block/$device/queue/scheduler | cut -d "[" -f2 | cut -d "]" -f1)
                if [[ $scheduler == "noop" ]]; then
                        printf ",I/O Scheduler[OK]"
                else
                		blocksettings="NOK"
                        printf ",\033[0;31mI/O Scheduler[NOT OK]\033[0m,"
                fi
                max_sectors_kb=$(cat /sys/block/$device/queue/max_sectors_kb)
                if [[ $max_sectors_kb == "4096" ]]; then
                        printf ",Max I/O Size[OK]"
                else
                		blocksettings="NOK"
                        printf ",\033[0;31mMax I/O Size[NOT OK]\033[0m,"
                fi  
                add_random=$(cat /sys/block/$device/queue/add_random)
                if [[ $add_random == "0" ]]; then
                        printf ",Add Random[OK]"
                else
                		blocksettings="NOK"
                        printf ",\033[0;31mAdd Random[NOT OK]\033[0m,"
                fi
                rq_affinity=$(cat /sys/block/$device/queue/rq_affinity)
                if [[ $add_random == "0" ]]; then
                        printf ",RQ Affinity[OK] -\n"
                else
                		blocksettings="NOK"
                        printf ",\033[0;31mRQ Affinity[NOT OK]\033[0m -\n"
                fi              
        else
                printf "[$vendor]\t\t - Ignoring Device -\n"
        fi
done

printf "\n***********************************\n"
printf "\n[4] Driver - dm-multipath - Check if Device-Mapper Multipathing is installed.\n"
multipathfound="OK"
command -v multipath  || { multipathfound="NOK";}
if [[ $multipathfound == "OK" ]]; then
        driverversion=$(multipathd list | grep "multipath-tools")
        printf " Multipath driver is installed.\n"
        multipathfound=$(systemctl is-active multipathd.service) || multipathfound="NOTUSINGSYSTEMCTL"
        if [[ $multipathfound == "NOTUSINGSYSTEMCTL" ]]; then 
                printf " \033[1;33m WARN - This distribution does not use systemctl.\n"
                printf " \033[1;33m Cannot check the running state of the multipathd.service service.\n"
        else
                printf " The multipathd service is currently $multipathfound\n" 
        fi
fi
#Check for EMC powerpath.
emcpowerpathdetected=$(powermt display dev=all >/dev/null 2>&1) || emcpowerpathdetected="NO"
if [[ $emcpowerpathdetected != "NO" ]]; then
        print " \033[0;31mEMC Powerpath detected!!!"
fi
#rpm -q device-mapper-multipath
printf "\n***********************************\n"
printf "\n[5] Config File - Check that there is an entry for Pure Storage Arrays\n"
if [ -f "/etc/multipath.conf" ]; then 
        # cat /etc/multipath.conf > ./multipath.conf
        printf " File found at [/etc/multipath.conf]\n"
        if grep -Fq "PURE" /etc/multipath.conf; then
                printf " Pure storage entry found in config file.\n" 
                mpathdevicefile="OK"
        else 
                printf " Pure storage entry NOT found in config file.\n"
                mpathdevicefile="NOK"
        fi
else
        mpathdevicefile="NOK"
        printf " FILE NOT FOUND\n"
fi

# Produce report
printf "\n***********************************\n"
printf "\n\033[1mBest Practice - Report - [$HOSTNAME]\033[0m\n\n"
printf "[1] Linux Distribution Detected \t\033[0;36m$prettyname\n\033[0m"
printf "    Build Version Detected \t\t\033[0;36m$buildversion\n\033[0m"
printf "    Kernel Version Detected \t\t\033[0;36m$kernelversion\n\033[0m"
compliance="PASS"
if [[ $blockdevicefile == "NOK" ]]; then
        printf "[2] Config File - 99-pure-storage.rules\t\033[0;31mFAIL\n No 99-pure-storage.rules file exists in the standard paths. "
        printf "Please ensure that there is a /*/udev/rules.d/99-pure-storage.rules file.\n\033[0m"
        compliance="FAIL"
else
        printf "[2] Config File - Block Devices\t\t\033[0;32mPASS\n\033[0m"
        printf "    Location\t\t\t\t\033[0;36m$blockdevicefile\n\033[0m"
fi
if [[ $blocksettings == "OK" ]]; then
	printf "[3] Connected Devices - Block\t\t\033[0;32mPASS\n\033[0m"
else
	printf "[3] Connected Devices - Block\t\t\033[0;31mFAIL\n One or more of your block devices is incorrectly configured. "
	printf "Please ensure that your /*/udev/rules.d/99-pure-storage.rules file is correctly configured for your current OS version.\n\033[0m"
        compliance="FAIL"
fi

if [[ $multipathfound == "active" ]]; then
        printf "[4] Multipath Driver Status\t\t\033[0;32mPASS\n\033[0m"
        printf "    dm-multipath version\t\t\033[0;36m$driverversion\n\033[0m"
elif [[ $multipathfound == "active" ]]; then
        printf "[4] Driver - dm-multipath\t\t\033[0;31mFAIL\n The generic multipathing driver service is currently in an [multipathfound] state, but should be [active].\n\033[0m"
        compliance="FAIL"    
else
        printf "[4] Driver - dm-multipath\t\t\033[0;31mFAIL\n Please ensure that the generic linux multipathing driver is installed.\n\033[0m"
        compliance="FAIL"
fi
if [[ $emcpowerpathdetected != "NO" ]]; then
        printf "[!] Driver - EMC Powerpath \t\t\033[0;31mFAIL\n EMC Powerpath detected!!!\n"
        printf " Please note that running EMC Powerpath with the genric linux dm-multipath driver can cause OS kernel panics!!!\n"
        printf " It is recommnded to remove EMC powerpath when using multiple vendor's storage subsystems.\n"
        printf " For more info - https://access.redhat.com/site/solutions/110553\033[0m\n"
        compliance="FAIL"
fi

if [[ $mpathdevicefile == "OK" ]]; then
        printf "[5] Config File - Multipath Driver\t\033[0;32mPASS\033[0;33m*\n\033[0m"
        printf "    Location\t\t\t\t\033[0;36m/etc/multipath.conf\n\033[0m"
else
        printf "[5] Config File - multipath.conf\t\033[0;31mFAIL\n An entry for Pure Storage was not found in the multipath.conf file.\n\033[0m"
        compliance="FAIL"
fi

# Submit result
if [[ $compliance != "PASS" ]]; then
        printf "\n \033[0;31mTHIS HOST [$HOSTNAME] IS NOT RUNNING ALL BEST PRACTICES.\033[0m\n"
        printf " PLEASE NOTE THAT SYSTEM STABILITY/MAXIMUM PERFORMANCE CANNOT BE EXPECTED.\n\n\033[0m"
fi

printf "\n\033[0;33m*Please confirm that the entries in the config files are correct for your OS version [$prettyname].\033[0m\n"
printf "\n***********************************\n\n"
printf "Please contact Data Sciences Corporation for additional support.\n"
exit
