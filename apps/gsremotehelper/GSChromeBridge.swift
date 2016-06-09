//
//  GSChromeBridge.swift
//  gsremotehelper
//
//  Created by Niophys on 6/5/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

class GSChromeBridge: NSObject {
    
    var presentationName = ""
    var presentationSlideCount = "0"
    let hostname = NSHost.currentHost().localizedName
    var bluetoothAdvertiser:GSBluetoothAdvertiser!
    var bluetoothCentral:GSBluetoothCentral!
    
    let stdout = NSFileHandle.fileHandleWithStandardOutput()
    
    override init() {
        super.init()
        
        requestPresentationData()
    }
    
    func requestPresentationData() {
        sendJsonToChrome(["action":"reqpresdata"])
    }
    
    //MARK: I/O Bridge
    
    func receivedDataFromChrome(data:NSData) {
        
        let json = JSON.parse(String(data:data, encoding: NSUTF8StringEncoding)!)
        
        if let action = json["action"].string {
            switch action {
            case "presdata":
                if let name = json["name"].string {
                    presentationName = name
                }
                if let count = json["count"].string{
                    presentationSlideCount = count
                }
                setupBluetooth()
            case "killbridge":
                bluetoothAdvertiser.stopAdvertising()
                bluetoothCentral.unsubscribeAll()
                delay(0.2) {
                    exit(EXIT_SUCCESS)
                }
            default:
                sendDataToRemote(data)
            }
        } else {
            sendDataToRemote(data)
        }
        
        
    }
    
    func sendJsonToChrome(json:JSON) {
        let data = try! json.rawData()
        sendDataToChrome(data)
    }
    
    func sendDataToChrome(data:NSData) {
        var l: Int = data.length
        let d = NSMutableData()
        d.appendData(NSData(bytes: &l, length: 4))
        d.appendData(data)
        stdout.writeData(d)
    }
    
    //MARK: Bluetooth
    
    func setupBluetooth() {
        let sessionUUID = NSUUID().UUIDString
        bluetoothAdvertiser = GSBluetoothAdvertiser(uuid: sessionUUID, withJSON: ["name":presentationName, "host":hostname!, "count":presentationSlideCount, "uuid":sessionUUID])
        bluetoothCentral = GSBluetoothCentral(withCBUUID: sessionUUID)
        bluetoothCentral.deviceDataCallback = receivedDataFromRemote
    }
    
    func receivedDataFromRemote(data:NSData, remote:RemoteDevice) {
        sendDataToChrome(data)
    }
    
    func sendJsonToRemote(json:JSON) {
        let data = try! json.rawData()
        sendDataToRemote(data)
    }
    
    func sendDataToRemote(data:NSData) {
        bluetoothCentral.sendData(data)
    }
    
    //MARK: Utilities
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_queue_create("delayQueue", DISPATCH_QUEUE_CONCURRENT), closure)
    }
    
}