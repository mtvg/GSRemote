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
    
    func sendData(data:NSData, onPriorityQueue priorityQueue:Int, flushQueue:Bool=false) {
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
        
        private weak var outer: SCBluetoothCentral!
        
        init(outer:SCBluetoothCentral, peripheral:CBPeripheral, rxchar: CBCharacteristic, txchar: CBCharacteristic, infochar: CBCharacteristic) {
            self.outer = outer
            self.peripheral = peripheral
            self.rxchar = rxchar
            self.txchar = txchar
            self.infochar = infochar
        }
        
        private var currentDataSent = 0
        private var currentData:NSData!
        private var sendingData = false
        
        
        func sendData(data:NSData, onPriorityQueue priorityQueue:Int, flushQueue:Bool=false) {
            if !sendingData {
                print("sending \(data.length) bytes")
                currentData = data
                currentDataSent = 0
                sendingData = true
                flushData()
            }
        }
        
        func flushData() {
            let sizeLeft = min(20, currentData.length-currentDataSent)
            peripheral.writeValue(currentData.subdataWithRange(NSRange(location: currentDataSent, length: sizeLeft)), forCharacteristic: rxchar, type: CBCharacteristicWriteType.WithResponse)
            currentDataSent += sizeLeft
            if currentDataSent == currentData.length {
                sendingData = false
            }
        }
        
        @objc func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
            let percent = Int(Float(currentDataSent)/Float(currentData.length)*100)
            print("sent \(percent)%")
            if sendingData {
                flushData()
            }
        }
        
        @objc func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
            outer.delegate?.central(outer, didReceivedData: characteristic.value!, fromPeripheral: peer)
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

