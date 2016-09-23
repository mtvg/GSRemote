//
//  SCBluetoothPeripheralDelegate.swift
//  GSRemote
//
//  Created by Niophys on 9/10/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation

public protocol SCBluetoothPeripheralDelegate: class {
    func peripheral(peripheral: SCBluetoothPeripheral, didConnectCentral central: SCPeer)
    func peripheral(peripheral: SCBluetoothPeripheral, didDisconnectCentral central: SCPeer, withError error:NSError?)
    func peripheral(peripheral: SCBluetoothPeripheral, didReceivedData data: NSData, onPriorityQueue priorityQueue:UInt8, fromCentral central:SCPeer)
}

public extension SCBluetoothPeripheralDelegate {
    func peripheral(peripheral: SCBluetoothPeripheral, didConnectCentral central: SCPeer) {}
    func peripheral(peripheral: SCBluetoothPeripheral, didDisconnectCentral central: SCPeer, withError error:NSError?) {}
    func peripheral(peripheral: SCBluetoothPeripheral, didReceivedData data: NSData, onPriorityQueue priorityQueue:UInt8, fromCentral central:SCPeer) {}
}
