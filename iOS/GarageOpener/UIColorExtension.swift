//
//  UIColorExtension.swift
//  GarageOpener
//
//  Created by Thomas Malt on 13/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    class func colorWithHex(_ hexString: String?) -> UIColor? {
        
        return colorWithHex(hexString, alpha: 1.0)
    }
    
    class func colorWithHex(_ hexString: String?, alpha: CGFloat) -> UIColor? {
        
        if let hexString = hexString {
            
            var error : NSError? = nil
            
//            let regexp = NSRegularExpression(pattern: "\\A#[0-9a-f]{6}\\z",
//                options: .CaseInsensitive,
//                error: &error)
//            
//            let count = regexp?.numberOfMatchesInString(hexString,
//                options: .ReportProgress,
//                range: NSMakeRange(0, hexString.count))
//            
//            if count != 1 {
//                
//                return nil
//            }
            
            var rgbValue : UInt32 = 0
            
            let scanner = Scanner(string: hexString)
            
            scanner.scanLocation = 1
            scanner.scanHexInt32(&rgbValue)
            
            let red   = CGFloat( (rgbValue & 0xFF0000) >> 16) / 255.0
            let green = CGFloat( (rgbValue & 0xFF00) >> 8) / 255.0
            let blue  = CGFloat( (rgbValue & 0xFF) ) / 255.0
            
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        
        return nil
    }
}
