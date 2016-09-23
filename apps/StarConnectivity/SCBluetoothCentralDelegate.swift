//
//  SCBluetoothCentralDelegate.swift
//  GSRemote
//
//  Created by Niophys on 7/5/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation

public protocol SCBluetoothCentralDelegate: class {
    func central(central: SCBluetoothCentral, didConnectPeripheral peripheral: SCPeer)
    func central(central: SCBluetoothCentral, didDisconnectPeripheral peripheral: SCPeer)
    func central(central: SCBluetoothCentral, didReceivedData data: NSData, onPriorityQueue priorityQueue:UInt8, fromPeripheral peripheral:SCPeer)
}

public extension SCBluetoothCentralDelegate {
    func central(central: SCBluetoothCentral, didConnectPeripheral peripheral: SCPeer) {}
    func central(central: SCBluetoothCentral, didDisconnectPeripheral peripheral: SCPeer) {}
    func central(central: SCBluetoothCentral, didReceivedData data: NSData, onPriorityQueue priorityQueue:UInt8, fromPeripheral peripheral:SCPeer) {}
}
