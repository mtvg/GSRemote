//
//  GSChromeBridge.swift
//  gsremotehelper
//
//  Created by Niophys on 6/5/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import AppKit
import CoreBluetooth
import MultipeerConnectivity

class GSChromeBridge: NSObject, MCSessionDelegate {
    
    var presentationName = ""
    var presentationSlideCount = "0"
    let hostname = NSHost.currentHost().localizedName
    var bluetoothAdvertiser:GSBluetoothAdvertiser!
    var bluetoothCentral:GSBluetoothCentral!
    
    var multipeerSession:MCSession!
    var mpeerid:MCPeerID!
    
    let stdout = NSFileHandle.fileHandleWithStandardOutput()
    
    override init() {
        super.init()
        requestPresentationData()
    }
    
    func requestPresentationData() {
        sendJsonToChrome(["action":"reqpresdata", "home":NSHomeDirectory()])
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
            case "windowpos":
                if let top = json["top"].int, let left = json["left"].int {
                    setScreenBounderies(extraTop: top, extraLeft: left)
                }
            case "killbridge":
                bluetoothAdvertiser.stopAdvertising()
                sendDataToRemote(NSData(bytes: [Int(0x00), Int(0xFF)], length: 2))
                delay(1) {
                    self.bluetoothCentral.unsubscribeAll()
                }
                delay(1.2) {
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
        
        mpeerid = MCPeerID(displayName: presentationName)
        multipeerSession = MCSession(peer: mpeerid)
        multipeerSession.delegate = self
    }
    
    func receivedDataFromRemote(data:NSData, remote:RemoteDevice) {
        let json = JSON(data:data)
        if let action = json["action"].string {
            if action == "disconnect" {
                bluetoothCentral.unsubscribeDevice(remote)
                bluetoothCentral.disconnectDevice(remote)
            }
            if action == "ready" {
                let keydown = CGEventCreateKeyboardEvent (nil, 0x41, true)
                let keyup = CGEventCreateKeyboardEvent (nil, 0x41, false)
                CGEventSetFlags(keydown, CGEventFlags.MaskControl)
                CGEventSetFlags(keyup, CGEventFlags.MaskControl)
                CGEventPost(.CGHIDEventTap, keydown)
                usleep(50_000)
                CGEventPost(.CGHIDEventTap, keyup)
            }
            if action == "setmousepos" {
                setCurrentMousePosition()
            }
            if action == "mousestartdrag" {
                dragging = true
                let mouseDown = CGEventCreateMouseEvent(nil, .LeftMouseDown, mousePosition, CGMouseButton.Left)
                CGEventPost(.CGHIDEventTap, mouseDown)
            }
            if action == "mouseclick" {
                setCurrentMousePosition()
                let mouseDown = CGEventCreateMouseEvent(nil, .LeftMouseDown, mousePosition, CGMouseButton.Left)
                let mouseUp = CGEventCreateMouseEvent(nil, .LeftMouseUp, mousePosition, CGMouseButton.Left)
                CGEventPost(.CGHIDEventTap, mouseDown)
                usleep(50_000)
                CGEventPost(.CGHIDEventTap, mouseUp)
            }
            if action == "mousestopdrag" {
                dragging = false
                let mouseUp = CGEventCreateMouseEvent(nil, .LeftMouseUp, mousePosition, CGMouseButton.Left)
                CGEventPost(.CGHIDEventTap, mouseUp)
            }
            if action == "startscrolling" {
                scrolling = true
            }
            if action == "stopscrolling" {
                scrolling = false
            }
        }
        else if json.array?.count == 2 {
            if let x = json[0].int, let y = json[1].int {
                
                if scrolling {
                    MouseWheel.scrollX(Int32(x), andY: Int32(y))
                } else {
                    mousePosition.offset(dx: x, dy: y)
                    
                    if mousePosition.x < screenFrame.origin.x {
                        mousePosition.x = screenFrame.origin.x
                    }
                    if mousePosition.x > screenFrame.origin.x + screenFrame.size.width {
                        mousePosition.x = screenFrame.origin.x + screenFrame.size.width - 1
                    }
                    if mousePosition.y < screenFrame.origin.y {
                        mousePosition.y = screenFrame.origin.y
                    }
                    if mousePosition.y > screenFrame.origin.y + screenFrame.size.height {
                        mousePosition.y = screenFrame.origin.y + screenFrame.size.height - 1
                    }
                    
                    if dragging {
                        CGEventPost(.CGHIDEventTap, CGEventCreateMouseEvent(nil, .LeftMouseDragged, mousePosition, CGMouseButton.Left))
                    } else {
                        CGEventPost(.CGHIDEventTap, CGEventCreateMouseEvent(nil, .MouseMoved, mousePosition, CGMouseButton.Left))
                    }
                }
                
                return
            }
        }
        else if let multipeer = json["peerdata"].string {
            
            if json["s"].int == 0 {
                peerstr = ""
            }
            
            peerstr = peerstr+multipeer
            
            if let slice = json["s"].int, let total = json["t"].int where slice == total {
                    
                let peerdata = NSKeyedArchiver.archivedDataWithRootObject(self.mpeerid)
                let slices = peerdata.base64EncodedStringWithOptions([]).split(70)
                for i in 0..<slices.count {
                    self.sendJsonToRemote(["peerdata":slices[i],"s":i+1,"t":slices.count])
                }
            }

            return
        }
        else if let multipeer = json["condata"].string {
            
            
            if json["s"].int == 0 {
                constr = ""
            }
            
            constr = constr+multipeer
            
            if let slice = json["s"].int, let total = json["t"].int where slice == total {
                if  let data = NSData(base64EncodedString: peerstr, options: []),
                    let peerid = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? MCPeerID,
                    let remotecondata = NSData(base64EncodedString: constr, options: []) {
                    
                    multipeerSession.nearbyConnectionDataForPeer(peerid, withCompletionHandler: { (data, error) in
                        print("ConnectionDataForPeer received")
                        
                        
                        
                        
                        let condata = data.base64EncodedStringWithOptions([])
                        let slicesd = condata.split(70)
                        for i in 0..<slicesd.count {
                            self.sendJsonToRemote(["condata":slicesd[i],"s":i+1,"t":slicesd.count])
                        }
                        
                        
                        
                        self.multipeerSession.connectPeer(peerid, withNearbyConnectionData: remotecondata)
                        print("connecting now")
                        print(peerid)
                        print(remotecondata)
                        
                    })
                }
            }
            
            return
        }
        
        sendDataToChrome(data)
    }
    
    var peerstr = ""
    var constr = ""
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        print("didReceiveData")
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        
        print("didChangeState")
        print(state.rawValue)
    }
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
        print("didReceiveStream")
    }
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
        print("didStartReceivingResourceWithName")
    }
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
        print("didFinishReceivingResourceWithName")
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
    var screenFrame = NSMakeRect(0, 0, 100, 100)
    var dragging = false
    var scrolling = false
    func setCurrentMousePosition() {
        let ev = CGEventCreate(nil);
        mousePosition = CGEventGetLocation(ev);
    }
    
    func setScreenBounderies(extraTop extraTop:Int, extraLeft:Int) {
        let screens = NSScreen.screens()
        for screen in screens! {
            if CGRectContainsPoint(screen.frame, NSMakePoint(CGFloat(extraLeft), CGFloat(extraTop))) {
                screenFrame = screen.frame
            }
        }
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
