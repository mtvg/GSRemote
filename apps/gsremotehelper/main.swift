//
//  main.swift
//  gsremotehelper
//
//  Created by Niophys on 5/31/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation

class Test : SCBluetoothCentralDelegate {
    func central(central: SCBluetoothCentral, didConnectPeripheral peripheral: SCPeer) {
        print("Connected to peripheral with info \(peripheral.discoveryData)")
    }
    func central(central: SCBluetoothCentral, didDisconnectPeripheral peripheral: SCPeer) {
        print("Disconnected from peripheral")
    }
}


let stdin = NSFileHandle.fileHandleWithStandardInput()

/*

let bridge = GSChromeBridge()

var pointerPosition = 0
var sectionlength:UInt32 = 0
var sectionComplete = true
var sectionBuffer = NSMutableData()

stdinLoop: while true {
    
    let data = stdin.availableData
    
    pointerPosition = 0
    while pointerPosition < data.length {
        if sectionComplete && data.length-pointerPosition >= 4 { //TODO: Handle case where Uint32 section size is not complete 
            data.getBytes(&sectionlength, range: NSMakeRange(pointerPosition, 4))
            pointerPosition += 4
            
            sectionBuffer.length = 0
            sectionComplete = false
        }
        
        if !sectionComplete {
            let range = NSMakeRange(pointerPosition, min(Int(sectionlength)-sectionBuffer.length, data.length-pointerPosition))
            sectionBuffer.appendData(data.subdataWithRange(range))
            pointerPosition += range.length
            
            if sectionBuffer.length == Int(sectionlength) {
                sectionComplete = true
                bridge.receivedDataFromChrome(sectionBuffer)
            }
        }
    }
    
}
*/


let service = SCUUID(string: "0799eb34-73a7-48c0-8839-615cdf1b495b")
let myPeer = SCPeer(id: NSUUID(UUIDString: "0799eb34-73a7-48c0-8839-615cdf1b495b")!)

//let adv = SCBluetoothAdvertiser(centralPeer:myPeer, serviceUUID: service)
//adv.startAdvertising()

let central = SCBluetoothCentral(centralPeer: myPeer)
let del = Test()
central.delegate = del


stdinLoop: while true {
    
    if stdin.availableData.length > 0 {
        central.sendData(NSMutableData(length: 51200)!, onPriorityQueue: 1000)
    }
    
}


