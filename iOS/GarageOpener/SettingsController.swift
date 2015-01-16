//
//  SettingsController.swift
//  GarageOpener
//
//  Created by Thomas Malt on 16/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation
import UIKit

class SettingsController : UITableViewController {
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var showPasswordSwitch: UISwitch!
    
    var config = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if let show = config.valueForKey("showPassword") as? Bool {
            showPasswordSwitch.on = show
        }
        
        if let pass = config.valueForKey("password") as? String {
            passwordField.text = pass
        }
        
        passwordField.secureTextEntry = !showPasswordSwitch.on
        
        println("Loaded settings controller")
    }
    
    @IBAction func handleShowPasswordChange(sender: UISwitch) {
        println("show password toggle changed: \(sender.on)")
        
        passwordField.secureTextEntry = !sender.on
        
        config.setBool(sender.on, forKey: "showPassword")
    }
    
    @IBAction func handleDonePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        println("modal closed: \(passwordField.text)")
        
        config.setObject(passwordField.text, forKey: "password")
    }
    
    @IBAction func handleCancelPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        println("modal closed")

    }
    
    func modalClosed() -> Void {
    }
}
