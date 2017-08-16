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
    
    fileprivate let nc = NotificationCenter.default
    fileprivate var centralManager: CBCentralManager?
    
    let btConst = BTConstants()
    
    var rssiTimer   : Timer?
    var scanTimeout : Timer?
    
    let btQueue : DispatchQueue!
    
    var activePeripheral : CBPeripheral? {
        didSet {
            print("activePeripheral got set")
        }
    }
    var activeService : BTService? {
        didSet {
            print("activeService got set")
            if let service = self.activeService {
                service.startDiscoveringServices()
            }
        }
    }
    
    override init() {
        self.btQueue = DispatchQueue(label: "no.malt.btdiscovery", attributes: [])

        super.init()
        
        nc.addObserver(
            self,
            selector: #selector(BTDiscoveryManager.appDidEnterBackground),
            name: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil)
        
        nc.addObserver(
            self,
            selector: #selector(BTDiscoveryManager.appWillEnterForeground),
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil
        )

        centralManager = CBCentralManager(delegate: self, queue: self.btQueue)
        
        rssiTimer = Timer.scheduledTimer(
            timeInterval: 2.0,
            target: self,
            selector: #selector(BTDiscoveryManager.doReadRSSI),
            userInfo: nil,
            repeats: true
        )
    }
    
    func appDidEnterBackground() {
        print("Discovery Manager: did enter background")
        
        if (self.activePeripheral == nil) {
            print("  Got nil activePeripheral. Not connected.")
            return
        }
        
        if let state = self.activePeripheral?.state {
            if (state == CBPeripheralState.connected) {
                let p = self.activePeripheral
                self.resetConnection()
                self.centralManager?.cancelPeripheralConnection(p!)
            }
        }
        else {
            print("  Did not get state or state is not connected.")
        }
    }
    
    
    func appWillEnterForeground() {
        print("Discovery Manager: will enter foreground")
        
        if let central = self.centralManager {
            if central.state == .poweredOn {
                self.startScanning()
            }
            else {
                print("  App became active but Bluetooth not on.")
            }
        }
    }
    
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure
        )
    }
    
    /// Called to start scanning for devices.
    /// Also sets a timer to stop scanning after a given time.
    func startScanning() {
        if let central = self.centralManager {
            if central.state == .poweredOff {
                self.resetConnection()
                nc.post(
                    name: Notification.Name(rawValue: "btStateChangedNotification"),
                    object: "Bluetooth Off"
                )
                return
            }
            
            if central.state == .poweredOn {
                nc.post(
                    name: Notification.Name(rawValue: "btStateChangedNotification"),
                    object: "Scanning"
                )
        
                central.scanForPeripherals(
                    withServices: [CBUUID(string: btConst.SERVICE_UUID)],
                    options: nil
                )
            
                NSLog("BTDiscovery: setting timer to stop scan:")
                DispatchQueue.main.async(execute: {
                    self.scanTimeout = Timer.scheduledTimer(
                        timeInterval: 30.0,
                        target: self,
                        selector: #selector(BTDiscoveryManager.handleCheckAndStopScan),
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
        self.resetScanTimeout()
    }
    
    /// This function invalidates the timer which cancels the scanning after
    /// a given interval.
    func resetScanTimeout() {
        if let scan = self.scanTimeout {
            if scan.isValid == true {
                scan.invalidate()
            }
        }
    }
    
    /// handler for NSTimer to stop the scanner after a set interval.
    func handleCheckAndStopScan() {
        NSLog("BTDiscovery: Told to check and stop scan.")
        if let centr = self.centralManager {
            if centr.state != .poweredOn {
                self.resetConnection()
                return
            }
            
            centr.stopScan()
            nc.post(
                name: Notification.Name(rawValue: "BTDiscoveryScanningTimedOutNotification"),
                object: self,
                userInfo: nil
            )
        }
        
    }
    
    
    func doReadRSSI() {
        
        if self.activePeripheral == nil { return }
        if self.activePeripheral?.state != CBPeripheralState.connected { return }
        
        // print("got timer set right: and connected")
        
        self.activePeripheral?.readRSSI()
    }
    
    ////////////////////////////////////////////////////////////////////////
    //
    // Implementation of CBCentralManagerDelegate
    //
    
    func centralManager(_ central: CBCentralManager!, didConnect peripheral: CBPeripheral!) {
        print("Called didConnectPeripheral");
        
        if (peripheral == nil) {
            print("  peripheral argument was nil")
            return
        }
        
        let uuid = peripheral.identifier.uuidString;
        
        print("  debug: " + peripheral.debugDescription)
        print("  identifier: \(uuid)")
        print("  name:       \(peripheral.name)")
        
        if (peripheral == self.activePeripheral) {
            print("  Got identical peripheral as in discovery. creating BTService object.")
            self.activeService = BTService(initWithPeripheral: peripheral)
        }
        
        print("Stopping scan!")
        central.stopScan()
        self.resetScanTimeout()
        
    }
    
    
    /// called when thing disconnects.
    func centralManager(_ central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: Error!) {
        print("Called did Disconnect Peripheral: \(peripheral)")
        
        nc.post(
            name: Notification.Name(rawValue: "btStateChangedNotification"),
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
    
    
    func centralManager(_ central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [AnyHashable: Any]!, RSSI: NSNumber!) {
        
        let uuid = peripheral.identifier.uuidString;
        
        print("Called did Discover Peripheral: \(uuid)")
        
        if ((self.activePeripheral != nil) && (self.activePeripheral?.state == CBPeripheralState.connected)) {
            print("activePeripheral is alrady set and connected.")
            return
        }
        
        if (RSSI.intValue == 127 || RSSI.intValue < -95) {
            self.handleLowSignal(RSSI.intValue)
            return
        }
            
        self.activePeripheral = peripheral
            
        print("  Connecting!")
        nc.post(name: Notification.Name(rawValue: "btFoundDeviceNotification"), object: true,
            userInfo: ["peripheral": peripheral, "RSSI": RSSI])
        
        central.connect(peripheral, options: nil)
    }
    
    
    func handleLowSignal(_ signal: Int) {
        print("  Do not connect rssi: \(signal)")
        
        var msg = "Low Signal: \(signal)"
        nc.post(name: Notification.Name(rawValue: "btStateChangedNotification"), object: msg)
        if let central = self.centralManager {
            central.stopScan()
            self.resetConnection()
        }
        
        delay(1.0) {
            // Wait one second to start scanning again.
            self.startScanning()
        }
    }
    
    
    func centralManager(_ central: CBCentralManager!, didFailToConnect peripheral: CBPeripheral!, error: Error!) {
        print("Called didFailToConnectPeripheral")
    }
    
    func centralManager(_ central: CBCentralManager!, didRetrieveConnectedPeripherals peripherals: [AnyObject]!) {
        print("Called didRetrieveConnectedPeripherals")
    }
    
    func centralManager(_ central: CBCentralManager!, didRetrievePeripherals peripherals: [AnyObject]!) {
        print("called didRetrievePeripherals");
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager!) {
        var state : String?
        
        switch (central.state) {
        case .poweredOn:
            print("BLE state Powered On")
            state = nil
            self.startScanning()
            break
        case .unknown:
            print("BLE state unknown")
            state = "Unknown"
            break
        case .resetting:
            print("BLE state resetting")
            state = "Resetting"
            break
        case .unsupported:
            print("BLE state unsupported")
            state = "Unsupported Device"
            break
        case .unauthorized:
            print("BLE state unauthorized")
            state = "Unauthorized"
            break
        case .poweredOff:
            print("BLE state powered off")
            state = "Bluetooth Off"
            self.resetConnection()
            break
        default:
            break
        }
        
        if state == nil { return }
        
        nc.post(
            name: Notification.Name(rawValue: "btStateChangedNotification"),
            object: state
        )
    }
}
