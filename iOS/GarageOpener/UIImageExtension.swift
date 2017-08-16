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
    class func imageWithColor(_ color:UIColor?) -> UIImage! {
        
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0);
        
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        
        let context = UIGraphicsGetCurrentContext();
        
        if let color = color {
            
            color.setFill()
        }
        else {
            
            UIColor.white.setFill()
        }
        
        context?.fill(rect);
        
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;
    }
    
    /// Returns the uicolor for a given pixel
    ///
    /// :return: UIColor
    func getPixelColor(_ pos: CGPoint!) -> UIColor {
        let pixelData : CFData = (self.cgImage)!.dataProvider!.data!
        let data      : UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        let pixelInfo : Int = ((Int(self.size.width) * Int(pos.y)) + Int(pos.x)) * 4
        let depth     : CGFloat = CGFloat(255.0)
        
        let r = CGFloat(data[pixelInfo + 0]) / depth
        let g = CGFloat(data[pixelInfo + 1]) / depth
        let b = CGFloat(data[pixelInfo + 2]) / depth
        let a = CGFloat(data[pixelInfo + 3]) / depth
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
    
    /// Get the RGB values as CGFloat for a given pixel. Discards Alpha
    ///
    /// :param: pos CGPoint
    /// :return: Array [CGFloat]
    func getPixelRGB(_ pos: CGPoint) -> [CGFloat] {
        let pixelData : CFData = (self.cgImage)!.dataProvider!.data!
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
        let pixelData : CFData = (self.cgImage)!.dataProvider!.data!
        let data      : UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        var total     : CGFloat   = 0.0
        let width     : Int       = Int(self.size.width)
        let height    : Int       = Int(self.size.height)
        
        for i in 0 ..< width {
            for j in 0 ..< height {
                
                let pixelInfo : Int = (((width * j) + i) * 4)
                let depth     : CGFloat = CGFloat(255.0)
                
                let r = CGFloat(data[pixelInfo + 0]) / depth
                let g = CGFloat(data[pixelInfo + 1]) / depth
                let b = CGFloat(data[pixelInfo + 2]) / depth
                
                total += (r * CGFloat(0.299))
                total += (g * CGFloat(0.587))
                total += (b * CGFloat(0.114))
            }
        }
        
        let luminance = (total / (self.size.width*self.size.height))
        
        return luminance
    }
}
