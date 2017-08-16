//
//  GOCaptureController.swift
//  GarageOpener
//
//  Created by Thomas Malt on 24/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class GOCaptureController: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var captureSession : AVCaptureSession?
    var captureDevice  : AVCaptureDevice?
    var captureTimer   : Timer?
    var videoOutput    : AVCaptureVideoDataOutput!
    var sessionQueue   : DispatchQueue!
    
    var cameraImage    : UIImage?
    
    var isAuthorized           : Bool?
    var isSessionConfigured    : Bool = false
    
    let nc = NotificationCenter.default
    
    /// Constructor
    override init() {
        super.init()
        
        self.sessionQueue = DispatchQueue(
            label: "no.malt.GOCaptureController",
            attributes: []
        )

        self.registerObservers()
    }
    
    
    /// Registering all the notifications observers we have use for
    /// in one place
    fileprivate func registerObservers() {
        nc.addObserver(
            self,
            selector: #selector(GOCaptureController.handleSettingsUpdated(_:)),
            name: Notification.Name(rawValue: "SettingsUpdatedNotification"),
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOCaptureController.appWillTerminate(_:)),
            name: Notification.Name.UIApplicationWillTerminate,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: #selector(GOCaptureController.handleSettingsRequestCameraAccess(_:)),
            name: Notification.Name(rawValue: "GOSettingsRequestCameraAccessNotification"),
            object: nil
        )
    }
    
    
    ///////////////////////////////////////////////////////////////////////
    // 
    //  handlers to handle initial reqeuest for camera access
    //
    
    func handleSettingsRequestCameraAccess(_ notification: Notification) {
        let config = notification.object as! UserDefaults
        
        self.requestCameraAccess(config)
        
    }
    
    func requestCameraAccess(_ config: UserDefaults) {
        AVCaptureDevice.requestAccess(
            forMediaType: AVMediaTypeVideo,
            completionHandler: { (access: Bool) -> Void in
                if access == true {
                    self.nc.post(
                        name: Notification.Name(rawValue: "GOCaptureDeviceAuthorizedNotification"),
                        object: self
                    )
                } else {
                    self.nc.post(
                        name: Notification.Name(rawValue: "GOCaptureDeviceNotAuthorizedNotification"),
                        object: self
                    )
                }
            }
        )
    }
    
    ///////////////////////////////////////////////////////////////////////
    // 
    // Functions related to Initializing the capture session 
    //
    
    /// Running the initial setup of a new capture session
    func initializeCaptureSession() {
        
        let isauth = self.isCaptureDeviceAuthorized()
        
        if isauth == true {
            print("  GOCaptureCtrl: Camera is authorized - initializing")

            self.setupCaptureSession()
            self.beginCaptureSession()
            self.setupImageCaptureTimer()
            
            self.isSessionConfigured = true
        } else if (isauth == false) {
            self.isSessionConfigured = false
            nc.post(name: Notification.Name(rawValue: "GOCaptureDeviceNotAuthorizedNotification"), object: self)
        } else {
            nc.post(
                name: Notification.Name(rawValue: "GOCaptureDeviceAuthorizationNotDetermined"),
                object: self
            )
           
            print("GOCaptureCtrl: Authorization not yet decided.")
        }
    }

    
    // beginning the capture session.
    fileprivate func setupCaptureSession() {
        self.captureSession             = AVCaptureSession()
        self.captureDevice              = AVCaptureDevice.deviceWithVideoInFront()
        self.videoOutput                = AVCaptureVideoDataOutput()
        
        self.setCaptureSessionPreset(AVCaptureSessionPreset352x288 as NSString)
        self.addCaptureSessionInputDevice()
        self.addCaptureSessionOutputDevice()
        
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
        self.videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as AnyHashable: NSNumber(value: Int(kCVPixelFormatType_32BGRA))
        ]
    }
    
    /// Implementation of the capture output delegate function
    /// implements the sample buffer event handler and converts the buffer
    /// into an UIImage for processing.
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        let imageBuffer : CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width       = CVPixelBufferGetWidth(imageBuffer)
        let height      = CVPixelBufferGetHeight(imageBuffer)
        let colorSpace  = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo  = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let context     = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
        let newImage    = context?.makeImage()
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        
//        self.cameraImage = UIImage(CGImage: newImage!)
    }
    
    
    fileprivate func setCaptureSessionPreset(_ preset: NSString!) {
        self.sessionQueue.async(execute: {
            print("Set capture session preset:")
            if let session = self.captureSession {
                if session.canSetSessionPreset(preset as String!) {
                    session.sessionPreset = preset as String!
                    print("  Set capture preset to: \(preset)")
                } else {
                    print("  Could not set preset: \(preset) -> implement fallback")
                }
            }
        })
    }

    
    fileprivate func addCaptureSessionInputDevice() {
        self.sessionQueue.async(execute: {
            print("Adding input device:")
//            if let session = self.captureSession {
//                if let camera = self.captureDevice {
//                    var input  = AVCaptureDeviceInput(device: camera, error: nil)
//                    
//                    if session.canAddInput(input) {
//                        session.addInput(AVCaptureDeviceInput(device: camera, error: nil))
//                        print("  Added front camera as input")
//                    } else {
//                        print("  Could not add front camera as input")
//                    }
//                    
//                    print("  active format: \(camera.activeFormat.description)")
//                }
//            }
        })
    }
    
    
    fileprivate func addCaptureSessionOutputDevice() {
        self.sessionQueue.async(execute: {
            print("Adding output device:")
            if let session = self.captureSession {
                if session.canAddOutput(self.videoOutput) {
                    session.addOutput(self.videoOutput)
                    print("  Added output object as output")
                } else {
                    print("  Could not add output object -> figure out why")
                }
            }
        })
    }
    
    
    /// Configuring the actual camera settings for the capture device.
    fileprivate func configureCaptureDevice() {
        
        let ISO            = 800.0
        let exposureLength = (10.0/1000.0)
        
        // Paranoid about the precense of a forward facing camera
        if let camera : AVCaptureDevice = self.captureDevice {
            do {
                try camera.lockForConfiguration()
            } catch {}

            print("Locking device configuration")
            
            self.setCaptureDeviceFrameRate(camera)
            
            // Set exposure
            if camera.isExposureModeSupported(AVCaptureExposureMode.custom) {
                print("  Setting exposure mode")
                camera.exposureMode = AVCaptureExposureMode.custom
                camera.setExposureModeCustomWithDuration(
                    CMTimeMakeWithSeconds(exposureLength, 1000*1000*1000),
                    iso: Float(ISO),
                    completionHandler: { (time) -> Void in
                        print("  - Set custom exposure done.")
                        self.getLuminance()
                    }
                )
            } else {
                print("  Camera not supporting custom exposure mode.")
            }
            
            camera.unlockForConfiguration()
            print("Unlocked device configuration")
            
        }
    }
    
    /// configures the minimal framerate possible to evaluate data.
    fileprivate func setCaptureDeviceFrameRate(_ camera: AVCaptureDevice!) {
        let fpsRange = camera.activeFormat.videoSupportedFrameRateRanges
        
        print("Frame rate range: \(String(describing: fpsRange))")
        print("  Count: \(String(describing: fpsRange?.count))")
        
        if let range = fpsRange?.first as? AVFrameRateRange {
            print("  range: \(range)")
            print("    \(CMTimeGetSeconds(range.minFrameDuration))")
            print("    \(CMTimeGetSeconds(range.maxFrameDuration))")
            
            // set framerate
            camera.activeVideoMinFrameDuration = range.maxFrameDuration
            camera.activeVideoMaxFrameDuration = range.maxFrameDuration
        } else {
            print("Frame rate range not returned - an error")
        }
    }
    
    
    func getLuminance() {
        self.sessionQueue.async(execute: {
            let image     = self.cameraImage! as UIImage
            let luminance = Float(image.luminance())
            
            self.nc.post(
                name: Notification.Name(rawValue: "GOCaptureCalculatedLightLevelNotification"),
                object: image,
                userInfo: ["luminance": luminance]
            )
        })
    }



    fileprivate func beginCaptureSession() {
        self.sessionQueue.async(execute: {
            if let session = self.captureSession {
                session.startRunning()
                self.configureCaptureDevice()
            }
        })
    }


    func endCaptureSession() {
        self.sessionQueue.async(execute: {
            if let session = self.captureSession {
                if session.isRunning == true {
                    print("GOCaptureCtrl: Stopping capture session")
                    session.stopRunning()
                }
            }
            
            self.captureSession      = nil
            self.videoOutput         = nil
            self.captureDevice       = nil
            self.isSessionConfigured = false
        })
    }
    
    
    ///////////////////////////////////////////////////////////////////////
    //
    // Setting up and tearing down the capture timer
    //
    func setupImageCaptureTimer() {
        print("Told to setup new image capture timer:")
        if (self.captureTimer == nil || self.captureTimer?.isValid == false) {
            print("  Starting new capture NSTimer 4.0s")
            self.captureTimer = Timer.scheduledTimer(
                timeInterval: 2.0,
                target: self,
                selector: #selector(GOCaptureController.getLuminance),
                userInfo: nil,
                repeats: true
            )
        }
    }
    
    
    func removeImageCaptureTimer() {
        print("Told to remove image capture timer.")
        if let timer : Timer = self.captureTimer {
            if timer.isValid == true {
                print("  Found running timer - invalidating")
                timer.invalidate()
            }
        } else {
            print("  No timer found - aborting.")
        }
        
        self.captureTimer = nil
    }

    
    ///////////////////////////////////////////////////////////////////////
    
    
    func isCaptureDeviceAuthorized() -> Bool? {
        print("GOCaptureCtrl: Checking authorization status:")
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        
        if (status == AVAuthorizationStatus.authorized) {
            self.isAuthorized = true
        } else if (status == AVAuthorizationStatus.notDetermined) {
            self.isAuthorized = nil
        } else {
            self.isAuthorized = false
        }
        
        return self.isAuthorized
    }
    
    
    func getCameraNotAuthorizedAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: "Theme Switching Disabled",
            message: "Camera access for this app has been turned off in settings. " +
                "Because of this theme switching is disabled.\n\n" +
                "To be able to switch themes automatically the camera is needed to " +
                "measure light levels.\n\n" +
                "If you wish to use this feature, please go to the " +
                "iOS Settings for Garage Opener and " +
                "enable access to the camera.",
            preferredStyle: UIAlertControllerStyle.alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: UIAlertActionStyle.default,
                handler: nil
            )
        )
        
        return alert
    }
    
    
    func handleSettingsUpdated(_ notification: Notification) {
        print("GOCaptureController: Told settings have updated")
        let config = notification.object as! UserDefaults
        
        if config.bool(forKey: "useAutoTheme") == false {
            print("  GOCaptureController: auto theme = false, disabling.")
            self.removeImageCaptureTimer()
            self.endCaptureSession()
            
            return
        }
        
        if self.isSessionConfigured == true {
            print("  GOCaptureController: auto theme == true, but session already running")
            return
        }
        
        print("  GOCaptureController: initializing session")
        self.initializeCaptureSession()
    }


    func appWillTerminate(_ notification: Notification) {
        print("GOCaptureCtrl: Told app will terminate")
        self.removeImageCaptureTimer()
        self.endCaptureSession()
    }
    
}
