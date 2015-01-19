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
        
        tableView.separatorColor = UIColor.colorWithHex("#cccccc")
        
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

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 28))
        // header.backgroundColor = UIColor.colorWithHex("#88ccFF")
        header.backgroundColor = UIColor.colorWithHex("#EEEEEE")
        
        
        if (section == 1) {
            let text = UILabel(frame: CGRectMake(18, -4, tableView.frame.size.width, 28))
            header.backgroundColor = UIColor.colorWithHex("#EEEEEE")
            text.font = UIFont.systemFontOfSize(14.0)
            text.textColor = UIColor.colorWithHex("#666666")
            text.text = String("Update Password").uppercaseString
            
            let border = CALayer();
            border.frame = CGRectMake(0, 22, tableView.frame.size.width, 0.5)
            border.backgroundColor = UIColor.colorWithHex("#CCCCCC")?.CGColor
        
            header.addSubview(text)
            header.layer.addSublayer(border)
            
            println("got header section: \(section)")
        }
        
        return header
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView(frame: CGRectMake(0, 0, tableView.frame.size.width, 40));
        footer.backgroundColor = UIColor.colorWithHex("#EEEEEE")
        if (section == 1) {
            let border = CALayer();
            border.frame = CGRectMake(0, 0, tableView.frame.size.width, 0.5)
            border.backgroundColor = UIColor.colorWithHex("#CCCCCC")?.CGColor
            
            footer.layer.addSublayer(border)
        }
        
        return footer
    }
}

