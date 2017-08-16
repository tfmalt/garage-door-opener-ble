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

    fileprivate let nc = NotificationCenter.default
    
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
        print("Starting discover services")
        
        if let peri = self.peripheral {
            peri.discoverServices([CBUUID(string: btConst.SERVICE_UUID)])
        }
    }
    
    func sendNotificationIsConnected(_ connected: Bool) {
        if let peripheral = self.peripheral {
            nc.post(
                name: Notification.Name(rawValue: "btConnectionChangedNotification"),
                object: self
//                ,
//                userInfo: [
//                    "isConnected": connected,
//                    "name": peripheral.name
//                ]
            )
        }
    }
    
    //
    // Implementation of CBPeripheralDelegate functions:
    //
    
    // Did Discover Characteristics for Service
    // 
    // Adds the two characteristics to the object for easy retrival
    func peripheral(_ peripheral: CBPeripheral!, didDiscoverCharacteristicsFor service: CBService!, error: Error!) {
        print("got did discover characteristics for service")
        for cha in service.characteristics! {
            if cha.uuid == CBUUID(string: btConst.CHAR_TX_UUID) {
                self.txCharacteristic = (cha as CBCharacteristic)
            }
            else if cha.uuid == CBUUID(string: btConst.CHAR_RX_UUID) {
                self.rxCharacteristic = (cha as CBCharacteristic)
            }
            else {
                print("  Found unexpected characteristic: \(cha)")
                return
            }
            
            peripheral.setNotifyValue(true, for: cha as CBCharacteristic)
        }
        
        self.sendNotificationIsConnected(true)
    }
    
    func peripheral(_ peripheral: CBPeripheral!, didDiscoverDescriptorsFor characteristic: CBCharacteristic!, error: Error!) {
        print("got did discover descriptors for characteristic")
    }
    
    func peripheral(_ peripheral: CBPeripheral!, didDiscoverIncludedServicesFor service: CBService!, error: Error!) {
        print("got did discover included services for service")

    }
    
    func peripheral(_ peripheral: CBPeripheral!, didDiscoverServices error: Error!) {
        // array of the two available characteristics.
        let cUUIDs : [CBUUID] = [
            CBUUID(string: btConst.CHAR_RX_UUID),
            CBUUID(string: btConst.CHAR_TX_UUID)
        ]
        
        if (error != nil) {
            print("got error: a surprise: \(error)")
            return
        }
        
        // Sometimes services has been reported as nil. testing for that.
        if ((peripheral.services == nil) || (peripheral.services?.count == 0)) {
            print("Got no services!")
            return
        }

        for service in peripheral.services! {
            if (service.uuid == CBUUID(string: btConst.SERVICE_UUID)) {
                peripheral.discoverCharacteristics(cUUIDs, for: service as CBService)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral!, didModifyServices invalidatedServices: [AnyObject]!) {
        print("got did modify services")

    }
    
    func peripheral(_ peripheral: CBPeripheral!, didReadRSSI RSSI: NSNumber!, error: Error!) {
        // print("got did read rssi: \(RSSI)")
        
        if peripheral.state != CBPeripheralState.connected {
            print("  Peripheral state says not connected.")
            return
        }
        
        nc.post(
            name: Notification.Name(rawValue: "btRSSIUpdateNotification"),
            object: peripheral,
            userInfo: ["rssi": RSSI]
        )
    }
    
    func peripheral(_ peripheral: CBPeripheral!, didUpdateNotificationStateFor characteristic: CBCharacteristic!, error: Error!) {
        print("got did update notification state for characteristic")

    }
    
    func peripheral(_ peripheral: CBPeripheral!, didUpdateValueFor characteristic: CBCharacteristic!, error: Error!) {
        print("got did update value for characteristic")
    }
    
    func peripheral(_ peripheral: CBPeripheral!, didUpdateValueFor descriptor: CBDescriptor!, error: Error!) {
        print("got did update value for descriptor")
    }
    
    func peripheral(_ peripheral: CBPeripheral!, didWriteValueFor characteristic: CBCharacteristic!, error: Error!) {
        print("got did write value for characteristic")
    }
    
    func peripheral(_ peripheral: CBPeripheral!, didWriteValueFor descriptor: CBDescriptor!, error: Error!) {
        print("got did write value for descriptor")
    }
    
    func peripheralDidInvalidateServices(_ peripheral: CBPeripheral!) {
        print("got peripheral did invalidate services")
    }
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral!) {
        print("got peripheral did update name")
    }
    
    func peripheralDidUpdateRSSI(_ peripheral: CBPeripheral!, error: Error!) {
        print("Got peripheral did update rssi")
    }
}
