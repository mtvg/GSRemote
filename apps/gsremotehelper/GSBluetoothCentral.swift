//
//  GSBluetoothCentral.swift
//  GSRemote
//
//  Created by Niophys on 6/6/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

class GSBluetoothCentral : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let manager:CBCentralManager
    let serviceCBUUID:CBUUID
    var connectedDevices = [RemoteDevice]()
    var discoveredPeripherals = [CBPeripheral]()
    
    let GSREMOTE_DEVRX = CBUUID(string: "C7D2F0D7-6B65-4010-897F-705C08F79B5A")
    let GSREMOTE_DEVTX = CBUUID(string: "BCD602FB-8AAA-4BF4-89CD-E5B11BF4840F")
    
    var deviceDiscoveryCallback:((RemoteDevice)->())?
    var deviceDisconnectCallback:((RemoteDevice)->())?
    var deviceDataCallback:((NSData, RemoteDevice)->())?
    
    init(withCBUUID uuid:String) {
        manager = CBCentralManager(delegate: nil, queue: dispatch_queue_create("bluetoothCentralQueue", DISPATCH_QUEUE_CONCURRENT))
        serviceCBUUID = CBUUID(string: uuid)
        super.init()
        
        manager.delegate = self
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            manager.scanForPeripheralsWithServices([serviceCBUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        if discoveredPeripherals.indexOf(peripheral) != nil {
            return
        }
        
        peripheral.delegate = self
        discoveredPeripherals.append(peripheral)
        manager.connectPeripheral(peripheral, options: nil)
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.discoverServices(nil)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if peripheral.services != nil {
            for service in peripheral.services! {
                if service.UUID == serviceCBUUID {
                    peripheral.discoverCharacteristics(nil, forService: service)
                    return
                }
            }
        }
        manager.cancelPeripheralConnection(peripheral)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        var txchar:CBCharacteristic?
        var rxchar:CBCharacteristic?
        
        if service.characteristics != nil {
            for characteristic in service.characteristics! {
                if characteristic.UUID == GSREMOTE_DEVTX {
                    txchar = characteristic
                }
                if characteristic.UUID == GSREMOTE_DEVRX {
                    rxchar = characteristic
                }
            }
            
            
            if txchar != nil && rxchar != nil {
                let device = RemoteDevice(peripheral: peripheral, rxchar: rxchar!, txchar: txchar!)
                connectedDevices.append(device)
                peripheral.setNotifyValue(true, forCharacteristic: txchar!)
                if deviceDiscoveryCallback != nil {
                    deviceDiscoveryCallback!(device)
                }
                
                return
            }
            
            manager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if let dIndex = connectedDevices.indexOf({$0.peripheral == peripheral}) {
            let device = connectedDevices[dIndex]
            if deviceDataCallback != nil, let data = characteristic.value {
                deviceDataCallback!(data, device)
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        
        if let pIndex = discoveredPeripherals.indexOf(peripheral) {
            discoveredPeripherals.removeAtIndex(pIndex)
        }
        
        if let dIndex = connectedDevices.indexOf({$0.peripheral == peripheral}) {
            let device = connectedDevices.removeAtIndex(dIndex)
            if deviceDisconnectCallback != nil {
                deviceDisconnectCallback!(device)
            }
        }
    }
    
    func sendData(data:NSData) {
        
        for device in connectedDevices {
            device.peripheral.writeValue(data, forCharacteristic: device.rxchar, type: CBCharacteristicWriteType.WithoutResponse)
        }
    }
    
    func disconnectAll() {
        for device in connectedDevices {
            disconnectDevice(device)
        }
    }
    
    func disconnectDevice(device:RemoteDevice) {
        manager.cancelPeripheralConnection(device.peripheral)
    }
    
    func unsubscribeAll() {
        for device in connectedDevices {
            unsubscribeDevice(device)
        }
    }
    
    func unsubscribeDevice(device:RemoteDevice) {
        device.peripheral.setNotifyValue(false, forCharacteristic: device.txchar)
    }
    
}

struct RemoteDevice {
    let peripheral:CBPeripheral
    let rxchar:CBCharacteristic
    let txchar:CBCharacteristic
}