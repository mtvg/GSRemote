//
//  SCBluetoothCentral.swift
//  GSRemote
//
//  Created by Niophys on 7/2/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

public class SCBluetoothCentral :NSObject {
    
    public weak var delegate:SCBluetoothCentralDelegate?
    let centralPeer:SCPeer
    
    private let cbCentralManager:CBCentralManager
    private var cbCentralManagerDelegate:CentralManagerDelegate!
    private let scannedPeripheralService:CBUUID
    
    private var connectedDevices = [Device]()
    
    init(centralPeer peer:SCPeer) {
        
        cbCentralManager = CBCentralManager(delegate: nil, queue: dispatch_queue_create("starConnectivity_bluetoothCentralQueue", DISPATCH_QUEUE_CONCURRENT))
        centralPeer = peer
        scannedPeripheralService = CBUUID(NSUUID: peer.identifier)
        super.init()
        cbCentralManagerDelegate = CentralManagerDelegate(outer: self)
        cbCentralManager.delegate = cbCentralManagerDelegate
    }
    
    func sendData(data:NSData, onPriorityQueue priorityQueue:UInt8, flushQueue:Bool=false) {
        for device in connectedDevices {
            if device.peer != nil {
                device.sendData(data, onPriorityQueue: priorityQueue, flushQueue: flushQueue)
            }
        }
    }
    

    private class Device: NSObject, CBPeripheralDelegate {
        let peripheral:CBPeripheral
        let rxchar:CBCharacteristic
        let txchar:CBCharacteristic
        let infochar:CBCharacteristic
        var peer:SCPeer!
        
        private let transmission = SCDataTransmission()
        private let reception = SCDataReception()
        private var isWriting = false
        
        private weak var outer: SCBluetoothCentral!
        
        init(outer:SCBluetoothCentral, peripheral:CBPeripheral, rxchar: CBCharacteristic, txchar: CBCharacteristic, infochar: CBCharacteristic) {
            self.outer = outer
            self.peripheral = peripheral
            self.rxchar = rxchar
            self.txchar = txchar
            self.infochar = infochar
            
            super.init()
            
            reception.onData = onReceptionData
        }
        
        
        func sendData(data:NSData, onPriorityQueue priorityQueue:UInt8, flushQueue:Bool=false) {
            transmission.addToQueue(data, onPriorityQueue: priorityQueue, flushQueue: flushQueue)
            flushData()
        }
        
        func onReceptionData(data:NSData, queue:UInt8) {
            print("Received \(data.length) bytes on queue \(queue)")
            print(data)
            outer.delegate?.central(outer, didReceivedData: data, onPriorityQueue: queue, fromPeripheral: peer)
        }
        
        func flushData(repeatLastPacket:Bool=false) {
            if isWriting {
                return
            }
            
            if transmission.lastPacketErrorCount > 5 {
                return
            }
            
            
            if let packet = transmission.getNextPacket(repeatLastPacket) {
                peripheral.writeValue(packet, forCharacteristic: rxchar, type: .WithResponse)
                print(packet)
                isWriting = true
            }
        }
        
        @objc func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
            isWriting = false
            flushData(error != nil)
        }
        
        @objc func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
            if characteristic == rxchar && error == nil && characteristic.value?.length > 1 {
                reception.parsePacket(characteristic.value!)
            }
        }
    }
    
    private class CentralManagerDelegate: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
        
        private weak var outer: SCBluetoothCentral!
        private var oldPeripheralState:CBPeripheralManagerState?
        
        var discoveredPeripherals = [CBPeripheral]()
        
        init(outer: SCBluetoothCentral) {
            self.outer = outer
            super.init()
        }
        
        @objc func centralManagerDidUpdateState(central: CBCentralManager) {
            if central.state == .PoweredOn {
                central.scanForPeripheralsWithServices([outer.scannedPeripheralService], options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
            }
        }
        
        @objc func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
            if discoveredPeripherals.indexOf(peripheral) != nil {
                return
            }
            peripheral.delegate = self
            discoveredPeripherals.append(peripheral)
            central.connectPeripheral(peripheral, options: nil)
        }
        
        @objc func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
            peripheral.discoverServices(nil)
        }
        
        @objc func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
            
            if let pIndex = discoveredPeripherals.indexOf(peripheral) {
                discoveredPeripherals.removeAtIndex(pIndex)
            }
            
            if let dIndex = outer.connectedDevices.indexOf({$0.peripheral == peripheral}) {
                outer.connectedDevices.removeAtIndex(dIndex)
            }
            
            if let peer = SCPeer.forgetPeer(fromCBPeripheral: peripheral) {
                outer.delegate?.central(outer, didDisconnectPeripheral: peer)
            }
        }
        
        // Peripheral connection only handeling
        
        @objc func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
            
            if peripheral.services != nil {
                for service in peripheral.services! {
                    if service.UUID == outer.scannedPeripheralService {
                        peripheral.discoverCharacteristics(nil, forService: service)
                        return
                    }
                }
            }
            
            outer.cbCentralManager.cancelPeripheralConnection(peripheral)
        }
        
        @objc func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
            if service.characteristics != nil {
                
                var txchar:CBCharacteristic?
                var rxchar:CBCharacteristic?
                var infochar:CBCharacteristic?
                
                for characteristic in service.characteristics! {
                    if characteristic.UUID == SCCommon.TX_CHARACTERISTIC_UUID {
                        txchar = characteristic
                    }
                    if characteristic.UUID == SCCommon.RX_CHARACTERISTIC_UUID {
                        rxchar = characteristic
                    }
                    if characteristic.UUID == SCCommon.DISCOVERYINFO_CHARACTERISTIC_UUID {
                        infochar = characteristic
                    }
                }
                
                
                if txchar != nil && rxchar != nil && infochar != nil {
                    let device = Device(outer: outer, peripheral: peripheral, rxchar: rxchar!, txchar: txchar!, infochar: infochar!)
                    outer.connectedDevices.append(device)
                    peripheral.readValueForCharacteristic(device.infochar)
                    
                    return
                }
                
            }
            
            outer.cbCentralManager.cancelPeripheralConnection(peripheral)
            
        }
        
        @objc func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
            if let dIndex = outer.connectedDevices.indexOf({$0.peripheral == peripheral}) {
                let device = outer.connectedDevices[dIndex]
                if characteristic == device.infochar && characteristic.value != nil {
                    if let peer = SCPeer.savePeer(withDiscoveryData: characteristic.value!, fromCBPeripheral: peripheral) {
                        device.peer = peer
                        peripheral.delegate = device
                        peripheral.setNotifyValue(true, forCharacteristic: device.txchar)
                        outer.delegate?.central(outer, didConnectPeripheral: peer)
                        
                        return
                    }
                }
            }
            
            outer.cbCentralManager.cancelPeripheralConnection(peripheral)
        }
        
    }



}

