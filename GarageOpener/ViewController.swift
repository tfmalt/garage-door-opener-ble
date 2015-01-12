//
//  ViewController.swift
//  GarageOpener
//
//  Created by Thomas Malt on 10/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var textLog: UITextView!
    @IBOutlet weak var openButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    var counter = 0
    var discovery : AnyObject?
    var isConnected : Bool?
    var nc = NSNotificationCenter.defaultCenter()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        isConnected = false
        
        textLog.text = ""
        self.addLogMsg("Initializing...");
        statusLabel.text = "Initializing...";
        
        openButton.layer.cornerRadius = 0.5 * openButton.bounds.size.width
        var color = UIColor(red: 0.9, green: 0.0, blue: 0.0, alpha: 1.0)
        openButton.backgroundColor = color; // UIColor.redColor()
        openButton.setTitle("Wait", forState: UIControlState.Normal)
        
        nc.addObserver(self, selector: Selector("btStateChanged:"), name: "btStateChangedNotification", object: nil)
        
        nc.addObserver(self, selector: Selector("btConnectionChanged:"), name: "btConnectionChangedNotification", object: nil)
        
        nc.addObserver(self, selector: Selector("btFoundDevice:"), name: "btFoundDeviceNotification", object: nil)
        
        discovery = BTDiscoveryManager()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func openButtonPressed(sender: UIButton) {
        counter = counter + 1;
        
        self.addLogMsg("button push \(counter)")
        
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
    
    /// Listens to notifications about CoreBluetooth state changes
    ///
    /// :param: notification The NSNotification object
    /// :returns: nil
    func btStateChanged(notification: NSNotification) {
        var msg = notification.object as String
        println("got notification: \(msg)")
        dispatch_async(dispatch_get_main_queue(), {
            self.addLogMsg(msg)
            self.statusLabel.text = "Scanning..."
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
        
        dispatch_async(dispatch_get_main_queue(), {
            self.openButton.backgroundColor = UIColor.orangeColor()
            self.statusLabel.text = "Found Device..."
            
            self.addLogMsg("Found correct device")
        })
        
    }
}

