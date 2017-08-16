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

extension CBCentralManager {
    internal var centralManagerState: CBCentralManagerState  {
        get {
            return CBCentralManagerState(rawValue: state.rawValue) ?? .unknown
        }
    }
}

// Constructing global singleton of this
var captureCtrl : GOCaptureController = GOCaptureController()

// Struct containing the colors I use.
struct Colors {
    static let wait              = UIColor.colorWithHex("#D00000")!
    static let waitHighlight     = UIColor.colorWithHex("#D00000")!
    static let open              = UIColor.colorWithHex("#33BB33")!
    static let openHighlight     = UIColor.colorWithHex("#208840")!
    static let scanning          = UIColor.colorWithHex("#D00000")!
    static let scanningHighlight = UIColor.colorWithHex("#D00000")!
    static let start             = UIColor.colorWithHex("#1080C0")! //  FFAA00
    static let startHighlight    = UIColor.colorWithHex("#0C4778")! // 0C4778 FFDD00
}


class GOOpenerController: UIViewController {
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var lumValueLabel: UILabel!
    @IBOutlet weak var lumLabel: UILabel!
    
    let AnimationDuration = 0.5
    
    // An enum to keep track of the application states defined.
    public enum States {
        case connected
        case initializing
        case scanning
        case waiting
        case deviceNotFound
        case deviceFound
        case bluetoothOff
        case disconnected
    }
    
    
    var currentState = States.disconnected
    
    var discovery   : BTDiscoveryManager?
    var captureCtrl : GOCaptureController = GOCaptureController()
    
    var needToShowCameraNotAuthorizedAlert : Bool = false
    var hasShownCameraNotAuthorized        : Bool = false
    
    var config = UserDefaults.standard
    let nc     = NotificationCenter.default
    
    let DEMO  : Bool = false
    let STATE : States = States.scanning
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initLabels()
        self.makeButtonCircular()
        
        if DEMO == true {
            self.setTheme()
            
            switch (STATE) {
            case States.connected:
                self.updateOpenButtonNormal()
                self.setupWithoutAutoTheme()
                self.setSignalLevel(3)
                self.activityIndicator.stopAnimating()
//                self.setStatusLabel("Connected to Home")
                break
                
            case States.scanning:
                self.updateOpenButtonScanning()
                self.setupWithoutAutoTheme()
//                self.setStatusLabel("Scanning")
                break
            default:
                self.updateOpenButtonWait()
                break
            }
            
        } else {
        
            self.updateOpenButtonWait()
            self.registerObservers()
            self.setTheme()
            self.checkAndConfigureAutoTheme()
        
            self.discovery = BTDiscoveryManager()
        }
    }
    
    
    func checkAndConfigureAutoTheme() {
        if self.config.bool(forKey: "useAutoTheme") == true {
            self.initAutoThemeLabels()
            self.captureCtrl.initializeCaptureSession()
        } else {
            self.setupWithoutAutoTheme()
        }
    }
    
    
    func initLabels() {
        self.lumValueLabel.text = ""
        
//        self.setStatusLabel("Initializing")
        self.setSignalLevel(0)
    }
    
    
    /// updates the rssiLabel with the signal meter number
    func setSignalLevel(_ strength: Int) {
        assert(
            (strength >= 0 && strength <= 5),
            "argument strength need to be an Integer between 0 and 5."
        )
        
        if let label = self.rssiLabel {
            label.text = self.getConnectionBar(strength)
        }
    }
    
    /// updates the status label with new text.
//    func setStatusLabel(_ text: String) {
//        if let label = self.statusLabel {
//            label.text = text
//        }
//    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        if self.needToShowCameraNotAuthorizedAlert == true {
            self.showCameraNotAuthorizedAlert()
        }
        
        self.hasShownCameraNotAuthorized = true
    }
    
    
    func showCameraNotAuthorizedAlert() {
        let alert = self.captureCtrl.getCameraNotAuthorizedAlert()
        self.present(alert, animated: true, completion: { () -> Void in
            self.needToShowCameraNotAuthorizedAlert = false
        })
    }
    
    
    func handleCaptureDeviceNotAuthorized(_ notification: Notification) {
        config.set(false, forKey: "useAutoTheme")
        self.setupWithoutAutoTheme()
        
        if self.hasShownCameraNotAuthorized == false {
            if (self.isViewLoaded && (self.view.window != nil)) {
                self.showCameraNotAuthorizedAlert()
            } else {
                self.needToShowCameraNotAuthorizedAlert = true
            }
        }
    }

    
    func handleCaptureDeviceAuthorizationNotDetermined(_ notification: Notification) {
        setupWithoutAutoTheme()
        config.set(false, forKey: "useAutoTheme")
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
        if (config.bool(forKey: "useDarkTheme")) {
            self.setDarkTheme()
        } else {
            self.setLightTheme()
        }
        
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    /// Updates the automatic theme settings based on the luminance value
    func updateAutoTheme(_ luminance: Float) {
        if self.config.bool(forKey: "useAutoTheme") == false {
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
        UIView.animate(withDuration: AnimationDuration, animations: {
            self.view.backgroundColor = UIColor.black
        })
            
        statusLabel.textColor = UIColor.colorWithHex("#CCCCCC")
        activityIndicator.color = UIColor.colorWithHex("#CCCCCC")
    }
    
    
    func setLightThemeAnimated() {
        UIView.animate(withDuration: AnimationDuration, animations: {
            self.view.backgroundColor = UIColor.white
        })
        
        statusLabel.textColor = UIColor.colorWithHex("#888888")
        activityIndicator.color = UIColor.colorWithHex("#888888")
    }
    
    
    func setDarkTheme() {
        self.view.backgroundColor = UIColor.black
        
        statusLabel.textColor = UIColor.colorWithHex("#CCCCCC")
        activityIndicator.color = UIColor.colorWithHex("#CCCCCC")
    }
    
    
    func setLightTheme() {
        self.view.backgroundColor = UIColor.white
        
        statusLabel.textColor = UIColor.colorWithHex("#888888")
        activityIndicator.color = UIColor.colorWithHex("#888888")
    }

    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        if self.view.backgroundColor == UIColor.black {
            return UIStatusBarStyle.lightContent
        } else {
            return UIStatusBarStyle.default
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
            selector: #selector(GOOpenerController.appWillEnterForeground(_:)),
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOOpenerController.appDidEnterBackground(_:)),
            name: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOOpenerController.btStateChanged(_:)),
            name: NSNotification.Name(rawValue: "btStateChangedNotification"),
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOOpenerController.handleBTScanningTimedOut(_:)),
            name: NSNotification.Name(rawValue: "BTDiscoveryScanningTimedOutNotification"),
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOOpenerController.btConnectionChanged(_:)),
            name: NSNotification.Name(rawValue: "btConnectionChangedNotification"),
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOOpenerController.btFoundDevice(_:)),
            name: NSNotification.Name(rawValue: "btFoundDeviceNotification"),
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOOpenerController.btUpdateRSSI(_:)),
            name: NSNotification.Name(rawValue: "btRSSIUpdateNotification"),
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOOpenerController.handleSettingsUpdated),
            name: NSNotification.Name(rawValue: "SettingsUpdatedNotification"),
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOOpenerController.handleLightLevelUpdate(_:)),
            name: NSNotification.Name(rawValue: "GOCaptureCalculatedLightLevelNotification"),
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOOpenerController.handleCaptureDeviceNotAuthorized(_:)),
            name: NSNotification.Name(rawValue: "GOCaptureDeviceNotAuthorizedNotification"),
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOOpenerController.handleCaptureDeviceAuthorizationNotDetermined(_:)),
            name: NSNotification.Name(rawValue: "GOCaptureDeviceAuthorizationNotDetermined"),
            object: nil
        )
    }
    
    ///////////////////////////////////////////////////////////////////////
    //
    //  App activity notifications
    //
    
    func appWillEnterForeground(_ notification: Notification) {
        self.updateOpenButtonWait()
        self.checkAndConfigureAutoTheme()
    }
    
    func appDidEnterBackground(_ notification: Notification) {
        self.updateOpenButtonWait()
        self.captureCtrl.removeImageCaptureTimer()
        self.captureCtrl.endCaptureSession()
    }

    ///////////////////////////////////////////////////////////////////////
    //
    //  Settings view notification handlers
    //
    
    func handleSettingsUpdated() {
        self.setTheme()
        
        if self.config.bool(forKey: "useAutoTheme") == true {
            self.initAutoThemeLabels()
        } else {
            self.setupWithoutAutoTheme()
        }
    }
    
    ///////////////////////////////////////////////////////////////////////
    
    func handleLightLevelUpdate(_ notification: Notification) {
        var info      = notification.userInfo    as! [String : AnyObject]
        let luminance = info["luminance"]        as! Float
        
        DispatchQueue.main.async(execute: {
            self.updateAutoTheme(luminance)
            self.lumValueLabel.text = String(format: "%.2f", luminance)
        })
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func getConnectionBar(_ strength: Int) -> String {
        let s : String = "\u{25A1}"
        let b : String = "\u{25A0}"
        
        var result : String = ""
        for i in 0 ..< 5 {
            if i < strength {
                result = result + b;
            } else {
                result = result + s;
            }
        }
        return result
    }
    

    @IBAction func openButtonPressed(_ sender: UIButton) {
        if self.currentState == States.connected {
            self.sendOpenCommand()
            return
        }
        
        if self.currentState == States.deviceNotFound {
            if let discovery = self.discovery {
                discovery.startScanning()
            }
            return
        }
    }
    
    
    func sendOpenCommand() {
        if let rx = self.getRXCharacteristic() {
            if let peripheral = self.getActivePeripheral() {
                if let pass = config.value(forKey: "password") as? String {
                    let str = "0" + pass;
                    let data : Data = str.data(using: String.Encoding.utf8)!
                    
                    peripheral.writeValue(
                        data,
                        for: rx,
                        type: CBCharacteristicWriteType.withoutResponse
                    )
                }
            }
        }
    }
    
    func getActivePeripheral() -> CBPeripheral? {
        if self.discovery == nil { return nil }
        
        if let peripheral = self.discovery!.activePeripheral {
            if peripheral.state != CBPeripheralState.connected { return nil }
            return peripheral
        }
        
        return nil
    }
    
    
    func getRXCharacteristic() -> CBCharacteristic? {
        if let peripheral = self.getActivePeripheral() {
            if let service = self.discovery?.activeService {
                if let rx = service.rxCharacteristic {
                    return rx
                }
            }
        }
        
        return nil
    }
    
    
    func updateOpenButtonWait() {
        
        UIView.animate(withDuration: AnimationDuration, animations: {
            self.openButton.backgroundColor = Colors.wait
        })
        
        openButton.setBackgroundImage(
            UIImage.imageWithColor(Colors.wait),
            for: UIControlState.highlighted
        )

        openButton.setTitle("Wait", for: UIControlState())
    }
    
    
    func updateOpenButtonNormal() {
        
        UIView.animate(withDuration: AnimationDuration, animations: {
            self.openButton.backgroundColor = Colors.open
        })
        
        openButton.setBackgroundImage(
            UIImage.imageWithColor(Colors.openHighlight),
            for: UIControlState.highlighted
        )
        
        self.openButton.setTitle("Open", for: UIControlState())
    }
    
    func updateOpenButtonScanning() {
        
        UIView.animate(withDuration: AnimationDuration, animations: {
            self.openButton.backgroundColor = Colors.scanning
        })
        
        self.openButton.setBackgroundImage(
            UIImage.imageWithColor(Colors.scanning),
            for: UIControlState.highlighted
        )
        
        self.openButton.setTitle("Wait", for: UIControlState())
    }
    
    func updateOpenButtonStartScan() {
        
        UIView.animate(withDuration: AnimationDuration, animations: {
            self.openButton.backgroundColor = Colors.start
        })
        
        self.openButton.setBackgroundImage(
            UIImage.imageWithColor(Colors.startHighlight),
            for: UIControlState.highlighted
        )

        
        openButton.setTitle("Connect", for: UIControlState())
    }
    
    /// Updates the button to make size and layout is correct.
    func makeButtonCircular() {
        openButton.frame              = CGRect(x: 0, y: 0, width: 180, height: 180);
        openButton.clipsToBounds      = true;
        openButton.layer.cornerRadius = 90
    }
    
    
    /// Listens to notifications about CoreBluetooth state changes
    ///
    /// :param: notification The NSNotification object
    /// :returns: nil
    func btStateChanged(_ notification: Notification) {
        let msg = notification.object as! String
        
        DispatchQueue.main.async(execute: {
            if (msg.hasPrefix("Low Signal")) {
                self.currentState = States.scanning
                return
            }
            
//            self.setStatusLabel(msg)

            if (msg != "Scanning") {
                self.activityIndicator.stopAnimating()
            }
            
            if (msg == "Disconnected") {
                self.currentState = States.disconnected
                self.updateOpenButtonWait()
            }
            else if (msg == "Bluetooth Off") {
                self.currentState = States.bluetoothOff
                self.updateOpenButtonWait()
                self.setSignalLevel(0)
            }
            else if (msg == "Scanning") {
                self.currentState = States.scanning
                self.updateOpenButtonScanning()
                self.setSignalLevel(0)
                self.activityIndicator.startAnimating()
            }
        })
    }
    
    
    func handleBTScanningTimedOut(_ notification: Notification) {
        self.currentState = States.deviceNotFound
        DispatchQueue.main.async(execute: {
            self.updateOpenButtonWait()
            self.setSignalLevel(0)
            self.activityIndicator.stopAnimating()
//            self.setStatusLabel("Device Not Found")
            
            self.delay(2.0) {
                self.updateOpenButtonStartScan()
//                self.setStatusLabel("Scan Finished")
            }
        })
    }
    
    
    /// Handler for the connection.
    func btConnectionChanged(_ notification: Notification) {
        let info = notification.userInfo as! [String: AnyObject]
        var name = info["name"]          as! NSString
        
        if name.length < 1 {
            name = ""
        } else {
            name = NSString(string: " to \(name)")
        }
        
        if let isConnected = info["isConnected"] as? Bool {
            self.currentState = States.connected
            
            DispatchQueue.main.async(execute: {
                self.updateOpenButtonNormal()
//                self.setStatusLabel("Connected\(name)")
                self.activityIndicator.stopAnimating()
            })
        
        }
    }
    
    func btFoundDevice(_ notification: Notification) {
        let info       = notification.userInfo as! [String: AnyObject]
        let peripheral = info["peripheral"]    as! CBPeripheral
        var rssi       = info["RSSI"]          as! NSNumber
        var name       = String(describing: peripheral.name)
        
        self.currentState = States.deviceFound
        DispatchQueue.main.async(execute: {
            self.openButton.backgroundColor = UIColor.orange
//            self.setStatusLabel("Found Device...")
        })
    }
    
    func getQualityFromRSSI(_ RSSI: NSNumber!) -> Int {
        var quality = 2 * (RSSI.intValue + 100);
        
        if quality < 0 { quality = 0 }
        if quality > 100 { quality = 100 }
        
        return quality
    }
    
    func btUpdateRSSI(_ notification: Notification) {
        let info = notification.userInfo as! [String: NSNumber]
        let peripheral = notification.object as! CBPeripheral
        let rssi : NSNumber! = info["rssi"]
        
        if peripheral.state != CBPeripheralState.connected {
            return
        }
        
        let quality  : Int = self.getQualityFromRSSI(rssi)
        let strength : Int = Int(ceil(Double(quality) / 20))
        
        DispatchQueue.main.async(execute: {
            self.setSignalLevel(strength)
        })
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure
        )
    }
    
}

