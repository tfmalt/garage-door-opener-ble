//
//  ViewController.swift
//  GarageOpener
//
//  Created by Thomas Malt on 10/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    @IBOutlet weak var textLog: UITextView!
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    
    var counter = 0
    var discovery : BTDiscoveryManager?
    var isConnected : Bool?
    var nc = NSNotificationCenter.defaultCenter()
    var config = NSUserDefaults.standardUserDefaults()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        isConnected = false
        
        textLog.text = ""
        self.addLogMsg("Initializing...");
        statusLabel.text = "Initializing";
        rssiLabel.text = "rssi: \(self.getConnectionBar(0)) [---]"
        
        self.makeButtonCircular()
        self.updateOpenButtonWait()
        
        nc.addObserver(self, selector: Selector("appWillResignActive:"), name: UIApplicationWillResignActiveNotification, object: nil)
        
        nc.addObserver(self, selector: Selector("appWillTerminate:"), name: UIApplicationWillTerminateNotification, object: nil)
            
        nc.addObserver(self, selector: Selector("btStateChanged:"), name: "btStateChangedNotification", object: nil)
        
        nc.addObserver(self, selector: Selector("btConnectionChanged:"), name: "btConnectionChangedNotification", object: nil)
        
        nc.addObserver(self, selector: Selector("btFoundDevice:"), name: "btFoundDeviceNotification", object: nil)
        
        nc.addObserver(self, selector: Selector("btUpdateRSSI:"), name: "btRSSIUpdateNotification", object: nil)
        
        discovery = BTDiscoveryManager()
    }

    func appWillResignActive(notification: NSNotification) {
        println("App will resign active")
        textLog.text = ""
    }
    
    func appWillTerminate(notification: NSNotification) {
        println("App will terminate")
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
        textLog.text = textLog.text + "\n" + msg
        var length = countElements(textLog.text);
        var range = NSMakeRange(length - 1, 1);
        textLog.scrollRangeToVisible(range);
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
            UIImage.imageWithColor(UIColor.colorWithHex("#0099CC")),
            forState: UIControlState.Normal
        )
        
        openButton.setBackgroundImage(
            UIImage.imageWithColor(UIColor.colorWithHex("#338822")),
            forState: UIControlState.Highlighted
        )
        
        self.openButton.setTitle("Open", forState: UIControlState.Normal)
        
    }
    
    func makeButtonCircular() {
        openButton.frame = CGRectMake(
            0, 0,
            openButton.bounds.size.width,
            openButton.bounds.size.height
        )
        
        openButton.clipsToBounds = true;
        openButton.layer.cornerRadius = 0.5 * openButton.bounds.size.width
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
            
            if (msg == "Disconnected") {
                self.updateOpenButtonWait()
                self.addLogMsg("Garage Opener Disconnected")
            }
            else if (msg == "Bluetooth Off") {
                self.updateOpenButtonWait()
                self.rssiLabel.text = "rssi: \(self.getConnectionBar(0)) [---]"
            }
            else if (msg == "Scanning") {
                self.updateOpenButtonWait()
                self.rssiLabel.text = "rssi: \(self.getConnectionBar(0)) [---]"
                self.addLogMsg("Scanning...")
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
                self.addLogMsg("Garage Opener Connected")
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
            
            self.addLogMsg("Found correct device (\(name)) (\(rssi))")
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
        
        var block = self.getConnectionBar(strength)
        
        // println("Got RSSI: \(rssi) \(quality) \(strength)")
        
        dispatch_async(dispatch_get_main_queue(), {
            self.rssiLabel.text = "rssi: \(block) [\(rssi)]"
        })
    }
}

