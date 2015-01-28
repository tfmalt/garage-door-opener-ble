//
//  BTDiscovery.swift
//  GarageOpener
//
//  Created by Thomas Malt on 10/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

class BTDiscoveryManager: NSObject, CBCentralManagerDelegate {
    
    private let nc = NSNotificationCenter.defaultCenter()
    private let centralManager: CBCentralManager?
    
    let btConst = BTConstants()
    
    var rssiTimer   : NSTimer?
    var scanTimeout : NSTimer?
    
    let btQueue : dispatch_queue_t!
    
    var activePeripheral : CBPeripheral? {
        didSet {
            println("activePeripheral got set")
        }
    }
    var activeService : BTService? {
        didSet {
            println("activeService got set")
            if let service = self.activeService {
                service.startDiscoveringServices()
            }
        }
    }
    
    override init() {
        super.init()
        
        nc.addObserver(
            self,
            selector: Selector("appDidEnterBackground"),
            name: UIApplicationDidEnterBackgroundNotification,
            object: nil)
        
        nc.addObserver(
            self,
            selector: Selector("appWillEnterForeground"),
            name: UIApplicationWillEnterForegroundNotification,
            object: nil
        )
        
        self.btQueue = dispatch_queue_create("no.malt.btdiscovery", DISPATCH_QUEUE_SERIAL)
        centralManager = CBCentralManager(delegate: self, queue: self.btQueue)
        
        rssiTimer = NSTimer.scheduledTimerWithTimeInterval(
            2.0,
            target: self,
            selector: Selector("doReadRSSI"),
            userInfo: nil,
            repeats: true
        )
    }
    
    func appDidEnterBackground() {
        println("Discovery Manager: did enter background")
        
        if (self.activePeripheral == nil) {
            println("  Got nil activePeripheral. Not connected.")
            return
        }
        
        if let state = self.activePeripheral?.state {
            if (state == CBPeripheralState.Connected) {
                let p = self.activePeripheral
                self.resetConnection()
                self.centralManager?.cancelPeripheralConnection(p)
            }
        }
        else {
            println("  Did not get state or state is not connected.")
        }
    }
    
    
    func appWillEnterForeground() {
        println("Discovery Manager: will enter foreground")
        
        if let central = self.centralManager {
            if central.state == CBCentralManagerState.PoweredOn {
                self.startScanning()
            }
            else {
                println("  App became active but Bluetooth not on.")
            }
        }
    }
    
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure
        )
    }
    

    func startScanning() {
        if let central = self.centralManager {
            if central.state == CBCentralManagerState.PoweredOff {
                self.resetConnection()
                nc.postNotificationName(
                    "btStateChangedNotification",
                    object: "Bluetooth Off"
                )
                return
            }
            
            if central.state == CBCentralManagerState.PoweredOn {
                nc.postNotificationName(
                    "btStateChangedNotification",
                    object: "Scanning"
                )
        
                central.scanForPeripheralsWithServices(
                    [CBUUID(string: btConst.SERVICE_UUID)],
                    options: nil
                )
            
                NSLog("BTDiscovery: setting timer to stop scan:")
                dispatch_async(dispatch_get_main_queue(), {
                    self.scanTimeout = NSTimer.scheduledTimerWithTimeInterval(
                        30.0,
                        target: self,
                        selector: "handleCheckAndStopScan",
                        userInfo: nil,
                        repeats: false
                    )
                })
                
                return
            }
            
            NSLog("BTDiscovery: Got other state than expected: \(central.state)")
        }
    }
    
    func resetConnection() {
        self.activeService = nil
        self.activePeripheral = nil
        
        if let scan = self.scanTimeout {
            if scan.valid == true {
                scan.invalidate()
            }
        }
    }
    
    
    /// handler for NSTimer to stop the scanner after a set interval.
    func handleCheckAndStopScan() {
        NSLog("BTDiscovery: Told to check and stop scan.")
        if let centr = self.centralManager {
            if centr.state != CBCentralManagerState.PoweredOn {
                self.resetConnection()
                return
            }
            
            centr.stopScan()
            nc.postNotificationName(
                "BTDiscoveryScanningTimedOutNotification",
                object: self,
                userInfo: nil
            )
        }
        
    }
    
    
    func doReadRSSI() {
        
        if self.activePeripheral == nil { return }
        if self.activePeripheral?.state != CBPeripheralState.Connected { return }
        
        // println("got timer set right: and connected")
        
        self.activePeripheral?.readRSSI()
    }
    
    //
    // Implementation of CBCentralManagerDelegate
    //
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("Called didConnectPeripheral");
        
        if (peripheral == nil) {
            println("  peripheral argument was nil")
            return
        }
        
        let uuid = peripheral.identifier.UUIDString;
        
        println("  debug: " + peripheral.debugDescription)
        println("  identifier: \(uuid)")
        println("  name:       \(peripheral.name)")
        
        if (peripheral == self.activePeripheral) {
            println("  Got identical peripheral as in discovery. creating BTService object.")
            self.activeService = BTService(initWithPeripheral: peripheral)
        }
        
        println("Stopping scan!")
        central.stopScan()
    }
    
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("Called did Disconnect Peripheral: \(peripheral)")
        
        nc.postNotificationName(
            "btStateChangedNotification",
            object: "Disconnected",
            userInfo: ["peripheral": peripheral]
        )
        
        delay(2.0) {
            // wait two seconds before trying to connect again.
            // when activePeripheral is set to nil we know we don't need to reconnect.
            if (peripheral == self.activePeripheral) {
                self.resetConnection()
                self.startScanning()
            }
        }
    }
    
    
    func centralManager(
        central: CBCentralManager!,
        didDiscoverPeripheral peripheral: CBPeripheral!,
        advertisementData: [NSObject : AnyObject]!,
        RSSI: NSNumber!) {
        
        let uuid = peripheral.identifier.UUIDString;
        
        println("Called did Discover Peripheral: \(uuid)")
        
        if ((self.activePeripheral != nil) && (self.activePeripheral?.state == CBPeripheralState.Connected)) {
            println("activePeripheral is alrady set and connected.")
            return
        }
        
        if (RSSI.integerValue == 127 || RSSI.integerValue < -95) {
            self.handleLowSignal(RSSI.integerValue)
            return
        }
            
        self.activePeripheral = peripheral
            
        println("  Connecting!")
        nc.postNotificationName("btFoundDeviceNotification", object: true,
            userInfo: ["peripheral": peripheral, "RSSI": RSSI])
        
        central.connectPeripheral(peripheral, options: nil)
    }
    
    
    func handleLowSignal(signal: Int) {
        println("  Do not connect rssi: \(signal)")
        
        var msg = "Low Signal: \(signal)"
        nc.postNotificationName("btStateChangedNotification", object: msg)
        if let central = self.centralManager {
            central.stopScan()
            self.resetConnection()
        }
        
        delay(1.0) {
            // Wait one second to start scanning again.
            self.startScanning()
        }
    }
    
    
    func centralManager(central: CBCentralManager!, didFailToConnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("Called didFailToConnectPeripheral")
    }
    
    func centralManager(central: CBCentralManager!, didRetrieveConnectedPeripherals peripherals: [AnyObject]!) {
        println("Called didRetrieveConnectedPeripherals")
    }
    
    func centralManager(central: CBCentralManager!, didRetrievePeripherals peripherals: [AnyObject]!) {
        println("called didRetrievePeripherals");
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        var state : String?
        
        switch (central.state) {
        case CBCentralManagerState.PoweredOn:
            println("BLE state Powered On")
            state = nil
            self.startScanning()
            break
        case CBCentralManagerState.Unknown:
            println("BLE state unknown")
            state = "Unknown"
            break
        case CBCentralManagerState.Resetting:
            println("BLE state resetting")
            state = "Resetting"
            break
        case CBCentralManagerState.Unsupported:
            println("BLE state unsupported")
            state = "Unsupported Device"
            break
        case CBCentralManagerState.Unauthorized:
            println("BLE state unauthorized")
            state = "Unauthorized"
            break
        case CBCentralManagerState.PoweredOff:
            println("BLE state powered off")
            state = "Bluetooth Off"
            self.resetConnection()
            break
        default:
            break
        }
        
        if state == nil { return }
        
        nc.postNotificationName(
            "btStateChangedNotification",
            object: state
        )
    }
}
