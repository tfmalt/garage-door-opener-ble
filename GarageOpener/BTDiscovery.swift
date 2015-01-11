//
//  BTDiscovery.swift
//  GarageOpener
//
//  Created by Thomas Malt on 10/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation
import CoreBluetooth

class BTDiscovery: NSObject, CBCentralManagerDelegate {
    
    var nc = NSNotificationCenter.defaultCenter()
    private let centralManager: CBCentralManager?
    
    override init() {
        super.init()
        
        let queue = dispatch_queue_create("no.malt", DISPATCH_QUEUE_SERIAL)
        centralManager = CBCentralManager(delegate: self, queue: queue)
    }
    
    func sayHello() -> String {
        println("Testing output.");
        return "Hello from BTDiscovery.";
    }
    
    //
    // Implementation of CBCentralManagerDelegate
    //
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        println("Called didConnectPeripheral");
        
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        println("Called didDisconnectPeripheral")
        
    }
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("Called didDiscoverPeripheral")
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
        println("Called centralManagerDidUpdateState: \(central.state)")
        
        switch (central.state) {
        case CBCentralManagerState.PoweredOn:
            println("BLE Starting Scanning for device...")
            nc.postNotificationName(
                "bleStateChangedNotification",
                object: "Scanning for device..."
            )
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
