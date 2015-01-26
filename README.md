
# Garage Opener

An iOS Swift and Arduino Bluetooth LE experiment.
See project homepage at http://tfmalt.github.io/garage-door-opener-ble/

This is a hobby project to learn swift and in the same go create a 
remote control for my garage door using an arduino uno.

The remote works really well, and is intended to be as simplistic as
possible, with only one button as the interface. The app connects 
automatically to the Arduino controller whenever they are in 
range of one another.

If you find it interesting or potentially useful, feel free to 
contribute or ask for features or functionality.

## iOS App
<img style="border: 1px solid #aaa" width="240px" src="http://tfmalt.github.io/garage-door-opener-ble/images/ios_scanning.jpg">
<img style="border: 1px solid #aaa" width="240px" src="http://tfmalt.github.io/garage-door-opener-ble/images/ios_settings.jpg">

## Features
* Connects automatically to a BLE peripheral with the correct device UUID.
* Scanning for device stops after 30 seconds if a device can't be found.
* Push button to open door changes color depending on state to communicate visually with the user.
* Contains both light and dark theme to be equally usable depending on light.
* Automatic theme switching can be enabled to switch to dark theme during the night. Nice when using the controller from a car.

### TODO
### DONE
* Stop scanning after 30s
* update colors: green and orange
* Disable spinner when connected.
* Add activty indicator when scanning.
* Try new silent image grab algorithm. -- successful.
* Refactor into separate capture device controller
* Alert cleanly when camera access is denied
* Ask for camera access when toggelig auto theme for the first time
* Stop and start capture device cleanly when:
* Changing views from settings to main
* entering or coming back from the background
* Remember the last theme on startup.
* Implement dark theme for night time
* Settings interface to toggle preferred theme
* Test camera light detection algorithm to toggle theme automatically.
* Version 1.0 done.
* set new password on ardinuo over serial.
* get NSTimer to trigger reading iRRSI properly
* Send updates to textviews on device discovery
* Make connecting to devices based on service UUID, not device
* Send an actual update.
* password setting dialog on iOS 
* implement wake from sleep event
* investigate light sensor reading
