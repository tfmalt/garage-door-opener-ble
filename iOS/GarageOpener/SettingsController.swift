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
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet var table: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        println("Loaded settings controller")
    }
    
    @IBAction func handleDone(sender: UIBarButtonItem) {
        println("handle done: \(passwordText.text)")
    }
    
}
