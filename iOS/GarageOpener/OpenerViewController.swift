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

class OpenerViewController: UIViewController {
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var ISOValueLabel: UILabel!
    @IBOutlet weak var expValueLabel: UILabel!
    @IBOutlet weak var lumValueLabel: UILabel!
    @IBOutlet weak var ISOLabel: UILabel!
    @IBOutlet weak var expLabel: UILabel!
    @IBOutlet weak var lumLabel: UILabel!
    
    
    var counter = 0
    var discovery   : BTDiscoveryManager?
    var isConnected : Bool?
    var nc     = NSNotificationCenter.defaultCenter()
    var config = NSUserDefaults.standardUserDefaults()
    
    var captureSession : AVCaptureSession?
    var captureDevice  : AVCaptureDevice?
    var captureTimer   : NSTimer?
    var imageOutput    : AVCaptureStillImageOutput!
    var sessionQueue   : dispatch_queue_t!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionQueue = dispatch_queue_create("session queue", DISPATCH_QUEUE_SERIAL)
        
        statusLabel.text = "Initializing";
        rssiLabel.text   = self.getConnectionBar(0)
        discovery        = BTDiscoveryManager()
        isConnected      = false
        
        self.makeButtonCircular()
        self.updateOpenButtonWait()
        self.registerObservers()
        self.setTheme()
        
        if (config.boolForKey("useAutoTheme") == true) {
            self.setupAutoTheme()
        } else {
            self.setupWithoutAutoTheme()
        }
    }
    
    
    func setupAutoTheme() {
        ISOLabel.text = "ISO:"
        expLabel.text = "Exp:"
        lumLabel.text = "Lum:"
        
        self.setupCaptureSession()
        self.beginCaptureSession()
        self.setupImageCaptureTimer()
    }
    
    
    func setupWithoutAutoTheme() {
        ISOLabel.text = ""
        expLabel.text = ""
        lumLabel.text = ""
        
        ISOValueLabel.text = ""
        expValueLabel.text = ""
        lumValueLabel.text = ""
    }
    

    ///////////////////////////////////////////////////////////////////////
    //
    //  Setting up the capture session and dealing with functionality
    //  relating to automatic theme change
    //
    
    func setCaptureSessionPreset(preset: NSString!) {
        dispatch_async(self.sessionQueue, {
            println("Set capture session preset:")
            if let session = self.captureSession {
                if session.canSetSessionPreset(preset) {
                    session.sessionPreset = preset
                    println("  Set capture preset to: \(preset)")
                } else {
                    println("  Could not set preset: \(preset) -> implement fallback")
                }
            }
        })
    }
    
    
    func addCaptureSessionInputDevice() {
        dispatch_async(self.sessionQueue, {
            println("Adding input device:")
            if let session = self.captureSession {
                if let camera = self.captureDevice {
                    var input  = AVCaptureDeviceInput(device: camera, error: nil)
                    
                    if session.canAddInput(input) {
                        session.addInput(AVCaptureDeviceInput(device: camera, error: nil))
                        println("  Added front camera as input")
                    } else {
                        println("  Could not add front camera as input")
                    }
                    
                    println("  active format: \(camera.activeFormat.description)")
                }
            }
        })
    }
    
    
    func addCaptureSessionOutputDevice() {
        dispatch_async(self.sessionQueue, {
            println("Adding output device:")
            if let session = self.captureSession {
                if session.canAddOutput(self.imageOutput) {
                    session.addOutput(self.imageOutput)
                    println("  Added output object as output")
                } else {
                    println("  Could not add output object -> figure out why")
                }
            }
        })
    }
    
    
    // beginning the capture session.
    func setupCaptureSession() {
        self.captureSession             = AVCaptureSession()
        self.imageOutput                = AVCaptureStillImageOutput()
        self.imageOutput.outputSettings = [AVVideoCodecKey : AVVideoCodecJPEG]
        self.captureDevice              = AVCaptureDevice.deviceWithVideoInFront()
        
        self.setCaptureSessionPreset(AVCaptureSessionPreset352x288)
        self.addCaptureSessionInputDevice()
        self.addCaptureSessionOutputDevice()
    }
    
    
    func beginCaptureSession() {
        if self.config.boolForKey("useAutoTheme") == true {
            dispatch_async(self.sessionQueue, {
                println("Begin Capture Session")
                if let session = self.captureSession {
                    session.startRunning()
                    self.configureCaptureDevice()
                }
            })
        }
    }
    
    
    func endCaptureSession() {
        dispatch_async(self.sessionQueue, {
            if let session = self.captureSession {
                if session.running == true {
                    println("Stopping capture session")
                    session.stopRunning()
                }
            }
            
            self.captureSession = nil
            self.imageOutput    = nil
            self.captureDevice  = nil
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
                        self.doActualCapture()
                    }
                )
            } else {
                println("  Camera not supporting custom exposure mode.")
            }
            
            camera.unlockForConfiguration()
            println("Unlocked device configuration")
        }
        
    }
    
    
    func setupImageCaptureTimer() {
        println("Told to setup new image capture timer:")
        if (self.captureTimer == nil || self.captureTimer?.valid == false) {
            println("  Starting new capture NSTimer 4.0s")
            self.captureTimer = NSTimer.scheduledTimerWithTimeInterval(
                4.0,
                target: self,
                selector: "doActualCapture",
                userInfo: nil,
                repeats: true
            )
        }
    }
    
    func removeImageCaptureTimer() {
        println("Told to remove image capture timer.")
        if let timer : NSTimer = self.captureTimer {
            if timer.valid == true {
                println("  Found running timer - invalidating")
                timer.invalidate()
            }
        }
        
        self.captureTimer = nil
    }
    
    
    func doActualCapture() {
        println("Do actual capture called:")
        if let session = self.captureSession {
            if session.running == true {
                println("  Session running")
                if let connection = self.imageOutput.connectionWithMediaType(AVMediaTypeVideo) {
                    println("    Got connection")
                    if connection.active == true {
                        println("      Connection active - doing capture")
                        self.imageOutput.captureStillImageAsynchronouslyFromConnection(
                            self.imageOutput.connectionWithMediaType(AVMediaTypeVideo),
                            completionHandler: self.handleInputImage
                        )
                    }
                }
            }
        }
    }
    
    
    /// Does the actual handling of the image
    func handleInputImage(buffer: CMSampleBuffer!, error: NSError!) {
        dispatch_async(dispatch_get_main_queue(), {
            if (buffer == nil) {
                println("Got empty image buffer - an error")
                return
            }
            
            var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
            var image     = UIImage(data: imageData)!
            var luminance = image.luminance()
            
            self.setAutoTheme(luminance)
            
            if let camera = self.captureDevice {
                var duration = CMTimeGetSeconds(camera.exposureDuration) * 1000
                var time     = Int(round(duration))
                var iso      = Int(camera.ISO)
                
                self.ISOValueLabel.text = String(iso)
                self.expValueLabel.text = "\(time)/1000 s"
                self.lumValueLabel.text = String(format: "%.2f", Float(luminance))
            }
        })
    }
    
    
    ///////////////////////////////////////////////////////////////////////
    //
    //  Functions relating to theming and adjusting the visual style
    //  depending on settings
    //
    
    func setTheme() {
        if (config.boolForKey("useDarkTheme")) {
            self.setDarkTheme()
        } else {
            self.setLightTheme()
        }
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    
    func setAutoTheme(luminance: CGFloat) {
        if self.config.boolForKey("useAutoTheme") == false {
            return
        }
        
        if (luminance >= 0.5) {
            self.setLightThemeAnimated()
        }
        else if (luminance < 0.5) {
            self.setDarkThemeAnimated()
        }
        
        delay(0.5) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    
    func setDarkThemeAnimated() {
        UIView.animateWithDuration(1.0, animations: {
            self.view.backgroundColor = UIColor.blackColor()
        })
            
        statusLabel.textColor = UIColor.colorWithHex("#CCCCCC")
        activityIndicator.color = UIColor.colorWithHex("#CCCCCC")
    }
    
    
    func setLightThemeAnimated() {
        UIView.animateWithDuration(1.0, animations: {
            self.view.backgroundColor = UIColor.whiteColor()
        })
        
        statusLabel.textColor = UIColor.colorWithHex("#888888")
        activityIndicator.color = UIColor.colorWithHex("#888888")
    }
    
    
    func setDarkTheme() {
        self.view.backgroundColor = UIColor.blackColor()
        
        statusLabel.textColor = UIColor.colorWithHex("#CCCCCC")
        activityIndicator.color = UIColor.colorWithHex("#CCCCCC")
    }
    
    
    func setLightTheme() {
        self.view.backgroundColor = UIColor.whiteColor()
        
        statusLabel.textColor = UIColor.colorWithHex("#888888")
        activityIndicator.color = UIColor.colorWithHex("#888888")
    }

    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        if self.view.backgroundColor == UIColor.blackColor() {
            return UIStatusBarStyle.LightContent
        } else {
            return UIStatusBarStyle.Default
        }
    }

    
    ///////////////////////////////////////////////////////////////////////
    //
    //  Observers and their handlers
    //
    
    /// The full list of events the app is listening to.
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
            selector: Selector("appWillEnterForeground:"),
            name: UIApplicationWillEnterForegroundNotification,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: Selector("appDidBecomeActive:"),
            name: UIApplicationDidBecomeActiveNotification,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: Selector("appDidEnterBackground:"),
            name: UIApplicationDidEnterBackgroundNotification,
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
        
        nc.addObserver(
            self,
            selector: Selector("handleSettingsCancelled"),
            name: "settingsCancelled",
            object: nil
        )
    }
    
    ///////////////////////////////////////////////////////////////////////
    //
    //  App activity notifications
    //
    
    func appWillResignActive(notification: NSNotification) {
        println("App will resign active")
    }
    
    
    func appDidBecomeActive(notification: NSNotification) {
        println("App did become active")
    }
    
    
    func appWillTerminate(notification: NSNotification) {
        println("App will terminate")
        
        if self.config.boolForKey("useAutoTheme") == true {
            self.endCaptureSession()
        }
    }
    
    func appWillEnterForeground(notification: NSNotification) {
        println("App will enter foreground.")
        
        if self.config.boolForKey("useAutoTheme") == true {
            self.setupAutoTheme()
        } else {
            self.setupWithoutAutoTheme()
        }
    }
    
    func appDidEnterBackground(notification: NSNotification) {
        println("App did enter background")
        self.updateOpenButtonWait()
        
        if self.config.boolForKey("useAutoTheme") == true {
            self.removeImageCaptureTimer()
            self.endCaptureSession()
        }
    }

    ///////////////////////////////////////////////////////////////////////
    //
    //  Settings view notification handlers
    //
    
    func handleSettingsUpdated() {
        println("View told settings have updated")
        self.setTheme()
        
        if config.boolForKey("useAutoTheme") == true {
            println("  Use Auto Theme: true")
            if self.captureSession == nil {
                // only if we have a nil session to we need to start
                println("  Auto theme not running - starting")
                self.setupAutoTheme()
            }
        } else {
            println("  Use Auto Theme: false")
            self.removeImageCaptureTimer()
            self.endCaptureSession()
            self.setupWithoutAutoTheme()
        }
    }
    
    
    func handleSettingsCancelled() {
        println("View told settings was cancelled")
        
    }
    
    ///////////////////////////////////////////////////////////////////////
    
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
