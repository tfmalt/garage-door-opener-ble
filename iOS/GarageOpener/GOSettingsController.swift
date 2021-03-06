//
//  SettingsController.swift
//  GarageOpener
//
//  Created by Thomas Malt on 16/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class GOSettingsController : UITableViewController, UITextFieldDelegate {
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var showPasswordSwitch: UISwitch!
    @IBOutlet weak var darkThemeSwitch: UISwitch!
    @IBOutlet weak var themeAutoSwitch: UISwitch!
    
    var config = NSUserDefaults.standardUserDefaults()
    var nc     = NSNotificationCenter.defaultCenter()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nc.addObserver(
            self,
            selector: "handleCaptureDeviceNotAuthorized:",
            name: "GOCaptureDeviceNotAuthorizedNotification",
            object: nil
        )
        
        self.passwordField.delegate = self
        
        tableView.separatorColor = UIColor.colorWithHex("#cccccc")
        self.configureSettings()
        
        println("Loaded settings controller")
    }
    
    /// Setting up the switches to default
    func configureSettings() {
        if let show = config.valueForKey("showPassword") as? Bool {
            showPasswordSwitch.on = show
        }
        
        if let pass = config.valueForKey("password") as? String {
            passwordField.text = pass
        }
        
        if let darkOn = config.valueForKey("useDarkTheme") as? Bool {
            darkThemeSwitch.on = darkOn
        }
        
        if let autoOn = config.valueForKey("useAutoTheme") as? Bool {
            themeAutoSwitch.on = autoOn
        }
        
        passwordField.secureTextEntry = !showPasswordSwitch.on
    }
    
    
    @IBAction func handleDarkThemeChange(sender: UISwitch) {
        config.setBool(sender.on, forKey: "useDarkTheme")
    }
    
    @IBAction func handleAutoThemeChange(sender: UISwitch) {
        config.setBool(sender.on, forKey: "useAutoTheme")
        
        if sender.on == true {
            nc.postNotificationName(
                "GOSettingsRequestCameraAccessNotification",
                object: config
            )
        }
    }
    

    @IBAction func handleShowPasswordChange(sender: UISwitch) {
        passwordField.secureTextEntry = !sender.on
        config.setBool(sender.on, forKey: "showPassword")
    }
    
    /// Store password and notify main view when done is pressed
    @IBAction func handleDonePressed(sender: AnyObject) {
        config.setObject(passwordField.text, forKey: "password")
        
        self.passwordField.resignFirstResponder()
        self.dismissViewControllerAnimated(true, completion: nil)
        
        nc.postNotificationName("SettingsUpdatedNotification", object: config)
    }
    
    
    /// Post notification to main view when cancel is pressed
    @IBAction func handleCancelPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.passwordField.resignFirstResponder()
        
        nc.postNotificationName("SettingsCancelledNotification", object: config)
    }
    
    
    func handleCaptureDeviceNotAuthorized(notification: NSNotification) {
        var captureCtrl = notification.object as GOCaptureController
        
        println("Settings: Got notification capture not authorized")
        if (self.isViewLoaded() && (self.view.window != nil)) {
            let alert = captureCtrl.getCameraNotAuthorizedAlert()
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            println("  - Setting auto theme = false")
            self.config.setBool(false, forKey: "useAutoTheme")
            self.themeAutoSwitch.on = false
        })
        
    }
    
    /// Iterating over the sections in the table view to update the 
    /// appearance by changing font and case to make it look more like the
    /// standard settings view in the settings app
    ///
    /// :return: UIView
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 28))

        header.backgroundColor = UIColor.colorWithHex("#EEEEEE")
        
        if (section == 1) {
            
            let text   : UILabel = self.getLabel()
            let border : CALayer = self.getBottomBorder()
            
            text.text = String("authentication").uppercaseString
            
            header.addSubview(text)
            header.layer.addSublayer(border)
        }
        
        if (section == 2) {
            let text   : UILabel = self.getLabel()
            let border : CALayer = self.getBottomBorder()
            
            text.text = String("Theme").uppercaseString
            
            header.addSubview(text)
            header.layer.addSublayer(border)
        }
        
        return header
    }
    
    
    /// Iterates over the tableview sections and updates all the footers
    /// to look nice
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 40));
        footer.backgroundColor = UIColor.colorWithHex("#EEEEEE")
        
        if (section == 1 || section == 2) {
            let border = CALayer();
            border.frame = CGRectMake(0, 0, tableView.frame.size.width, 0.5)
            border.backgroundColor = UIColor.colorWithHex("#CCCCCC")?.CGColor
            
            footer.layer.addSublayer(border)
        }
        
        return footer
    }
    
    
    /// Helper function to draw a bottom border on the top header for 
    /// beautiful effect
    func getBottomBorder() -> CALayer {
        let border = CALayer();
        
        border.frame = CGRectMake(0, 22, tableView.frame.size.width, 0.5)
        border.backgroundColor = UIColor.colorWithHex("#CCCCCC")?.CGColor
        
        return border
    }
    
    
    /// Helper function to draw the tableview cells the way I want.
    func getLabel() -> UILabel {
        let text = UILabel(
            frame: CGRectMake(18, -4 ,
            tableView.frame.size.width, 28)
        )
        
        text.font = UIFont.systemFontOfSize(14.0)
        text.textColor = UIColor.colorWithHex("#666666")
        
        return text
    }
    
    /// Makes the textfield disappear
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

