//
//  AVCaptureDeviceExtension.swift
//  GarageOpener
//
//  Created by Thomas Malt on 21/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation
import AVFoundation

extension AVCaptureDevice {
    
    /// Function to retrieve the first forward facing camera we find.
    /// 
    /// There is probably only one camera like that on a device, and
    /// if there are several the first found will be good engugh.
    class func deviceWithVideoInFront() -> AVCaptureDevice? {
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for device in devices! {
            if (device as AnyObject).position == AVCaptureDevicePosition.front {
                return device as? AVCaptureDevice
            }
        }
        
        // If we get this far we return nil
        return nil
    }
}
