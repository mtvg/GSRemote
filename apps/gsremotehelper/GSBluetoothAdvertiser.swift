//
//  GSBluetoothAdvertiser.swift
//  GSRemote
//
//  Created by Niophys on 6/6/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

class GSBluetoothAdvertiser : NSObject, CBPeripheralManagerDelegate {
    
    let manager:CBPeripheralManager
    let serviceCBUUID:String
    let advertisedJSON:JSON
    
    let GSREMOTE_DEVSERVICE = CBUUID(string: "9DE4F6A3-613B-4CCD-9480-183B0B0C794E")
    let GSREMOTE_ADVDATA = CBUUID(string: "4B090A0B-4AD5-45B9-9FCF-FA6CA47339BB")
    
    init(uuid:String, withJSON json:JSON) {
        manager = CBPeripheralManager(delegate: nil, queue: dispatch_queue_create("bluetoothAdvertiserQueue", DISPATCH_QUEUE_CONCURRENT))
        serviceCBUUID = uuid
        advertisedJSON = json
        super.init()
        
        manager.delegate = self
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        if peripheral.state == .PoweredOn {
            
            let service = CBMutableService(type: GSREMOTE_DEVSERVICE, primary: true)
            
            let data = try! advertisedJSON.rawData()
            print("characteristic's value is \(data.length) bytes long")
            
            let advdata = CBMutableCharacteristic(type: GSREMOTE_ADVDATA, properties: CBCharacteristicProperties.Read, value: data, permissions: CBAttributePermissions.Readable)
            
            service.characteristics = [advdata]
            
            manager.addService(service)
        }
    }
    
    func peripheralManager(peripheral: CBPeripheralManager, didAddService service: CBService, error: NSError?) {
        var time = NSDate().timeIntervalSince1970
        let timedata = String(NSData(bytes: &time, length: sizeof(NSTimeInterval)).base64EncodedStringWithOptions([]).characters.dropLast())
        
        let dataToBeAdvertised:[String: AnyObject!] = [
            CBAdvertisementDataLocalNameKey : "GSR#"+timedata,
            CBAdvertisementDataServiceUUIDsKey : [GSREMOTE_DEVSERVICE],
            ]
        manager.startAdvertising(dataToBeAdvertised)
    }
    
    func stopAdvertising() {
        manager.stopAdvertising()
    }
}