//
//  GSBluetoothPeripheral.swift
//  GSRemote
//
//  Created by Niophys on 6/7/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

class GSBluetoothPeripheral : NSObject, CBPeripheralManagerDelegate {
    
    var manager:CBPeripheralManager!
    let serviceCBUUID:CBUUID
    
    let GSREMOTE_DEVRX = CBUUID(string: "C7D2F0D7-6B65-4010-897F-705C08F79B5A")
    let GSREMOTE_DEVTX = CBUUID(string: "BCD602FB-8AAA-4BF4-89CD-E5B11BF4840F")
    
    var charWrite:CBMutableCharacteristic!
    
    var centralConnectionCallback:((CBCentral)->())?
    var centralDisconnectionCallback:((CBCentral)->())?
    var centralDataCallback:((NSData,CBCentral)->())?
    
    var connectedCentral:CBCentral?
    var sendingQueueData = [NSData]()
    var isSending = false
    
    init(withCBUUID uuid:CBUUID) {
        manager = CBPeripheralManager(delegate: nil, queue: nil)
        serviceCBUUID = uuid
        super.init()
        
        manager.delegate = self
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        if peripheral.state == .PoweredOn {
            
            let service = CBMutableService(type: serviceCBUUID, primary: true)
            charWrite = CBMutableCharacteristic(type: GSREMOTE_DEVTX, properties: .Notify, value: nil, permissions: CBAttributePermissions.Readable)
            service.characteristics = [
                charWrite,
                CBMutableCharacteristic(type: GSREMOTE_DEVRX, properties: [.WriteWithoutResponse, .Write], value: nil, permissions: CBAttributePermissions.Writeable)]
            manager.addService(service)
            
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        manager.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [serviceCBUUID]])
        print("startAdvertising")
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
        connectedCentral = central
        manager.stopAdvertising()
        if let callback = centralConnectionCallback {
            callback(central)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFromCharacteristic characteristic: CBCharacteristic) {
        connectedCentral = nil
        
        if let callback = centralDisconnectionCallback {
            callback(central)
        }
        
        manager.delegate = nil
        manager = nil
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
        
        for req in requests {
            if let data = req.value {
                peripheral.respondToRequest(req, withResult: CBATTError.Success)
                
                if let callback = centralDataCallback {
                    callback(data, req.central)
                }
            }
        }
    }
    
    func sendData(data:NSData) {
        sendingQueueData.append(data)
        if !isSending {
            flushQueue()
        }
    }
    
    func flushQueue() {
        isSending = true
        while sendingQueueData.count > 0 {
            let data = sendingQueueData[0]
            
            if !manager.updateValue(data, forCharacteristic: charWrite, onSubscribedCentrals: nil) {
                return
            }
            
            sendingQueueData.removeAtIndex(0)
        }
        isSending = false
    }
    
    func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
        if isSending {
            flushQueue()
        }
    }
}