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
    
    var config = UserDefaults.standard
    var nc     = NotificationCenter.default
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nc.addObserver(
            self,
            selector: #selector(GOSettingsController.handleCaptureDeviceNotAuthorized(_:)),
            name: Notification.Name(rawValue: "GOCaptureDeviceNotAuthorizedNotification"),
            object: nil
        )
        
        self.passwordField.delegate = self
        
        tableView.separatorColor = UIColor.colorWithHex("#cccccc")
        self.configureSettings()
        
        print("Loaded settings controller")
    }
    
    /// Setting up the switches to default
    func configureSettings() {
        if let show = config.value(forKey: "showPassword") as? Bool {
            showPasswordSwitch.isOn = show
        }
        
        if let pass = config.value(forKey: "password") as? String {
            passwordField.text = pass
        }
        
        if let darkOn = config.value(forKey: "useDarkTheme") as? Bool {
            darkThemeSwitch.isOn = darkOn
        }
        
        if let autoOn = config.value(forKey: "useAutoTheme") as? Bool {
            themeAutoSwitch.isOn = autoOn
        }
        
        passwordField.isSecureTextEntry = !showPasswordSwitch.isOn
    }
    
    
    @IBAction func handleDarkThemeChange(_ sender: UISwitch) {
        config.set(sender.isOn, forKey: "useDarkTheme")
    }
    
    @IBAction func handleAutoThemeChange(_ sender: UISwitch) {
        config.set(sender.isOn, forKey: "useAutoTheme")
        
        if sender.isOn == true {
            nc.post(
                name: Notification.Name(rawValue: "GOSettingsRequestCameraAccessNotification"),
                object: config
            )
        }
    }
    

    @IBAction func handleShowPasswordChange(_ sender: UISwitch) {
        passwordField.isSecureTextEntry = !sender.isOn
        config.set(sender.isOn, forKey: "showPassword")
    }
    
    /// Store password and notify main view when done is pressed
    @IBAction func handleDonePressed(_ sender: AnyObject) {
        config.set(passwordField.text, forKey: "password")
        
        self.passwordField.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
        
        nc.post(name: Notification.Name(rawValue: "SettingsUpdatedNotification"), object: config)
    }
    
    
    /// Post notification to main view when cancel is pressed
    @IBAction func handleCancelPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
        self.passwordField.resignFirstResponder()
        
        nc.post(name: Notification.Name(rawValue: "SettingsCancelledNotification"), object: config)
    }
    
    
    func handleCaptureDeviceNotAuthorized(_ notification: Notification) {
        let captureCtrl = notification.object as! GOCaptureController
        
        print("Settings: Got notification capture not authorized")
        if (self.isViewLoaded && (self.view.window != nil)) {
            let alert = captureCtrl.getCameraNotAuthorizedAlert()
            self.present(alert, animated: true, completion: nil)
        }
        
        DispatchQueue.main.async(execute: {
            print("  - Setting auto theme = false")
            self.config.set(false, forKey: "useAutoTheme")
            self.themeAutoSwitch.isOn = false
        })
        
    }
    
    /// Iterating over the sections in the table view to update the 
    /// appearance by changing font and case to make it look more like the
    /// standard settings view in the settings app
    ///
    /// :return: UIView
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 28))

        header.backgroundColor = UIColor.colorWithHex("#EEEEEE")
        
        if (section == 1) {
            
            let text   : UILabel = self.getLabel()
            let border : CALayer = self.getBottomBorder()
            
            text.text = String("authentication").uppercased()
            
            header.addSubview(text)
            header.layer.addSublayer(border)
        }
        
        if (section == 2) {
            let text   : UILabel = self.getLabel()
            let border : CALayer = self.getBottomBorder()
            
            text.text = String("Theme").uppercased()
            
            header.addSubview(text)
            header.layer.addSublayer(border)
        }
        
        return header
    }
    
    
    /// Iterates over the tableview sections and updates all the footers
    /// to look nice
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40));
        footer.backgroundColor = UIColor.colorWithHex("#EEEEEE")
        
        if (section == 1 || section == 2) {
            let border = CALayer();
            border.frame = CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 0.5)
            border.backgroundColor = UIColor.colorWithHex("#CCCCCC")?.cgColor
            
            footer.layer.addSublayer(border)
        }
        
        return footer
    }
    
    
    /// Helper function to draw a bottom border on the top header for 
    /// beautiful effect
    func getBottomBorder() -> CALayer {
        let border = CALayer();
        
        border.frame = CGRect(x: 0, y: 22, width: tableView.frame.size.width, height: 0.5)
        border.backgroundColor = UIColor.colorWithHex("#CCCCCC")?.cgColor
        
        return border
    }
    
    
    /// Helper function to draw the tableview cells the way I want.
    func getLabel() -> UILabel {
        let text = UILabel(
            frame: CGRect(x: 18, y: -4 ,
            width: tableView.frame.size.width, height: 28)
        )
        
        text.font = UIFont.systemFont(ofSize: 14.0)
        text.textColor = UIColor.colorWithHex("#666666")
        
        return text
    }
    
    /// Makes the textfield disappear
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

