//
//  GSBluetoothBridge.swift
//  GSRemote
//
//  Created by Mathieu Vignau on 6/7/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

enum Command: String {
    case PreviousSlide = "prev", NextSlide = "next", InitData = "ready", Presentation = "presentation"
}

class GSBluetoothBridge: NSObject {
    
    let scanner = GSBluetoothScanner()
    var peripheral:GSBluetoothPeripheral!
    
    var selectedPresentationName = ""
    var selectedPresentationHost = ""
    var selectedPresentationCount = ""
    
    
    var deviceDiscoveryCallback:(()->())?
    var deviceDisconnectCallback:(()->())?
    var deviceDataCallback:((String)->())?
    
    
    override init() {
        super.init()
        
        scanner.deviceDiscoveryCallback = onPresentationFound
    }
    
    func startScanningForPresentations() {
        scanner.startScanning()
    }
    
    func onPresentationFound(json:JSON) {
        if let name = json["name"].string {
            selectedPresentationName = name
        }
        if let host = json["host"].string {
            selectedPresentationHost = host
        }
        if let count = json["count"].string {
            selectedPresentationCount = count
        }
        if let uuid = json["uuid"].string {
            scanner.stopScanning()
            peripheral = GSBluetoothPeripheral(withCBUUID: CBUUID(string: uuid))
            peripheral.centralConnectionCallback = onPresentationConnection
            peripheral.centralDisconnectionCallback = onPresentationDisconnection
            peripheral.centralDataCallback = onPresentationData
        }
    }
    
    func onPresentationConnection(central:CBCentral) {
        print("onPresentationConnection")
        if (deviceDiscoveryCallback != nil) {
            deviceDiscoveryCallback!()
        }
    }
    func onPresentationDisconnection(central:CBCentral) {
        print("onPresentationDisconnection")
        if (deviceDisconnectCallback != nil) {
            deviceDisconnectCallback!()
        }
        
    }
    func onPresentationData(data:NSData, central:CBCentral) {
        if (deviceDataCallback != nil) {
            deviceDataCallback!(String(data: data, encoding:NSUTF8StringEncoding)!)
        }
    }
    
    func sendCommand(cmd:Command) {
        sendDictionary(["action":cmd.rawValue])
    }
    
    func sendExtra(extraIndex:Int) {
        sendDictionary(["action":"extra", "extra":extraIndex])
    }
    
    func sendExtraPan(direction:String) {
        sendDictionary(["action":"extra", "control":"pan", "dir":direction])
    }
    
    func sendExtraControl(control:String) {
        sendDictionary(["action":"extra", "control":control])
    }
    
    func sendDictionary(dict:AnyObject) {
        let json = JSON(dict)
        let payload = try! json.rawData()
        
        peripheral.sendData(payload)
    }
}