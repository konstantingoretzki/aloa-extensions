# ALOA extensions
PoC extensions of the famous [P4wnP1 A.L.O.A.](https://github.com/RoganDawes/P4wnP1_aloa) framework by MaMe82 for the Raspberry Pi Zero W(H). The main functionality of this extension is a basic operating system and keyboard layout detection by analyzing DHCP packets and "brute-forcing" (power)shell commands. Besides helper scripts are provided that allow root / admin right detection, easy binary execution (incl. commandline arguments) and file extraction. An example for stealing the Firefox cookies.db using a golang executable and a HIDScript is given.

## Installation
- Simple way: just download the `aloa-extensions.img` image (needs SD card with at least 6 GB) and flash using `dd` or [balenaEtcher](https://www.balena.io/etcher/)
- Manual mode:
    1. Normally [flash](https://github.com/RoganDawes/P4wnP1_aloa#0-how-to-install) your P4wnP1
    2. SSH into to device: `ssh root@172.24.0.1` (WLAN AP) or `ssh root@172.16.0.1` (USB)
	3. Connect your P4wnP1 to the internet (see [internet sharing](#internet-sharing))
	4. Clone the repo (`git clone https://github.com/konstantingoretzki/aloa-extensions`) and execute `install-extensions.sh` (`cd aloa-extensions && chmod +x install-extensions.sh && ./install-extensions.sh`)
	5. Customize `trigger-usb-connect.sh` according to your wishes (see [settings](#settings))
	6. Reboot the device --> `reboot`

## Usage
LED:
- Flashing twice: ready OR running checks / payload
- Continuous: startup OR execution done (safe to unplug)

Credentials:
- System: `kali:kali`
- WLAN: `notmyday` (only for `aloa-extensions.img`)

IPv4 addresses:
- USB-Ethernet: http://172.16.0.1:8000
- WLAN: http://172.24.0.1:8000

## How it works
The OS detection works by analyzing recorded DHCP packets and analyzing them via Python and scapy. Windows 10 Pro Build 2004, macOS Catalina 10.15.6 and Ubuntu 20.04.1 LTS have been tested and could be recognized. To determine the keyboard layout a test file is written to a created USB storage device. The main script (`trigger-usb-connect.sh`) runs and checks if a file could be found. If not the write failed and the wrong keyboard layout was selected. Another try will be made. The keyboard layouts for German, English and French are supported. Adjustments to use another subset have to be made manually.

## Settings
To use the extensions some settings in the `trigger-usb-connect.sh`-file can be tweaked. You can use either the binary executable or the HIDScript payload mode.

If the payload execution time takes a bit and is not done instantly the HID payload has to write a file if it is done. The binary mode does this automatically. A maximum time to wait before stopping the execution can be set.
```
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
```

To prevent accidentally running detections and payload executions while testing or installing per default the file `/root/hosts/start.txt` has to be created.
You can do this simply by connecting via SSH (USB connection or WLAN AP) and running `touch /root/hosts/start.txt`.
This feature can be "deactivated" by commenting out the code-block in `/usr/local/P4wnP1/scripts/trigger-usb-connect.sh` like this:
```
## Debugging
# allow to only start if start.txt exists
#until [ -f /root/hosts/start.txt ]
#do
#    sleep 1
#done
#rm /root/hosts/start.txt
```

## Internet sharing
- Windows:
    1. Host: go via system settings to the network connections menu
    2. Host: select the adapter that is used on your PC / laptop for internet (WLAN or Ethernet adapter), right-click and activate internet sharing (sth like "other users are allowed to use this connection as internet connection") with your P4wnP1 adapter 
    3. Host: select the P4wnP1 adapter and reset the TCP/IPv4 settings to "get automatically"
    4. P4wnP1: `route add default gw 172.16.0.2 usbeth`
- Linux:
    1. Host: `echo "1" | sudo tee /proc/sys/net/ipv4/ip_forward`
    2. Host: `sudo iptables -A POSTROUTING -t nat -j MASQUERADE -s 172.16.0.0/30`
    3. Host: `sudo ip addr add 172.16.0.2/30 dev <usb-ethernet-adapter>`
    4. P4wnP1: `route add default gw 172.16.0.2 usbeth`
    5. Host (if done): `echo "0" | sudo tee /proc/sys/net/ipv4/ip_forward > /dev/null`
    6. Host (if done): `sudo iptables -t nat -F POSTROUTING`
    
More information can be found e.g. in [this thread](https://github.com/RoganDawes/P4wnP1_aloa/issues/64).

## TODO
Most of the code is somehow hacky and possibly not the best way. Besides there are also other problems that should be fixed for a better experience.
Feel free to contribute and share your thoughts.

- [ ] Improve documentation
- [ ] Improve timings: try to find the minimal waiting time
    - [ ] USB folder spawn
    - [ ] HIDScript typingSpeed
    - [ ] tcpdump sniff time
    - [ ] improve scapy startup time (golang lib?)
    - [ ] improve booting time?
- [ ] Fix macOS keyboard layout files --> extra files for macOS
- [ ] Add RTC helper script
- [ ] Refactor: 
    - [ ] settings in an extra file
    - [ ] use proper IPC instead of files to determine if a process is done
- [ ] Image build: 
    - [ ] smaller image using auto build script
    - [ ] update P4wnP1 main image?
- [ ] Bug fixes
    - [ ] Fix USB copy crash: USB copy speed is on Ubuntu way to high for USB 2.0 and will crash for huge files (e.g. 3 GB media file). On Windows copy is very slow (2 MB/s). `dmesg` showed USB driver crashes. The might be related to a [bug](https://github.com/raspberrypi/linux/issues/2796) in the used kernel version (4.14.80). A kernel upgrade isn't that trivial because the Re4son kernel is used.
    - [ ] Fix rare HIDScript hiccups where chars are mistyped / ignored (P4wnP1 bug or caused by extensions?)
- [ ] Support ALT codes (--> code of [P4wnP1 A.L.O.A.](https://github.com/RoganDawes/P4wnP1_aloa))

## Troubleshooting
- Tcpdump: newer versions of tcpdump in Kali seem to be available at `/usr/sbin/tcpdump` instead of `/usr/bin/tcpdump`. If this is the case then please adjust the tcpdump-paths in `/usr/local/P4wnP1/scripts/trigger-usb-connect.sh`.
- Internet sharing: Windows 10 with a build newer than 2004 only loads new USB gadgets like Ethernet if the device itself changes (at least on my systems). We can bypass this behaviour by simply changing the vendorID. This can also be the case if the P4wnP1 is missing in the connection list. If so: go to the P4wnP1 webinterface, change the vendorID e.g. to `0x1d6f` and click on `deploy`.
