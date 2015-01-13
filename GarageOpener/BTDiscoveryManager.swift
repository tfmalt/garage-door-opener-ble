//
//  BTDiscovery.swift
//  GarageOpener
//
//  Created by Thomas Malt on 10/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation
import CoreBluetooth

class BTDiscoveryManager: NSObject, CBCentralManagerDelegate {
    
    private let nc = NSNotificationCenter.defaultCenter()
    private let centralManager: CBCentralManager?
    
    let btConst = BTConstants()
    
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
        
        let queue = dispatch_queue_create("no.malt", DISPATCH_QUEUE_SERIAL)
        centralManager = CBCentralManager(delegate: self, queue: queue)
        
        NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("doReadRSSI"), userInfo: nil, repeats: true)
    }
    
    func sayHello() -> String {
        println("Testing output.");
        return "Hello from BTDiscovery.";
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
        nc.postNotificationName("btStateChangedNotification", object: "Scanning")
        
        if let central = self.centralManager {
            central.scanForPeripheralsWithServices([CBUUID(string: btConst.SERVICE_UUID)], options: nil)
        }
    }
    
    func resetConnection() {
        self.activeService = nil
        self.activePeripheral = nil
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
        
        nc.postNotificationName("btStateChangedNotification", object: "Disconnected", userInfo: ["peripheral": peripheral])
        
        if (peripheral == self.activePeripheral) {
            self.resetConnection()
            self.startScanning()
        }
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        
        let uuid = peripheral.identifier.UUIDString;
        
        println("Called did Discover Peripheral: \(uuid)")
        
        if ((self.activePeripheral != nil) && (self.activePeripheral?.state == CBPeripheralState.Connected)) {
            println("activePeripheral is alrady set and connected.")
            return
        }
        
        if (RSSI.integerValue == 127 || RSSI.integerValue < -85) {
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
        
        self.centralManager?.stopScan()
        self.resetConnection()
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
