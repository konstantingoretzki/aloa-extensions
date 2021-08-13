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
                echo "$(date +"%T") : cleared image $d"
                sleep 3
done
