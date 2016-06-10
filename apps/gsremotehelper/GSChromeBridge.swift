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
        let json = JSON(data:data)
        if let action = json["action"].string {
            if action == "disconnect" {
                bluetoothCentral.unsubscribeDevice(remote)
                bluetoothCentral.disconnectDevice(remote)
            }
            if action == "laseron" {
                setCurrentMousePosition()
            }
        }
        else if json.array?.count == 2 {
            if let x = json[0].int, let y = json[1].int {
                mousePosition.offset(dx: x, dy: y)
                CGEventPost(.CGHIDEventTap, CGEventCreateMouseEvent(nil, .MouseMoved, mousePosition, CGMouseButton.Left))
                return
            }
        }
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
    
    var mousePosition = NSMakePoint(0, 0)
    func setCurrentMousePosition() {
        let ev = CGEventCreate(nil);
        mousePosition = CGEventGetLocation(ev);
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_queue_create("delayQueue", DISPATCH_QUEUE_CONCURRENT), closure)
    }
    
}

extension CGPoint {
    
    public mutating func offset(dx dx: Int, dy: Int) -> CGPoint {
        x += CGFloat(dx)/20
        y += CGFloat(dy)/20
        return self
    }
}
