//
//  SCPeer.swift
//  GSRemote
//
//  Created by Niophys on 7/2/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

public class SCPeer {
    
    public let identifier:NSUUID
    
    static private var savedCBPeripheralPeers = [CBPeripheral:SCPeer]()
    static private var savedCBCentralPeers = [CBCentral:SCPeer]()
    
    init() {
        identifier = NSUUID()
    }
    
    private init(withNSUUID uuid:NSUUID) {
        identifier = uuid
    }
    
    static func savePeer(withIdentifier identifier:NSData, fromCBPeripheral peripheral:CBPeripheral) {
        let peer = SCPeer(withNSUUID: NSUUID())
        savedCBPeripheralPeers[peripheral] = peer
    }
    static func savePeer(withIdentifier identifier:NSData, fromCBCentral central:CBCentral) {
        let peer = SCPeer(withNSUUID: NSUUID())
        savedCBCentralPeers[central] = peer
    }
    static func getPeer(fromCBPeripheral peripheral:CBPeripheral) -> SCPeer? {
        return savedCBPeripheralPeers[peripheral]
    }
    static func getPeer(fromCBCentral central:CBCentral) -> SCPeer? {
        return savedCBCentralPeers[central]
    }
}
