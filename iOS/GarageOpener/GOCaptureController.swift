//
//  GOCaptureController.swift
//  GarageOpener
//
//  Created by Thomas Malt on 24/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation

import AVFoundation

class GOCaptureController: NSObject {
    
    var captureSession : AVCaptureSession?
    var captureDevice  : AVCaptureDevice?
    var captureTimer   : NSTimer?
    var imageOutput    : AVCaptureStillImageOutput!
    var sessionQueue   : dispatch_queue_t!
    
    var config = NSUserDefaults.standardUserDefaults()
    let nc     = NSNotificationCenter.defaultCenter()
    
    
    override init() {
        super.init()
        
        if self.isCaptureDeviceAuthorized() == true {
            // do initialization
        }
        else {
            self.nc.postNotificationName("CameraAccessDenied", object: self)
        }
    }
        
    func isCaptureDeviceAuthorized() -> Bool {
        println("Checking authorization status:")
        var status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
            
        if (status == AVAuthorizationStatus.Authorized) {
            return true
        }
            
        return false
    }
}