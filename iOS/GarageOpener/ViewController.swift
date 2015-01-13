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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        isConnected = false
        
        textLog.text = ""
        self.addLogMsg("Initializing...");
        statusLabel.text = "Initializing";
        rssiLabel.text = self.getConnectionBar(0)
        
        openButton.layer.cornerRadius = 0.5 * openButton.bounds.size.width
        
        self.updateOpenButtonWait()
        
        nc.addObserver(self, selector: Selector("btStateChanged:"), name: "btStateChangedNotification", object: nil)
        
        nc.addObserver(self, selector: Selector("btConnectionChanged:"), name: "btConnectionChangedNotification", object: nil)
        
        nc.addObserver(self, selector: Selector("btFoundDevice:"), name: "btFoundDeviceNotification", object: nil)
        
        nc.addObserver(self, selector: Selector("btUpdateRSSI:"), name: "btRSSIUpdateNotification", object: nil)
        
        discovery = BTDiscoveryManager()
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
        
        self.addLogMsg("button pressed: \(counter)")
        println("Button got pressed:")
        if self.discovery == nil {
            println("  Could not find discovery object.")
            return
        }
        
        let peripheral = self.discovery?.activePeripheral
        
        if peripheral == nil {
            println("  Did not get active peripheral.")
            return
        }
        
        if peripheral?.state != CBPeripheralState.Connected {
            println("  Peripheral apparently is not connected.")
            return
        }
        
        let service = self.discovery?.activeService
        
        if service == nil {
            println("  Did not get active service.")
            return
        }
        
        let tx = service?.txCharacteristic
        if (tx == nil) {
            println("  Did not get tx characteristic.")
            return
        }
        
        let rx = service?.rxCharacteristic
        if (rx == nil) {
            println("  Did not get rx characteristic")
            return
        }
        
        
        var str = "0Martha";
        var data : NSData = str.dataUsingEncoding(NSUTF8StringEncoding)!
        
        peripheral?.writeValue(data, forCharacteristic: rx, type: CBCharacteristicWriteType.WithoutResponse)
        
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
        
        openButton.backgroundColor = color;
        openButton.setTitle("Wait", forState: UIControlState.Normal)
    }
    
    func updateOpenButtonScanning() {
        let color = UIColor.orangeColor()
        
        openButton.backgroundColor = color;
        openButton.setTitle("Wait", forState: UIControlState.Normal)
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
            self.addLogMsg(log)
            
            if (msg.hasPrefix("Low Signal")) {
                return
            }
            self.statusLabel.text = msg
            
            if (msg == "Bluetooth Off") {
                self.updateOpenButtonWait()
                self.rssiLabel.text = self.getConnectionBar(0)
            }
            else if (msg == "Scanning") {
                self.updateOpenButtonScanning()
                self.rssiLabel.text = self.getConnectionBar(0)
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
            
                self.openButton.backgroundColor = UIColor(
                    red: 0.0, green: 0.6, blue: 0.8, alpha: 1.0
                )
                self.openButton.setTitle("Open", forState: UIControlState.Normal)
                self.statusLabel.text = "Connected"
            
                self.addLogMsg("Device connected")
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
    
    func btUpdateRSSI(notification: NSNotification) {
        // println("got update rssi notification")
        
        let info = notification.userInfo as [String: NSNumber]
        let peripheral = notification.object as CBPeripheral
        var rssi : NSNumber! = info["rssi"]
        
        if peripheral.state != CBPeripheralState.Connected {
            println("  peripheral state says not connected!")
            return
        }
        
        var b = "\u{25A0}"
        var s = "\u{25A1}"
        
        var block = ""
        if (rssi.integerValue > -50) {
            block = b + b + b + b + b
        }
        else if (rssi.integerValue > -60) {
            block = b + b + b + b + s
        }
        else if (rssi.integerValue > -70) {
            block = b + b + b + s + s
        }
        else if rssi.integerValue > -80 {
            block = b + b + s + s + s
        }
        else if rssi.integerValue > -90 {
            block = b + s + s + s + s
        }
        else if rssi.integerValue > -100 {
            block = s + s + s + s + s
        }

        
        
        dispatch_async(dispatch_get_main_queue(), {
            self.rssiLabel.text = block
            self.addLogMsg("Got RSSI from Device: \(rssi.integerValue)")
        })
    }
}

