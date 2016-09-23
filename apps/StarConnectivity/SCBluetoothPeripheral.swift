//
//  SCBluetoothPeripheral.swift
//  GSRemote
//
//  Created by Niophys on 9/10/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

public class SCBluetoothPeripheral : NSObject {
    
    public weak var delegate:SCBluetoothPeripheralDelegate?
    public let centralPeer:SCPeer
    public let peer:SCPeer
    
    private let serviceUUID:CBUUID
    private let advData:[String:AnyObject]
    private let cbPeripheralManager:CBPeripheralManager
    private var cbPeripheralManagerDelegate:PeripheralManagerDelegate!
    private var txchar:CBMutableCharacteristic?
    private var rxchar:CBMutableCharacteristic?
    private var infochar:CBMutableCharacteristic?
    
    private var advertisingRequested = false
    private var servicesInitialised = false
    
    private let transmission = SCDataTransmission()
    private var isWriting = false
    private var lastPacketDidNotTransmit = false
    
    init(peripheralPeer peer:SCPeer, toCentralPeer centralPeer:SCPeer) {
        self.centralPeer = centralPeer
        self.peer = peer
        
        serviceUUID = CBUUID(NSUUID: centralPeer.identifier)
        
        advData = [CBAdvertisementDataServiceUUIDsKey : [serviceUUID]]
        cbPeripheralManager = CBPeripheralManager(delegate: nil, queue: dispatch_queue_create("starConnectivity_bluetoothPeripheralQueue", DISPATCH_QUEUE_CONCURRENT))
        
        super.init()
        cbPeripheralManagerDelegate = PeripheralManagerDelegate(outer: self)
        cbPeripheralManager.delegate = cbPeripheralManagerDelegate
        
        startAdvertising()
    }
    
    private func initService() {
        let service = CBMutableService(type: serviceUUID, primary: true)
        infochar = CBMutableCharacteristic(type: SCCommon.DISCOVERYINFO_CHARACTERISTIC_UUID, properties: CBCharacteristicProperties.Read, value: peer.discoveryData, permissions: CBAttributePermissions.Readable)
        txchar = CBMutableCharacteristic(type: SCCommon.TX_CHARACTERISTIC_UUID, properties: CBCharacteristicProperties.Notify, value: nil, permissions: CBAttributePermissions.Readable)
        rxchar = CBMutableCharacteristic(type: SCCommon.RX_CHARACTERISTIC_UUID, properties: [CBCharacteristicProperties.Write, CBCharacteristicProperties.WriteWithoutResponse], value: nil, permissions: CBAttributePermissions.Writeable)
        service.characteristics = [infochar!, txchar!, rxchar!]
        cbPeripheralManager.addService(service)
    }
    
    public func startAdvertising() {
        advertisingRequested = true
        
        if cbPeripheralManager.state == .PoweredOn {
            if !servicesInitialised {
                initService()
                servicesInitialised = true
            }
            cbPeripheralManager.startAdvertising(advData)
            print("Now advertising on channel \(serviceUUID) with info \(peer.discoveryData)")
        }
    }
    
    public func stopAdvertising() {
        advertisingRequested = false
        cbPeripheralManager.stopAdvertising()
    }
    
    public func sendData(data:NSData, onPriorityQueue priorityQueue:UInt8, flushQueue:Bool=false) {
        sendData(data, onPriorityQueue: priorityQueue, flushQueue: flushQueue, internalData: false)
    }
    
    
    
    private func sendData(data:NSData, onPriorityQueue priorityQueue:UInt8, flushQueue:Bool, internalData:Bool) {
        transmission.addToQueue(data, onPriorityQueue: priorityQueue, flushQueue: flushQueue, internalData: internalData)
        flushData()
    }
    
    private func flushData() {
        if isWriting {
            return
        }
        
        isWriting = true
        while let packet = transmission.getNextPacket(lastPacketDidNotTransmit) {
            lastPacketDidNotTransmit = !cbPeripheralManager.updateValue(packet, forCharacteristic: txchar!, onSubscribedCentrals: nil)
            if lastPacketDidNotTransmit {
                return
            }
        }
        isWriting = false
    }
    
    private func onReceptionData(data:NSData, queue:UInt8) {
        delegate?.peripheral(self, didReceivedData: data, onPriorityQueue: queue, fromCentral: peer)
    }
    
    private func onReceptionInternalData(data:NSData, queue:UInt8) {
        // Parse internal data
    }
    
    private class PeripheralManagerDelegate: NSObject, CBPeripheralManagerDelegate {
        
        private weak var outer: SCBluetoothPeripheral!
        private var oldPeripheralState:Int?
        
        private let reception = SCDataReception()
        
        init(outer: SCBluetoothPeripheral) {
            self.outer = outer
            super.init()
            reception.onData = outer.onReceptionData
            reception.onInternalData = outer.onReceptionInternalData
        }
        
        
        @objc func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
            
            if oldPeripheralState == peripheral.state.rawValue {
                return
            }
            oldPeripheralState = peripheral.state.rawValue
            
            if peripheral.state == .PoweredOn && outer.advertisingRequested {
                outer.startAdvertising()
            }
        }
        
        @objc private func peripheralManager(peripheral: CBPeripheralManager, didReceiveWriteRequests requests: [CBATTRequest]) {
            
            for req in requests {
                if let data = req.value {
                    peripheral.respondToRequest(req, withResult: CBATTError.Success)
                    
                    reception.parsePacket(data)
                }
            }
        }
        
        @objc private func peripheralManager(peripheral: CBPeripheralManager, central: CBCentral, didSubscribeToCharacteristic characteristic: CBCharacteristic) {
            print("peripheralManager didSubscribeToCharacteristic")
        }
        
        @objc private func peripheralManagerIsReadyToUpdateSubscribers(peripheral: CBPeripheralManager) {
            outer.isWriting = false
            outer.flushData()
        }
    }
}
