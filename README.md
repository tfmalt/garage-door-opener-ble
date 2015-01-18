
# Garage Opener

An iOS Swift to arduino Bluetooth LE experiment.
See project homepage at http://tfmalt.github.io/garage-door-opener-ble/

This is a hobby experiment to learn swift and create a control for my 
garage door opener using an arduino uno in the same go.

If you find it interesting or potentially useful, feel free to contribute or 
ask for features or functionality.
## iOS App
<img style="border: 1px solid #aaa" width="240px" src="http://tfmalt.github.io/garage-door-opener-ble/images/ios_scanning.jpg">

### TODO
* Implement dark theme for night time
* Settings interface to toggle preferred theme
* Test camera light detection algorithm to toggle theme automatically.

### DONE
* Version 1.0 done.
* set new password on ardinuo over serial.
* get NSTimer to trigger reading iRRSI properly
* Send updates to textviews on device discovery
* Make connecting to devices based on service UUID, not device
* Send an actual update.
* password setting dialog on iOS 
* implement wake from sleep event
* investigate light sensor reading
