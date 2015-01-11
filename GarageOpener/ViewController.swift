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
    
    var counter = 0
    var discovery : AnyObject?
    var nc = NSNotificationCenter.defaultCenter()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        textLog.text = ""
        self.addLogMsg("Starting...");
        
        nc.addObserver(self, selector: Selector("bleStateChanged:"), name: "bleStateChangedNotification", object: nil)
        discovery = BTDiscovery()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func openButtonPressed(sender: UIButton) {
        counter = counter + 1;
        
        self.addLogMsg("button push \(counter)")
        
    }
    
    func addLogMsg(msg: String) {
        textLog.text = textLog.text + "\n" + msg
        var length = countElements(textLog.text);
        var range = NSMakeRange(length - 1, 1);
        textLog.scrollRangeToVisible(range);
    }
    
    func bleStateChanged(notification: NSNotification) {
        var msg = notification.object as String
        println("got notification: \(msg)")
        dispatch_async(dispatch_get_main_queue(), {
            self.addLogMsg(msg)
        })
    }
}

