//
//  SCBluetoothAdvertiser.swift
//  GSRemote
//
//  Created by Niophys on 6/30/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

public class SCBluetoothAdvertiser : NSObject {
    
    public let serviceUUID:SCUUID
    public let peer:SCPeer
    public let discoveryInfo:JSON?
    
    private let advData:[String:AnyObject]
    private let discoveryData:NSData
    private let peripheralManager:CBPeripheralManager
    
    private var advertisingRequested = false
    private var peripheralManagerDelegate:SCBluetoothAdvertiserPeripheralManagerDelegate!
    
    init?(peer:SCPeer, serviceUUID uuid: SCUUID, discoveryInfo info: JSON?) {
        self.serviceUUID = uuid
        self.peer = peer
        self.discoveryInfo = info
        
        // generating discovery data
        let buildDiscoveryData = NSMutableData()
        var uuidBytes: [UInt8] = [UInt8](count: 16, repeatedValue: 0)
        peer.identifier.getUUIDBytes(&uuidBytes)
        buildDiscoveryData.appendBytes(uuidBytes, length: 16)
        
        if info != nil, let infoData = try? info?.rawData() {
            if infoData == nil || infoData?.length > 496 {
                return nil
            }
            buildDiscoveryData.appendData(infoData!)
        }
        
        // generating unique name for this device
        var time = NSDate().timeIntervalSince1970
        let timedata = String(NSData(bytes: &time, length: sizeof(NSTimeInterval)).base64EncodedStringWithOptions([]).characters.dropLast())
        
        advData = [CBAdvertisementDataLocalNameKey : "SC#"+timedata, CBAdvertisementDataServiceUUIDsKey : [serviceUUID]]
        discoveryData = NSData(data: buildDiscoveryData)
        peripheralManager = CBPeripheralManager(delegate: nil, queue: dispatch_queue_create("starConnectivity_bluetoothAdvertiserQueue", DISPATCH_QUEUE_CONCURRENT))
        
        super.init()
        peripheralManagerDelegate = SCBluetoothAdvertiserPeripheralManagerDelegate(outer: self)
        peripheralManager.delegate = peripheralManagerDelegate
        
        initService()
    }
    
    public func startAdvertising() {
        advertisingRequested = true
        
        if peripheralManager.state == .PoweredOn {
            peripheralManager.startAdvertising(advData)
        }
    }
    
    public func stopAdvertising() {
        advertisingRequested = false
        peripheralManager.stopAdvertising()
    }
    
    private func initService() {
        let service = CBMutableService(type: serviceUUID, primary: true)
        let advchar = CBMutableCharacteristic(type: SCCommon.DISCOVERYINFO_CHARACTERISTIC_UUID, properties: CBCharacteristicProperties.Read, value: discoveryData, permissions: CBAttributePermissions.Readable)
        service.characteristics = [advchar]
        peripheralManager.addService(service)
    }
}

internal class SCBluetoothAdvertiserPeripheralManagerDelegate: NSObject, CBPeripheralManagerDelegate {
    
    private weak var outer: SCBluetoothAdvertiser!
    private var oldPeripheralState:CBPeripheralManagerState?
    
    init(outer: SCBluetoothAdvertiser) {
        self.outer = outer
        super.init()
    }
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        
        if oldPeripheralState == peripheral.state {
            return
        }
        oldPeripheralState = peripheral.state
        
        if peripheral.state == .PoweredOn && outer.advertisingRequested {
            outer.startAdvertising()
        }
    }
}

