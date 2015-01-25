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
    var captureTimer   : NSTimer?
    var videoOutput    : AVCaptureVideoDataOutput!
    var sessionQueue   : dispatch_queue_t!
    
    var cameraImage    : UIImage?
    
    var isAuthorized           : Bool?
    var isSessionConfigured    : Bool = false
    
    let nc = NSNotificationCenter.defaultCenter()
    
    /// Constructor
    override init() {
        super.init()
        
        self.sessionQueue = dispatch_queue_create(
            "no.malt.GOCaptureController",
            DISPATCH_QUEUE_SERIAL
        )

        self.registerObservers()
    }
    
    
    /// Registering all the notifications observers we have use for
    /// in one place
    private func registerObservers() {
        nc.addObserver(
            self,
            selector: "handleSettingsUpdated:",
            name: "SettingsUpdatedNotification",
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: "appWillTerminate:",
            name: UIApplicationWillTerminateNotification,
            object: nil
        )
        
        nc.addObserver(
            self,
            selector: "handleSettingsRequestCameraAccess:",
            name: "GOSettingsRequestCameraAccessNotification",
            object: nil
        )
    }
    
    
    ///////////////////////////////////////////////////////////////////////
    // 
    //  handlers to handle initial reqeuest for camera access
    //
    
    func handleSettingsRequestCameraAccess(notification: NSNotification) {
        var config = notification.object as NSUserDefaults
        
        self.requestCameraAccess(config)
        
    }
    
    func requestCameraAccess(config: NSUserDefaults) {
        AVCaptureDevice.requestAccessForMediaType(
            AVMediaTypeVideo,
            completionHandler: { (access: Bool) -> Void in
                if access == true {
                    self.nc.postNotificationName(
                        "GOCaptureDeviceAuthorizedNotification",
                        object: self
                    )
                } else {
                    self.nc.postNotificationName(
                        "GOCaptureDeviceNotAuthorizedNotification",
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
        
        var isauth = self.isCaptureDeviceAuthorized()
        
        if isauth == true {
            println("  GOCaptureCtrl: Camera is authorized - initializing")

            self.setupCaptureSession()
            self.beginCaptureSession()
            self.setupImageCaptureTimer()
            
            self.isSessionConfigured = true
        } else if (isauth == false) {
            self.isSessionConfigured = false
            nc.postNotificationName("GOCaptureDeviceNotAuthorizedNotification", object: self)
        } else {
            nc.postNotificationName(
                "GOCaptureDeviceAuthorizationNotDetermined",
                object: self
            )
           
            println("GOCaptureCtrl: Authorization not yet decided.")
        }
    }

    
    // beginning the capture session.
    private func setupCaptureSession() {
        self.captureSession             = AVCaptureSession()
        self.captureDevice              = AVCaptureDevice.deviceWithVideoInFront()
        self.videoOutput                = AVCaptureVideoDataOutput()
        
        self.setCaptureSessionPreset(AVCaptureSessionPreset352x288)
        self.addCaptureSessionInputDevice()
        self.addCaptureSessionOutputDevice()
        
        self.videoOutput.alwaysDiscardsLateVideoFrames = true
        self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
        self.videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey: NSNumber(integer: kCVPixelFormatType_32BGRA)
        ]
    }
    
    /// Implementation of the capture output delegate function
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        
        var imageBuffer : CVImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        CVPixelBufferLockBaseAddress(imageBuffer, 0)
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width       = CVPixelBufferGetWidth(imageBuffer)
        let height      = CVPixelBufferGetHeight(imageBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(CGImageAlphaInfo.PremultipliedLast.rawValue)
        let context    = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, bitmapInfo)
        let newImage   = CGBitmapContextCreateImage(context)
        
        self.cameraImage = UIImage(CGImage: newImage)
        
        // NSLog("captureOutput: sample buffer: \(bytesPerRow) w:\(width), h: \(height)")
    }
    
    
    private func setCaptureSessionPreset(preset: NSString!) {
        dispatch_async(self.sessionQueue, {
            println("Set capture session preset:")
            if let session = self.captureSession {
                if session.canSetSessionPreset(preset) {
                    session.sessionPreset = preset
                    println("  Set capture preset to: \(preset)")
                } else {
                    println("  Could not set preset: \(preset) -> implement fallback")
                }
            }
        })
    }

    
    private func addCaptureSessionInputDevice() {
        dispatch_async(self.sessionQueue, {
            println("Adding input device:")
            if let session = self.captureSession {
                if let camera = self.captureDevice {
                    var input  = AVCaptureDeviceInput(device: camera, error: nil)
                    
                    if session.canAddInput(input) {
                        session.addInput(AVCaptureDeviceInput(device: camera, error: nil))
                        println("  Added front camera as input")
                    } else {
                        println("  Could not add front camera as input")
                    }
                    
                    println("  active format: \(camera.activeFormat.description)")
                }
            }
        })
    }
    
    
    private func addCaptureSessionOutputDevice() {
        dispatch_async(self.sessionQueue, {
            println("Adding output device:")
            if let session = self.captureSession {
                if session.canAddOutput(self.videoOutput) {
                    session.addOutput(self.videoOutput)
                    println("  Added output object as output")
                } else {
                    println("  Could not add output object -> figure out why")
                }
            }
        })
    }
    
    
    /// Configuring the actual camera settings for the capture device.
    private func configureCaptureDevice() {
        
        let ISO            = 800.0
        let exposureLength = (10.0/1000.0)
        
        // Paranoid about the precense of a forward facing camera
        if let camera : AVCaptureDevice = self.captureDevice {
            camera.lockForConfiguration(nil)
            println("Locking device configuration")
            
            // set framerate
            camera.activeVideoMinFrameDuration = CMTimeMake(1, 1)
            camera.activeVideoMaxFrameDuration = CMTimeMake(1, 1)
            
            // Set exposure
            if camera.isExposureModeSupported(AVCaptureExposureMode.Custom) {
                println("  Setting exposure mode")
                camera.exposureMode = AVCaptureExposureMode.Custom
                camera.setExposureModeCustomWithDuration(
                    CMTimeMakeWithSeconds(exposureLength, 1000*1000*1000),
                    ISO: Float(ISO),
                    completionHandler: { (time) -> Void in
                        println("  - Set custom exposure done.")
                        self.getLuminance()
                    }
                )
            } else {
                println("  Camera not supporting custom exposure mode.")
            }
            
            camera.unlockForConfiguration()
            println("Unlocked device configuration")
            
        }
    }


    private func beginCaptureSession() {
        dispatch_async(self.sessionQueue, {
            if let session = self.captureSession {
                session.startRunning()
                self.configureCaptureDevice()
            }
        })
    }


    func endCaptureSession() {
        dispatch_async(self.sessionQueue, {
            if let session = self.captureSession {
                if session.running == true {
                    println("GOCaptureCtrl: Stopping capture session")
                    session.stopRunning()
                }
            }
            
            self.captureSession = nil
            self.videoOutput    = nil
            self.captureDevice  = nil
            
            self.isSessionConfigured = false
        })
    }
    
    
    ///////////////////////////////////////////////////////////////////////
    //
    // Setting up and tearing down the capture timer
    //
    func setupImageCaptureTimer() {
        println("Told to setup new image capture timer:")
        if (self.captureTimer == nil || self.captureTimer?.valid == false) {
            println("  Starting new capture NSTimer 4.0s")
            self.captureTimer = NSTimer.scheduledTimerWithTimeInterval(
                2.0,
                target: self,
                selector: "getLuminance",
                userInfo: nil,
                repeats: true
            )
        }
    }
    
    
    func removeImageCaptureTimer() {
        println("Told to remove image capture timer.")
        if let timer : NSTimer = self.captureTimer {
            if timer.valid == true {
                println("  Found running timer - invalidating")
                timer.invalidate()
            }
        } else {
            println("  No timer found - aborting.")
        }
        
        self.captureTimer = nil
    }

    
    ///////////////////////////////////////////////////////////////////////
    func getLuminance() {
        dispatch_async(self.sessionQueue, {
            var image     = self.cameraImage! as UIImage
            var lumRaw    = image.luminance()
            var luminance = Float(lumRaw)
            
            if let camera = self.captureDevice {
                var time      = Int(round(CMTimeGetSeconds(camera.exposureDuration) * 1000))
                var iso       = Int(camera.ISO)
                
                self.nc.postNotificationName(
                    "CaptureImageNotification",
                    object: image,
                    userInfo: [
                        "luminance"        : luminance,
                        "exposureTimeMsec" : time,
                        "isoValue"         : iso
                    ]
                )
            } else {
                println("GOCaptureCtrl: Could not get camera after capture - error")
            }
        })
    }

    
    func isCaptureDeviceAuthorized() -> Bool? {
        println("GOCaptureCtrl: Checking authorization status:")
        var status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        
        if (status == AVAuthorizationStatus.Authorized) {
            self.isAuthorized = true
        } else if (status == AVAuthorizationStatus.NotDetermined) {
            self.isAuthorized = nil
        } else {
            self.isAuthorized = false
        }
        
        return self.isAuthorized
    }
    
    
    func getCameraNotAuthorizedAlert() -> UIAlertController {
        var alert = UIAlertController(
            title: "Theme Switching Disabled",
            message: "Camera access for this app has been turned off in settings. " +
                "Because of this theme switching is disabled.\n\n" +
                "To be able to switch themes automatically the camera is needed to " +
                "measure light levels.\n\n" +
                "If you wish to use this feature, please go to the " +
                "iOS Settings for Garage Opener and " +
                "enable access to the camera.",
            preferredStyle: UIAlertControllerStyle.Alert
        )
        
        alert.addAction(
            UIAlertAction(
                title: "OK",
                style: UIAlertActionStyle.Default,
                handler: nil
            )
        )
        
        return alert
    }
    
    
    func handleSettingsUpdated(notification: NSNotification) {
        println("GOCaptureController: Told settings have updated")
        let config = notification.object as NSUserDefaults
        
        if config.boolForKey("useAutoTheme") == false {
            println("  GOCaptureController: auto theme = false, disabling.")
            self.removeImageCaptureTimer()
            self.endCaptureSession()
            
            return
        }
        
        if self.isSessionConfigured == true {
            println("  GOCaptureController: auto theme == true, but session already running")
            return
        }
        
        println("  GOCaptureController: initializing session")
        self.initializeCaptureSession()
    }


    func appWillTerminate(notification: NSNotification) {
        println("GOCaptureCtrl: Told app will terminate")
        self.removeImageCaptureTimer()
        self.endCaptureSession()
    }
    
}