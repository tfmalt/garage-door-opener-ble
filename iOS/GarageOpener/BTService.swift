//
//  BTService.swift
//  GarageOpener
//
//  Created by Thomas Malt on 11/01/15.
//  Copyright (c) 2015 Thomas Malt. All rights reserved.
//

import Foundation
import CoreBluetooth

class BTService : NSObject, CBPeripheralDelegate {
    
    var peripheral       : CBPeripheral?
    var txCharacteristic : CBCharacteristic?
    var rxCharacteristic : CBCharacteristic?
    
    let btConst = BTConstants()

    private let nc = NSNotificationCenter.defaultCenter()
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        super.init()
        
        self.peripheral = peripheral
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func reset() {
        if peripheral != nil {
            peripheral = nil
        }
    }
    
    func startDiscoveringServices() {
        println("Starting discover services")
        self.peripheral?.discoverServices([CBUUID(string: btConst.SERVICE_UUID)])
    }
    
    func sendNotificationIsConnected(connected: Bool) {
        let info = ["isConnected": connected]
        nc.postNotificationName("btConnectionChangedNotification", object: self, userInfo: info)
    }
    
    //
    // Implementation of CBPeripheralDelegate functions:
    //
    
    // Did Discover Characteristics for Service
    // 
    // Adds the two characteristics to the object for easy retrival
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        println("got did discover characteristics for service")
        for cha in service.characteristics {
            if cha.UUID == CBUUID(string: btConst.CHAR_TX_UUID) {
                self.txCharacteristic = (cha as CBCharacteristic)
            }
            else if cha.UUID == CBUUID(string: btConst.CHAR_RX_UUID) {
                self.rxCharacteristic = (cha as CBCharacteristic)
            }
            else {
                println("  Found unexpected characteristic: \(cha)")
                return
            }
            
            peripheral.setNotifyValue(true, forCharacteristic: cha as CBCharacteristic)
        }
        
        self.sendNotificationIsConnected(true)
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverDescriptorsForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("got did discover descriptors for characteristic")
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverIncludedServicesForService service: CBService!, error: NSError!) {
        println("got did discover included services for service")

    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        // array of the two available characteristics.
        let cUUIDs : [CBUUID] = [
            CBUUID(string: btConst.CHAR_RX_UUID),
            CBUUID(string: btConst.CHAR_TX_UUID)
        ]
        
        if (error != nil) {
            println("got error: a surprise: \(error)")
            return
        }
        
        // Sometimes services has been reported as nil. testing for that.
        if ((peripheral.services == nil) || (peripheral.services.count == 0)) {
            println("Got no services!")
            return
        }

        for service in peripheral.services {
            if (service.UUID == CBUUID(string: btConst.SERVICE_UUID)) {
                peripheral.discoverCharacteristics(cUUIDs, forService: service as CBService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didModifyServices invalidatedServices: [AnyObject]!) {
        println("got did modify services")

    }
    
    func peripheral(peripheral: CBPeripheral!, didReadRSSI RSSI: NSNumber!, error: NSError!) {
        // println("got did read rssi: \(RSSI)")
        
        if peripheral.state != CBPeripheralState.Connected {
            println("  Peripheral state says not connected.")
            return
        }
        
        nc.postNotificationName(
            "btRSSIUpdateNotification",
            object: peripheral,
            userInfo: ["rssi": RSSI]
        )
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("got did update notification state for characteristic")

    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("got did update value for characteristic")
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForDescriptor descriptor: CBDescriptor!, error: NSError!) {
        println("got did update value for descriptor")
    }
    
    func peripheral(peripheral: CBPeripheral!, didWriteValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("got did write value for characteristic")
    }
    
    func peripheral(peripheral: CBPeripheral!, didWriteValueForDescriptor descriptor: CBDescriptor!, error: NSError!) {
        println("got did write value for descriptor")
    }
    
    func peripheralDidInvalidateServices(peripheral: CBPeripheral!) {
        println("got peripheral did invalidate services")
    }
    
    func peripheralDidUpdateName(peripheral: CBPeripheral!) {
        println("got peripheral did update name")
    }
    
    func peripheralDidUpdateRSSI(peripheral: CBPeripheral!, error: NSError!) {
        println("Got peripheral did update rssi")
    }
}
