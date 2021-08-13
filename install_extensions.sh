#!/bin/bash

echo -e "\nPlease make sure that the P4wnP1 has internet connection! \n"

# dependencies
echo "Installing dependencies ..."
apt update
apt install ntfs-3g tcpdump sqlite3
pip3 install scapy

# scripts
echo -e "\nInstalling scripts ..."
cp scripts/analyze-pcap.py scripts/clear-imgs.sh /root/scripts/
cp scripts/trigger-usb-connect.sh /usr/local/P4wnP1/scripts/
chmod 755 /root/scripts/analyze-pcap.py /root/scripts/clear-imgs.sh
chmod 755 /usr/local/P4wnP1/scripts/trigger-usb-connect.sh

# cronjob
echo -e "Setup cronjob ..."
(crontab -l ; echo -e "SHELL=/bin/bash\nPATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin\n@reboot /usr/bin/python3 /root/scripts/analyze-pcap.py &\n") | crontab -

# payloads - binary
echo -e "\nCopy binary payloads ..."
mkdir -p /root/hosts/payloads
cp payloads/binary/executables/* /root/hosts/payloads/
chmod 751 /root/hosts/payloads/*

# payloads - HIDScript
echo -e "Copy HIDScript payloads ..."
cp payloads/HIDScript/* /usr/local/P4wnP1/HIDScripts/
chmod 644 /usr/local/P4wnP1/HIDScripts/keyboard.js /usr/local/P4wnP1/HIDScripts/payload-execute.js /usr/local/P4wnP1/HIDScripts/root-check.js
chmod 644 /usr/local/P4wnP1/HIDScripts/stealFirefoxPlaces.js /usr/local/P4wnP1/HIDScripts/stealFirefoxCookies.js

# database
echo -e "\nSetup database ..."
cp extensions.db /usr/local/P4wnP1/db/
/usr/local/bin/P4wnP1_cli db restore --name extensions.db

# drive images
echo -e "\nSetup drive images ..."
# FAT32
/usr/local/P4wnP1/helper/genimg  -l "sneaky" -s 500 -o 500mb
mount -o loop /usr/local/P4wnP1/ums/flashdrive/500mb.bin /mnt
cp /root/hosts/payloads/* /mnt/
umount /mnt
# NTFS
dd if=/dev/zero of=/usr/local/P4wnP1/ums/flashdrive/ntfs.bin bs=1M count=500
mkfs.ntfs -Q -v -F -L sneaky /usr/local/P4wnP1/ums/flashdrive/ntfs.bin
mount -o loop /usr/local/P4wnP1/ums/flashdrive/ntfs.bin /mnt
cp /root/hosts/payloads/* /mnt/
umount /mnt

echo -e "\nInstalling done."
echo -e "Please reboot now to be able to use the extensions.\n"
