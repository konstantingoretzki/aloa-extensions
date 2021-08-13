#!/usr/bin/env python3

from scapy.sendrecv import sniff
from scapy.layers.dhcp import DHCP
import os
import time

# write detected os in os.txt-file
def writeOSFile(OS):
	f = open("/root/hosts/os.txt", "w")
	f.write(OS)
	f.close()
	fAn = open("/root/hosts/done-analyzing.txt", "w")
	fAn.write("done")
	fAn.close()
	exit()

# try to detect the os by checking the DHCP request options
def detectOS(options):
	f = open("/root/hosts/os.txt", "w")

	# Windows devices define the vendor_class_id
	if "vendor_class_id" in options:
		if "MSFT" in options["vendor_class_id"]:
			writeOSFile("Windows")

	# Ubuntu (also Kali Linux so probably all debian-based distros) does set option 2 and 17 in the parameter request list
	elif set([2, 17]).issubset(options["param_req_list"]):
		writeOSFile("Ubuntu")

	# macOS does set option 95 in the parameter request list
	elif set([95]).issubset(options["param_req_list"]):
		writeOSFile("Mac")

	# if some devices do not set the given identifiers then the OS can not be determined
	else:
		writeOSFile("Unknown")


# check if packet is DHCP request/ discover and if so add DHCP options
def dhcp_callback(pkt):
	if DHCP in pkt and (pkt[DHCP].options[0][1] == 3 or pkt[DHCP].options[0][1] == 1):
	#if pkt[BOOTP] and pkt[BOOTP].op == 1: # BOOTREQUEST/ DHCP Request

		dhcp_options = pkt[DHCP].options
		option_list = {}

		# iterate through all tuples
		for option in dhcp_options:

			# check if we might to convert sth because it contains additional flags, length, etc.
			if isinstance(option[1], (bytes, bytearray)):

				# only client name - remove leading length, flags, a-pr and ptr-ppr result
				if option[0] == "client_FQDN":
					option_list[option[0]] = option[1][3:].decode()

				# only mac - remove length and hw type
				elif option[0] == "client_id":
					# extract mac only as hex and add delimiter
					# https://stackoverflow.com/questions/9020843/how-to-convert-a-mac-number-to-mac-string
					option_list[option[0]] = ':'.join(format(s, '02x') for s in bytes.fromhex(option[1][1:].hex()))

				else:
					option_list[option[0]] = option[1].decode()
			else:
				option_list[option[0]] = option[1]

		print(option_list)
		detectOS(option_list)


if __name__ == "__main__":
	# tell trigger-usb-connect that the imports are done --> ready for analyzing .pcaps
	os.system("/usr/local/bin/P4wnP1_cli led -b 2")
	fRdy = open("/root/hosts/ready.txt", "w")
	fRdy.write("rdy")
	fRdy.close()

	# wait until trigger-usb-connect is finish with recording
	while True:
		if os.path.isfile("/root/hosts/done-sniffing.txt"):
			os.remove("/root/hosts/done-sniffing.txt")
			try:
				sniff(offline='/root/sniff.pcap', store=0, prn=dhcp_callback)
			except Exception as e:
				print(e)

			# gets only called if it could not detect the os
			fAn = open("/root/hosts/done-analyzing.txt", "w")
			fAn.write("done")
			fAn.close()
			break
		time.sleep(2)

	while True:
		if os.path.isfile("/root/hosts/done-sniffing.txt"):
			os.remove("/root/hosts/done-sniffing.txt")
			try:
				sniff(offline='/root/sniff.pcap', store=0, prn=dhcp_callback)
			except Exception as e:
				 print(e)

			# gets only called if it could not detect the os
			fAn = open("/root/hosts/done-analyzing.txt", "w")
			fAn.write("done")
			fAn.close()
			exit()
		time.sleep(2)


