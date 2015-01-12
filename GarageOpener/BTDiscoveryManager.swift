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
    }
    
    func sayHello() -> String {
        println("Testing output.");
        return "Hello from BTDiscovery.";
    }
    
    
    func startScanning() {
        if let central = self.centralManager {
            central.scanForPeripheralsWithServices(nil, options: nil)
        }
    }
    
    func resetConnection() {
        self.activeService = nil
        self.activePeripheral = nil
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
        
        if (uuid == btConst.IDENTIFIER_UUID) {
            println("  Device match!")
            
            self.activePeripheral = peripheral
            
            println("  Connecting!")
            nc.postNotificationName("btFoundDeviceNotification", object: true)
            central.connectPeripheral(peripheral, options: nil)
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
        // println("Called centralManagerDidUpdateState: \(central.state)")
        
        switch (central.state) {
        case CBCentralManagerState.PoweredOn:
            println("BLE state Powered On")
            nc.postNotificationName(
                "btStateChangedNotification",
                object: "Scanning for peripherals..."
            )
            
            self.startScanning()
            
            break
        case CBCentralManagerState.Unknown:
            println("BLE state unknown")
            break
        case CBCentralManagerState.Resetting:
            println("BLE state resetting")
            break
        case CBCentralManagerState.Unsupported:
            println("BLE state unsupported")
            break
        case CBCentralManagerState.Unauthorized:
            println("BLE state unauthorized")
            break
        case CBCentralManagerState.PoweredOff:
            println("BLE state powered off")
            break
        default:
            break
        }
        
    }
    
    
}
