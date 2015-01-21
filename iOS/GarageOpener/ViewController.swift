//
//  ViewController.swift
//  GarageOpener
//
//  Created by Thomas Malt on 10/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var themeImage: UIImageView!
    @IBOutlet weak var ISOValueLabel: UILabel!
    @IBOutlet weak var expValueLabel: UILabel!
    @IBOutlet weak var lumValueLabel: UILabel!
    
    var counter = 0
    var discovery   : BTDiscoveryManager?
    var isConnected : Bool?
    var nc     = NSNotificationCenter.defaultCenter()
    var config = NSUserDefaults.standardUserDefaults()
    
    let captureSession : AVCaptureSession = AVCaptureSession()
    var captureDevice  : AVCaptureDevice?
    var captureTimer   : NSTimer?
    var imageOutput    : AVCaptureStillImageOutput = AVCaptureStillImageOutput()
    var sessionQueue   : dispatch_queue_t!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        
        statusLabel.text = "Initializing";
        rssiLabel.text   = self.getConnectionBar(0)
        discovery        = BTDiscoveryManager()
        isConnected      = false
        
        self.makeButtonCircular()
        self.makeThemeImageCircular()
        self.updateOpenButtonWait()
        self.registerObservers()
        self.setTheme()
        self.setupCaptureSession()
        // self.configureCaptureDevice()
        self.captureImage()
        self.setupImageCaptureTimer()
        
    }
    
    func setupImageCaptureTimer() {
        
        self.ISOValueLabel.text = ""
        self.expValueLabel.text = ""
        self.lumValueLabel.text = ""
        
        self.captureTimer = NSTimer.scheduledTimerWithTimeInterval(
            1.0,
            target: self,
            selector: "doActualCapture",
            userInfo: nil,
            repeats: true
        )
    }
    
    func setupCaptureSession() {
        dispatch_async(self.sessionQueue, {
            println("Starting to configure capture session.")
            if self.captureSession.canSetSessionPreset(AVCaptureSessionPreset352x288) {
                self.captureSession.sessionPreset = AVCaptureSessionPreset352x288
                println("  Set capture preset to 352x288")
            } else {
                println("  Could not set preset to 352x288 -> implement fallback")
            }
            
            self.captureDevice = AVCaptureDevice.deviceWithVideoInFront()
            self.imageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
            
            // be a bit paranoid about the availablity of a camera.
            if let camera : AVCaptureDevice = self.captureDevice {
                var input  = AVCaptureDeviceInput(device: camera, error: nil)
                var output = self.imageOutput
                
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(AVCaptureDeviceInput(device: camera, error: nil))
                    println("  Added front camera as input")
                } else {
                    println("  Could not add front camera as input")
                }
                
                if self.captureSession.canAddOutput(output) {
                    self.captureSession.addOutput(output)
                    println("  Added output object as output")
                } else {
                    println("  Could not add output object -> figure out why")
                }
                
                println("  active format: \(camera.activeFormat.description)")
            }
            
            println("Configured capture session")
        })
    }
    
    
    func configureCaptureDevice() {
        
        let ISO            = 800.0
        let exposureLength = (10.0/1000.0)
        
        // Paranoid about the precense of a forward facing camera
        if let camera : AVCaptureDevice = self.captureDevice {
            camera.lockForConfiguration(nil)
            println("Locking device configuration")
            
            if camera.isExposureModeSupported(AVCaptureExposureMode.Custom) {
                println("  Setting exposure mode")
                camera.exposureMode = AVCaptureExposureMode.Custom
                camera.setExposureModeCustomWithDuration(
                    CMTimeMakeWithSeconds(exposureLength, 1000*1000*1000),
                    ISO: Float(ISO),
                    completionHandler: { (time) -> Void in
                        println("  - Set custom exposure done.")
                    }
                )
            } else {
                println("  Camera not supporting custom exposure mode.")
            }
            
            camera.unlockForConfiguration()
            println("Unlocked device configuration")
        }
        
    }
    
    
    func captureImage() {
        dispatch_async(self.sessionQueue, {
            var cmtime = CMTimeGetSeconds(self.captureDevice!.exposureDuration)
            println("Capturing image")
            println("  exposure duration: \(cmtime)")
            
            self.captureSession.startRunning()
            
            self.configureCaptureDevice()
        })
    }
    
    func doActualCapture() {
        println("got call do do actual capture")
        
        self.imageOutput.captureStillImageAsynchronouslyFromConnection(
            self.imageOutput.connectionWithMediaType(AVMediaTypeVideo),
            completionHandler: self.handleInputImage
        )
    }
    
    
    /// Does the actual handling of the image
    func handleInputImage(buffer: CMSampleBuffer!, error: NSError!) {
        println("  Got call to handle input image")
        
        if (buffer == nil) {
            println("    Got empty image buffer - an error")
            return
        }
        
        var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
        var image = UIImage(data: imageData)!
        println("    image size: \(image.size.width), \(image.size.height)")
        
        var luminance = image.luminance()
        
        themeImage.image = image
        
        if let camera = self.captureDevice {
            var duration = CMTimeGetSeconds(camera.exposureDuration) * 1000
            
            var time = Int(round(duration))
            var iso  = Int(camera.ISO)
            
            println("    exposure time: \(time)/1000)")
            println("    ISO: \(iso)")
            println("    the luminance I got: \(luminance)")
            
            self.ISOValueLabel.text = String(iso)
            self.expValueLabel.text = "\(time)/1000 s"
            self.lumValueLabel.text = String(format: "%.2f", Float(luminance))
        }
    }
    
    func setTheme() {
        if (config.boolForKey("useDarkTheme")) {
            self.setDarkTheme()
        } else {
            self.setLightTheme()
        }
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if (config.boolForKey("useDarkTheme")) {
            return UIStatusBarStyle.LightContent
        } else {
            return UIStatusBarStyle.Default
        }
    }
    
    func setDarkTheme() {
        view.backgroundColor = UIColor.blackColor()
        statusLabel.textColor = UIColor.colorWithHex("#CCCCCC")
        activityIndicator.color = UIColor.colorWithHex("#CCCCCC")
    }
    
    func setLightTheme() {
        view.backgroundColor = UIColor.whiteColor()
        statusLabel.textColor = UIColor.colorWithHex("#888888")
        activityIndicator.color = UIColor.colorWithHex("#888888")
    }
    
    
    func appWillResignActive(notification: NSNotification) {
        println("App will resign active")
        self.updateOpenButtonWait()
        
        self.captureSession.stopRunning()
        println("  stopping capture session")
    }
    
    func appWillTerminate(notification: NSNotification) {
        println("App will terminate")
    }
    
    func registerObservers() {
        nc.addObserver(
            self,
            selector: Selector("appWillResignActive:"),
            name: UIApplicationWillResignActiveNotification,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: Selector("appWillTerminate:"),
            name: UIApplicationWillTerminateNotification,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: Selector("btStateChanged:"),
            name: "btStateChangedNotification",
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: Selector("btConnectionChanged:"),
            name: "btConnectionChangedNotification",
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: Selector("btFoundDevice:"),
            name: "btFoundDeviceNotification",
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: Selector("btUpdateRSSI:"),
            name: "btRSSIUpdateNotification",
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: Selector("handleSettingsUpdated"),
            name: "settingsUpdated",
            object: nil
        )
    }
    
    func handleSettingsUpdated() {
        println("Got told settings have updated")
        self.setTheme() // The only thing I currently have to keep track of.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getConnectionBar(strength: Int) -> String {
        let s : String = "\u{25A1}"
        let b : String = "\u{25A0}"
        
        var result : String = ""
        for (var i = 0; i < 5; i++) {
            if i < strength {
                result = result + b;
            } else {
                result = result + s;
            }
        }
        return result
    }
    

    @IBAction func openButtonPressed(sender: UIButton) {
        counter = counter + 1;
        
        let rx = self.getRXCharacteristic()
        if rx == nil { return }
       
        let peripheral = self.getActivePeripheral()
        if peripheral == nil { return }
        
        if let pass = config.valueForKey("password") as? String {
            var str = "0" + pass;
            var data : NSData = str.dataUsingEncoding(NSUTF8StringEncoding)!
        
            peripheral?.writeValue(data, forCharacteristic: rx, type: CBCharacteristicWriteType.WithoutResponse)
        } else {
            println("Did not find valid password, so not writing anything")
        }
    }
    
    
    func getActivePeripheral() -> CBPeripheral? {
        if self.discovery == nil {
            println("  Could not find discovery object.")
            return nil
        }
        
        let peripheral = self.discovery!.activePeripheral
        if peripheral == nil {
            println("  Did not get active peripheral.")
            return nil
        }
        
        if peripheral?.state != CBPeripheralState.Connected {
            println("  Peripheral apparently is not connected.")
            return nil
        }

        return peripheral
    }
    
    func getRXCharacteristic() -> CBCharacteristic? {
        let peripheral = self.getActivePeripheral()
        if peripheral == nil { return nil }
        
        let service = self.discovery?.activeService
        if service == nil {
            println("  Did not get active service.")
            return nil
        }
        
        let rx = service?.rxCharacteristic
        if (rx == nil) {
            println("  Did not get rx characteristic")
            return nil
        }
        
        return rx
    }
    
    /// A really naive first attempt at adding a log abstraction for the 
    /// information textbox
    ///
    /// :param: msg The message to log
    func addLogMsg(msg: String) {
        
    }
    
    
    func updateOpenButtonWait() {
        let color = UIColor(red: 0.9, green: 0.0, blue: 0.0, alpha: 1.0)
        
        openButton.setBackgroundImage(
            UIImage.imageWithColor(color), forState: UIControlState.Normal
        )
        
        openButton.setBackgroundImage(
            UIImage.imageWithColor(color), forState: UIControlState.Highlighted
        )

        openButton.setTitle("Wait", forState: UIControlState.Normal)
    }
    
    func updateOpenButtonNormal() {
        openButton.setBackgroundImage(
            UIImage.imageWithColor(UIColor.colorWithHex("#66CC55")),
            forState: UIControlState.Normal
        )
        
        openButton.setBackgroundImage(
            UIImage.imageWithColor(UIColor.colorWithHex("#338822")),
            forState: UIControlState.Highlighted
        )
        
        self.openButton.setTitle("Open", forState: UIControlState.Normal)
    }
    
    
    func makeButtonCircular() {
        openButton.frame = CGRectMake(0, 0, 180, 180);
        openButton.clipsToBounds = true;
        
        println("Circular button: \(openButton.frame.size.width) x \(openButton.frame.size.height)")
        openButton.layer.cornerRadius = 90
    }
    
    
    func makeThemeImageCircular() {
        themeImage.clipsToBounds = true
        themeImage.layer.borderWidth = 2.0
        themeImage.layer.borderColor = UIColor.colorWithHex("#CCCCCC")?.CGColor
        themeImage.layer.cornerRadius = (themeImage.frame.size.width / 2)
    }
    
    /// Listens to notifications about CoreBluetooth state changes
    ///
    /// :param: notification The NSNotification object
    /// :returns: nil
    func btStateChanged(notification: NSNotification) {
        var msg = notification.object as String
        var log = msg
        
        if msg == "Disconnected" {
            var info       = notification.userInfo as [String: CBPeripheral]
            var peripheral = info["peripheral"]
            var name       = peripheral?.name
            
            log = "\(String(name!)) disconnected"
        }
        
        println("got notification: \(msg)")
        dispatch_async(dispatch_get_main_queue(), {
            if (msg.hasPrefix("Low Signal")) {
                return
            }
            
            self.statusLabel.text = msg

            if (msg != "Scanning") {
                self.activityIndicator.stopAnimating()
            }
            
            if (msg == "Disconnected") {
                self.updateOpenButtonWait()
            }
            else if (msg == "Bluetooth Off") {
                self.updateOpenButtonWait()
                self.rssiLabel.text = self.getConnectionBar(0)
            }
            else if (msg == "Scanning") {
                self.updateOpenButtonWait()
                self.rssiLabel.text = self.getConnectionBar(0)
                self.activityIndicator.startAnimating()
            }
        })
    }
    
    
    func btConnectionChanged(notification: NSNotification) {
        println("got connection changed notification: \(notification)")
        
        let userinfo = notification.userInfo as [String: Bool]
        let service  = notification.object as BTService
        let peripheral = service.peripheral
        
        if let isConnected: Bool = userinfo["isConnected"] {
            self.isConnected = isConnected
            
            dispatch_async(dispatch_get_main_queue(), {
                self.updateOpenButtonNormal()
                self.statusLabel.text = "Connected"
            })
        
        }
    }
    
    func btFoundDevice(notification: NSNotification) {
        println("got found device notification: \(notification)")
        
        let info       = notification.userInfo as [String: AnyObject]
        var peripheral = info["peripheral"]    as CBPeripheral
        var rssi       = info["RSSI"]          as NSNumber
        var name       = String(peripheral.name)
        
        dispatch_async(dispatch_get_main_queue(), {
            self.openButton.backgroundColor = UIColor.orangeColor()
            self.statusLabel.text = "Found Device..."
        })
    }
    
    func getQualityFromRSSI(RSSI: NSNumber!) -> Int {
        var quality = 2 * (RSSI.integerValue + 100);
        
        if quality < 0 { quality = 0 }
        if quality > 100 { quality = 100 }
        
        return quality
    }
    
    func btUpdateRSSI(notification: NSNotification) {
        let info = notification.userInfo as [String: NSNumber]
        let peripheral = notification.object as CBPeripheral
        var rssi : NSNumber! = info["rssi"]
        
        if peripheral.state != CBPeripheralState.Connected {
            println("  peripheral state says not connected!")
            return
        }
        
        var quality  : Int = self.getQualityFromRSSI(rssi)
        var strength : Int = Int(ceil(Double(quality) / 20))
        
        dispatch_async(dispatch_get_main_queue(), {
            self.rssiLabel.text = self.getConnectionBar(strength)
        })
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure
        )
    }
    
}

