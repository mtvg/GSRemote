//
//  GSBluetoothScanner.swift
//  GSRemote
//
//  Created by Niophys on 6/6/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

class GSBluetoothScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let manager:CBCentralManager
    
    let GSREMOTE_DEVSERVICE = CBUUID(string: "9DE4F6A3-613B-4CCD-9480-183B0B0C794E")
    let GSREMOTE_ADVDATA = CBUUID(string: "4B090A0B-4AD5-45B9-9FCF-FA6CA47339BB")
    
    var deviceDiscoveryCallback:((JSON)->())?
    var peripheralUpdateCallback:(([GSScannedPeripheral])->())?
    
    var discoveredPeripherals = [CBPeripheral]()
    var discoveredPeripheralsID = [CBPeripheral:String]()
    var availablePeripherals = [GSScannedPeripheral]()
    var scanIsRequested = false
    var isScanning = false
    var peripheralLifeTimer:NSTimer?
    
    override init() {
        manager = CBCentralManager(delegate: nil, queue: nil)
        super.init()
        
        manager.delegate = self
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        if central.state == CBCentralManagerState.PoweredOn {
            if scanIsRequested {
                startScanning()
            }
        }
    }
    
    func startScanning() {
        scanIsRequested = true
        if manager.state == CBCentralManagerState.PoweredOn {
            manager.scanForPeripheralsWithServices([GSREMOTE_DEVSERVICE], options: [CBCentralManagerScanOptionAllowDuplicatesKey:true])
            peripheralLifeTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(checkPeripheralsLife), userInfo: nil, repeats: true)
            isScanning = true
            //print("start scanning")
        }
    }
    
    func stopScanning() {
        scanIsRequested = false
        isScanning = false
        peripheralLifeTimer?.invalidate()
        manager.stopScan()
        
        availablePeripherals.removeAll()
    }
    
    func checkPeripheralsLife() {
        var listUpdated = false
        while let index = availablePeripherals.indexOf({$0.lastSeen.timeIntervalSinceNow < -6}) {
            availablePeripherals.removeAtIndex(index)
            listUpdated = true
        }
        if listUpdated && peripheralUpdateCallback != nil {
            peripheralUpdateCallback!(availablePeripherals)
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        if let pid = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            
            if let index = availablePeripherals.indexOf({$0.peripheral == peripheral}) {
                
                if availablePeripherals[index].pid == pid {
                    availablePeripherals[index].lastSeen = NSDate()
                    return
                } else {
                    //print(availablePeripherals[index].name+" removed")
                    availablePeripherals.removeAtIndex(index)
                    if peripheralUpdateCallback != nil {
                        peripheralUpdateCallback!(availablePeripherals)
                    }
                }
            }
            
            if discoveredPeripherals.indexOf(peripheral) != nil {
                return
            }
            
            peripheral.delegate = self
            discoveredPeripherals.append(peripheral)
            discoveredPeripheralsID[peripheral] = pid
            manager.connectPeripheral(peripheral, options: nil)
            //print("didDiscoverPeripheral")
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        peripheral.discoverServices([GSREMOTE_DEVSERVICE])
        //print("peripheral connected")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if peripheral.services != nil {
            for service in peripheral.services! {
                if service.UUID == GSREMOTE_DEVSERVICE {
                    peripheral.discoverCharacteristics(nil, forService: service)
                    return
                }
            }
        }
        manager.cancelPeripheralConnection(peripheral)
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        if service.characteristics != nil {
            for characteristic in service.characteristics! {
                if characteristic.UUID == GSREMOTE_ADVDATA {
                    peripheral.readValueForCharacteristic(characteristic)
                    return
                }
            }
            
            manager.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if characteristic.UUID == GSREMOTE_ADVDATA && characteristic.value != nil && isScanning {
            print("characteristic's value is \(characteristic.value!.length) bytes long")
            print(error)
            let j = JSON(data: characteristic.value!)
            if let name = j["name"].string, let host = j["host"].string, let count = j["count"].string, let uuid = j["uuid"].string {
                let p = GSScannedPeripheral(name: name, host: host, count: 10, uuid: uuid, peripheral: peripheral, pid: discoveredPeripheralsID[peripheral]!, lastSeen: NSDate())
                availablePeripherals.append(p)
                //print(p.name+" added")
                if peripheralUpdateCallback != nil {
                    peripheralUpdateCallback!(availablePeripherals)
                }
                
            }
        }
        
        manager.cancelPeripheralConnection(peripheral)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        if let index = discoveredPeripherals.indexOf(peripheral) {
            discoveredPeripherals.removeAtIndex(index)
            discoveredPeripheralsID.removeValueForKey(peripheral)
        }
        //print("peripheral disconnected")
    }
}

struct GSScannedPeripheral {
    let name:String
    let host:String
    let count:Int
    let uuid:String
    let peripheral:CBPeripheral
    let pid:String
    var lastSeen:NSDate
}
