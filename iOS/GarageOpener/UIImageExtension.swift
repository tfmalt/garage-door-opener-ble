//
//  UIImageExtension.swift
//  GarageOpener
//
//  Created by Thomas Malt on 13/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    /// A function pulled of StackOverflow to create an empty image from 
    /// a hex rgb code
    class func imageWithColor(color:UIColor?) -> UIImage! {
        
        let rect = CGRectMake(0.0, 0.0, 1.0, 1.0);
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        
        let context = UIGraphicsGetCurrentContext();
        
        if let color = color {
            
            color.setFill()
        }
        else {
            
            UIColor.whiteColor().setFill()
        }
        
        CGContextFillRect(context, rect);
        
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;
    }
    
    /// Returns the uicolor for a given pixel
    ///
    /// :return: UIColor
    func getPixelColor(pos: CGPoint!) -> UIColor {
        let pixelData : CFDataRef = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let data      : UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo : Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        let depth     : CGFloat = CGFloat(255.0)
        
        var r = CGFloat(data[pixelInfo + 0]) / depth
        var g = CGFloat(data[pixelInfo + 1]) / depth
        var b = CGFloat(data[pixelInfo + 2]) / depth
        var a = CGFloat(data[pixelInfo + 3]) / depth
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    /// Get the RGB values as CGFloat for a given pixel. Discards Alpha
    ///
    /// :param: pos CGPoint
    /// :return: Array [CGFloat]
    func getPixelRGB(pos: CGPoint) -> [CGFloat] {
        let pixelData : CFDataRef = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let data      : UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo : Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        let depth     : CGFloat = CGFloat(255.0)
        
        return [
            (CGFloat(data[pixelInfo + 0]) / depth),
            (CGFloat(data[pixelInfo + 1]) / depth),
            (CGFloat(data[pixelInfo + 2]) / depth)
        ]
    }
    
    /// Calculates the average luminance of the whole image
    ///
    /// :return: CGFloat
    func luminance() -> CGFloat {
        let pixelData : CFDataRef = CGDataProviderCopyData(CGImageGetDataProvider(self.CGImage))
        let data      : UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        var total     : CGFloat   = 0.0
        let width     : Int       = Int(self.size.width)
        let height    : Int       = Int(self.size.height)
        
        for var i = 0; i < width; i++ {
            for var j = 0; j < height; j++ {
                
                let pixelInfo : Int = (((width * j) + i) * 4)
                let depth     : CGFloat = CGFloat(255.0)
                
                var r = CGFloat(data[pixelInfo + 0]) / depth
                var g = CGFloat(data[pixelInfo + 1]) / depth
                var b = CGFloat(data[pixelInfo + 2]) / depth
                
                total += (r * CGFloat(0.299))
                total += (g * CGFloat(0.587))
                total += (b * CGFloat(0.114))
            }
        }
        
        var luminance = (total / (self.size.width*self.size.height))
        
        return luminance
    }
}