//
//  OpenerViewController.swift
//  GarageOpener
//
//  Created by Thomas Malt on 10/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import UIKit
import CoreBluetooth
import AVFoundation

// Constructing global singleton of this
var captureCtrl : GOCaptureController = GOCaptureController()

// Struct containing the colors I use.
struct GOOpenerColors {
    let wait              = UIColor.colorWithHex("#D00000")!
    let waitHighlight     = UIColor.colorWithHex("#D00000")!
    let open              = UIColor.colorWithHex("#33BB33")!
    let openHighlight     = UIColor.colorWithHex("#208840")!
    let scanning          = UIColor.colorWithHex("#D00000")!
    let scanningHighlight = UIColor.colorWithHex("#D00000")!
    let start             = UIColor.colorWithHex("#1080C0")! //  FFAA00
    let startHighlight    = UIColor.colorWithHex("#0C4778")! // 0C4778 FFDD00
}


class GOOpenerController: UIViewController {
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lumValueLabel: UILabel!
    @IBOutlet weak var lumLabel: UILabel!
    
    let Colors            = GOOpenerColors()
    let animationDuration = 1.0
    
    // An enum to keep track of the application states defined.
    enum States {
        case Connected
        case Initializing
        case Scanning
        case Waiting
        case DeviceNotFound
        case DeviceFound
        case BluetoothOff
        case Disconnected
    }
    
    
    var currentState = States.Disconnected
    
    var discovery   : BTDiscoveryManager?
    var captureCtrl : GOCaptureController = GOCaptureController()
    
    var needToShowCameraNotAuthorizedAlert : Bool = false
    var hasShownCameraNotAuthorized        : Bool = false
    
    var config = NSUserDefaults.standardUserDefaults()
    let nc     = NSNotificationCenter.defaultCenter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initLabels()
        self.makeButtonCircular()
        self.updateOpenButtonWait()
        self.registerObservers()
        self.setTheme()
        self.checkAndConfigureAutoTheme()
        
        self.discovery = BTDiscoveryManager()
    }
    
    
    func checkAndConfigureAutoTheme() {
        if self.config.boolForKey("useAutoTheme") == true {
            println("View: auto theme true - trying to init capture.")
            self.initAutoThemeLabels()
            self.captureCtrl.initializeCaptureSession()
        } else {
            println("View: Auto Theme disabled")
            self.setupWithoutAutoTheme()
        }
    }
    
    
    func initLabels() {
        self.statusLabel.text   = "Initializing";
        self.rssiLabel.text     = self.getConnectionBar(0)
        self.lumValueLabel.text = ""
    }
    
    
    override func viewDidAppear(animated: Bool) {
        if self.needToShowCameraNotAuthorizedAlert == true {
            self.showCameraNotAuthorizedAlert()
        }
        
        self.hasShownCameraNotAuthorized = true
    }
    
    
    func showCameraNotAuthorizedAlert() {
        let alert = self.captureCtrl.getCameraNotAuthorizedAlert()
        self.presentViewController(alert, animated: true, completion: { () -> Void in
            self.needToShowCameraNotAuthorizedAlert = false
        })
    }
    
    
    func handleCaptureDeviceNotAuthorized(notification: NSNotification) {
        println("View: got notified capture is not authorized.")
        
        config.setBool(false, forKey: "useAutoTheme")
        self.setupWithoutAutoTheme()
        if self.hasShownCameraNotAuthorized == false {
            if (self.isViewLoaded() && (self.view.window != nil)) {
                self.showCameraNotAuthorizedAlert()
            } else {
                self.needToShowCameraNotAuthorizedAlert = true
            }
        } else {
            println("  - View: alert already shown - not showing again.")
        }
    }

    
    func handleCaptureDeviceAuthorizationNotDetermined(notification: NSNotification) {
        setupWithoutAutoTheme()
        config.setBool(false, forKey: "useAutoTheme")
    }
    
    
    func initAutoThemeLabels() {
        lumLabel.text = "Lum:"
    }
    
    
    func setupWithoutAutoTheme() {
        lumLabel.text = ""
        lumValueLabel.text = ""
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
    
    /// Updates the automatic theme settings based on the luminance value
    func updateAutoTheme(luminance: Float) {
        if self.config.boolForKey("useAutoTheme") == false {
            return
        }
        
        if (luminance >= 0.50) {
            self.setLightThemeAnimated()
        }
        else if (luminance <= 0.40) {
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
            selector: "handleBTScanningTimedOut:",
            name: "BTDiscoveryScanningTimedOutNotification",
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
            selector: "handleSettingsUpdated",
            name: "SettingsUpdatedNotification",
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: Selector("handleSettingsCancelled"),
            name: "SettingsCancelledNotification",
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: "handleLightLevelUpdate:",
            name: "GOCaptureCalculatedLightLevelNotification",
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: "handleCaptureDeviceNotAuthorized:",
            name: "GOCaptureDeviceNotAuthorizedNotification",
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: "handleCaptureDeviceAuthorizationNotDetermined:",
            name: "GOCaptureDeviceAuthorizationNotDetermined",
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
    
    func appWillEnterForeground(notification: NSNotification) {
        println("GOOpener: App will enter foreground.")
        self.checkAndConfigureAutoTheme()
    }
    
    func appDidEnterBackground(notification: NSNotification) {
        println("GOOpener: App did enter background")
        self.updateOpenButtonWait()
        self.captureCtrl.removeImageCaptureTimer()
        self.captureCtrl.endCaptureSession()
    }

    ///////////////////////////////////////////////////////////////////////
    //
    //  Settings view notification handlers
    //
    
    func handleSettingsUpdated() {
        println("View:  told settings have updated")
        self.setTheme()
        
        if self.config.boolForKey("useAutoTheme") == true {
            self.initAutoThemeLabels()
        } else {
            self.setupWithoutAutoTheme()
        }
    }
    
    
    func handleSettingsCancelled() {
        println("View told settings was cancelled")
        
    }
    
    ///////////////////////////////////////////////////////////////////////
    
    func handleLightLevelUpdate(notification: NSNotification) {
        var info      = notification.userInfo    as [String : AnyObject]
        var luminance = info["luminance"]        as Float
        
        dispatch_async(dispatch_get_main_queue(), {
            self.updateAutoTheme(luminance)
            self.lumValueLabel.text = String(format: "%.2f", luminance)
        })
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
        if self.currentState == States.Connected {
            self.sendOpenCommand()
            return
        }
        
        if self.currentState == States.DeviceNotFound {
            NSLog("GOOpener: button pressed: state: device not found")
            if let discovery = self.discovery {
                discovery.startScanning()
            }
            return
        }
    }
    
    
    func sendOpenCommand() {
        if let rx = self.getRXCharacteristic() {
            if let peripheral = self.getActivePeripheral() {
                if let pass = config.valueForKey("password") as? String {
                    var str = "0" + pass;
                    var data : NSData = str.dataUsingEncoding(NSUTF8StringEncoding)!
                    
                    peripheral.writeValue(
                        data,
                        forCharacteristic: rx,
                        type: CBCharacteristicWriteType.WithoutResponse
                    )
                } else {
                    println("Did not find valid password, so not writing anything")
                }
            }
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
        
        UIView.animateWithDuration(1.0, animations: {
            self.openButton.backgroundColor = self.Colors.wait
        })
        
        openButton.setBackgroundImage(
            UIImage.imageWithColor(self.Colors.wait),
            forState: UIControlState.Highlighted
        )

        openButton.setTitle("Wait", forState: UIControlState.Normal)
    }
    
    
    func updateOpenButtonNormal() {
        
        UIView.animateWithDuration(1.0, animations: {
            self.openButton.backgroundColor = self.Colors.open
        })
        
        openButton.setBackgroundImage(
            UIImage.imageWithColor(self.Colors.openHighlight),
            forState: UIControlState.Highlighted
        )
        
        self.openButton.setTitle("Open", forState: UIControlState.Normal)
    }
    
    func updateOpenButtonScanning() {
        
        UIView.animateWithDuration(1.0, animations: {
            self.openButton.backgroundColor = self.Colors.scanning
        })
        
        self.openButton.setBackgroundImage(
            UIImage.imageWithColor(self.Colors.scanning),
            forState: UIControlState.Highlighted
        )
        
        self.openButton.setTitle("Wait", forState: UIControlState.Normal)
    }
    
    func updateOpenButtonStartScan() {
        
        UIView.animateWithDuration(1.0, animations: {
            self.openButton.backgroundColor = self.Colors.start
        })
        
        self.openButton.setBackgroundImage(
            UIImage.imageWithColor(self.Colors.startHighlight),
            forState: UIControlState.Highlighted
        )

        
        openButton.setTitle("Start", forState: UIControlState.Normal)
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
        
        NSLog("GOOpener: bt state changed: got notification: \(msg)")
        
        dispatch_async(dispatch_get_main_queue(), {
            if (msg.hasPrefix("Low Signal")) {
                self.currentState = States.Scanning
                return
            }
            
            self.statusLabel.text = msg

            if (msg != "Scanning") {
                self.activityIndicator.stopAnimating()
            }
            
            if (msg == "Disconnected") {
                self.currentState = States.Disconnected
                self.updateOpenButtonWait()
            }
            else if (msg == "Bluetooth Off") {
                self.currentState = States.BluetoothOff
                self.updateOpenButtonWait()
                self.rssiLabel.text = self.getConnectionBar(0)
            }
            else if (msg == "Scanning") {
                self.currentState = States.Scanning
                self.updateOpenButtonScanning()
                self.rssiLabel.text = self.getConnectionBar(0)
                self.activityIndicator.startAnimating()
            }
        })
    }
    
    
    func handleBTScanningTimedOut(notification: NSNotification) {
        self.currentState = States.DeviceNotFound
        dispatch_async(dispatch_get_main_queue(), {
            self.updateOpenButtonWait()
            self.rssiLabel.text = self.getConnectionBar(0)
            self.activityIndicator.stopAnimating()
            self.statusLabel.text = "Device Not Found"
            
            self.delay(2.0) {
                self.updateOpenButtonStartScan()
                self.statusLabel.text = "Scan Finished"
            }
        })
    }
    
    
    /// Handler for the connection.
    func btConnectionChanged(notification: NSNotification) {
        println("got connection changed notification: \(notification)")
        
        let info = notification.userInfo as [String: AnyObject]
        var name = info["name"]          as NSString
        
        if name.length < 1 {
            name = ""
        } else {
            name = " to " + name
        }
        
        if let isConnected = info["isConnected"] as? Bool {
            self.currentState = States.Connected
            
            dispatch_async(dispatch_get_main_queue(), {
                self.updateOpenButtonNormal()
                self.statusLabel.text = "Connected\(name)"
                self.activityIndicator.stopAnimating()
            })
        
        }
    }
    
    func btFoundDevice(notification: NSNotification) {
        println("got found device notification: \(notification)")
        
        let info       = notification.userInfo as [String: AnyObject]
        var peripheral = info["peripheral"]    as CBPeripheral
        var rssi       = info["RSSI"]          as NSNumber
        var name       = String(peripheral.name)
        
        self.currentState = States.DeviceFound
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

