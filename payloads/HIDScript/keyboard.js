typingSpeed(10,0)

// will be changed via sed
var lang = 'de'
var os = 'Windows'

// set keyboard language
layout(lang)

// helpers
function runPowershell() {
    press("GUI r") // windows + r
    delay(500)
    type("powershell\n") // write powershell and press "enter"
    delay(1000)
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
  // close window for new keyboard setup
  press("GUI Q")
  press("GUI SPACE")
  // window effects delay
  // especially if running in VM
  delay(5000)
  type("termi\n")
  // use less delay later
  delay(5000)
}

function createWindowsFile(language) {
    // get drive name of mass storage, improved version: only the value!
    type("$usbPath = Get-WMIObject Win32_Volume | ? { $_.Label -eq 'sneaky' } | select -expand name\n")

    // create file with hostname in it
    // [IO.File]::WriteAllLines((Join-Path $usbPath "language.txt"), "XXX")
    // we can only access .NET if we are still on the system drive
    // --> changing dir/ drive removes the possibility to call .NET routines
    // https://stackoverflow.com/questions/5596982/using-powershell-to-write-a-file-in-utf-8-without-the-bom
    // we can also prevent the win BOM problems --> makes parsing on the linux side way more easy
    var cmdWriteFile = "[IO.File]::WriteAllLines((Join-Path $usbPath 'language.txt'), '" + language + "')\n"
    type(cmdWriteFile)
  	type("Write-VolumeCache $usbPath[0]\n")
}

function createUbuntuFile(language) {
    // fix the wrongly created file for french if german keyboard was used
  	if (lang === 'fr') {
      type("rm \"7,ediq748users97sneqkw7lqnguqge:txt\" 2>/dev/null ; ")
      type("echo \"" + language + "\" > /media/$(users)/sneaky/language.txt\n")
      type("\n sync && exit\n")  // exit, \n in front for failed english needed
    }
  	else {
    // path: /media/$(users)/sneaky
    type("echo \"" + language + "\" > /media/$(users)/sneaky/language.txt && sync\n")
    delay(1000)
    type("\nexit\n")
  	}
}

function createMacFile(language) {
  if (lang === "de") {
    // first run so enable switching buttons via TAB
    press("CTRL F7")
  	type("echo \"" + language + "\" ° /Volumes/sneaky/language.txt && sync\n")
    delay(1000)
    // switch to button "OK" and press it
    press("TAB")
    press("TAB")
    press("SPACE")
  }
  
  else if (lang === "us") {
    /*
  	type("echo ")
  	press("SHIFT Ä")
  	type(language)
  	press("SHIFT Ä")
  	type(" : -Volumes-sneakz-language.txt && sync\n")
    */
    press("CTRL C")
    delay(100)
    
    type("echo \"" + language + "\" > /Volumes/sneaky/language.txt && sync\n")
    delay(1000)
    
    press("TAB")
    press("TAB")
    press("SPACE")
  }
  
  else if (lang === "fr") {
    
    press("CTRL C")
    delay(100)
  
  	type("echo \"")
  	type(language)
  	type("\" ")
  
  	// workaround to fix the broken french layout
  	// >
  	layout("us")
  	press("SHIFT Ü");
  	type("~");
  	layout(language)
  
  	type(" /Volumes/sneaky/language.txt && sync\n")
    
    delay(1000)
    
    press("TAB")
    press("TAB")
    press("SPACE")
	}
}

if (os === "Windows") {
  runPowershell()
  createWindowsFile(lang)
  type("\nexit\n")  // exit, \n in front for failed english needed
  // close all open windows, needed for french
  // 1x for closing run-error message and 1x for exiting the run-dialog
  press("ESC")  // close all open windows --> needed for french
  press("ESC")  // close all open windows --> needed for french
}

else if (os === "Ubuntu") {
  ubuntuTerminal()
  createUbuntuFile(lang)
}

else if (os === "Mac") {
  macTerminal()
  createMacFile(lang)
}
