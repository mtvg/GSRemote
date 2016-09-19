//
//  SCPeer.swift
//  GSRemote
//
//  Created by Niophys on 7/2/16.
//  Copyright © 2016 MTVG. All rights reserved.
//


// Discovery Data format for protocol version 1:
//   [0-15]           [16]           [17-416]
//   16 bits          1 bit        0 to 400bits
// Peer UUID   Protocol Version   Optionnal JSON



import Foundation
import CoreBluetooth

public class SCPeer {
    
    
    static private var savedCBPeripheralPeers = [CBPeripheral:SCPeer]()
    static private var savedCBCentralPeers = [CBCentral:SCPeer]()
    
    private let _protocolVersion:UInt8
    private let _identifier:NSUUID
    private var _identifierBytes = [UInt8](count: 16, repeatedValue: 0)
    private var _discoveryInfo:JSON?
    private var _discoveryData:NSData!
    
    init() {
        _protocolVersion = SCCommon.STARCONNECTIVITY_PROTOCOL_VERSION
        _identifier = NSUUID()
        generateUuidBytes()
        generateDiscoveryData()
    }
    
    init(id:NSUUID) {
        _protocolVersion = SCCommon.STARCONNECTIVITY_PROTOCOL_VERSION
        _identifier = id
        generateUuidBytes()
        generateDiscoveryData()
    }
    
    init?(withDiscoveryInfo discoveryInfo:JSON) {
        _protocolVersion = SCCommon.STARCONNECTIVITY_PROTOCOL_VERSION
        _identifier = NSUUID()
        _discoveryInfo = discoveryInfo
        generateUuidBytes()
        if !generateDiscoveryData() {
            return nil
        }
    }
    
    private init?(fromDiscoveryData discoveryData:NSData) {
        _discoveryData = discoveryData
        if _discoveryData.length < 17 {
            return nil
        }
        
        _discoveryData.getBytes(&_identifierBytes, length: 16)
        var protocolBytes = [UInt8](count: 1, repeatedValue: 0)
        _discoveryData.getBytes(&protocolBytes, length: 1)
        _protocolVersion = protocolBytes[0]
        
        
        _identifier = NSUUID(UUIDBytes: _identifierBytes)
        
        if _discoveryData.length > 17 {
            _discoveryInfo = JSON(data: _discoveryData.subdataWithRange(NSMakeRange(17, _discoveryData.length-17)))
        }
        
    }
    
    private func generateUuidBytes() {
        identifier.getUUIDBytes(&_identifierBytes)
    }
    
    private func generateDiscoveryData() -> Bool {
        let buildDiscoveryData = NSMutableData()
        buildDiscoveryData.appendBytes(identifierBytes, length: 16)
        buildDiscoveryData.appendBytes([protocolVersion], length: 1)
        
        if _discoveryInfo != nil, let infoData = try? _discoveryInfo?.rawData() {
            if infoData == nil || infoData?.length > 400 {
                return false
            }
            buildDiscoveryData.appendData(infoData!)
        }
        
        _discoveryData = NSData(data: buildDiscoveryData)
        
        return true
    }
    
    public var protocolVersion:UInt8 {
        get {
            return _protocolVersion
        }
    }
    
    public var identifier:NSUUID {
        get {
            return _identifier
        }
    }
    
    public var identifierBytes:[UInt8] {
        get {
            return _identifierBytes
        }
    }
    
    public var discoveryInfo:JSON? {
        get {
            return _discoveryInfo
        }
    }
    
    public var discoveryData:NSData {
        get {
            return _discoveryData
        }
    }
   
    static func savePeer(withDiscoveryData discoveryData:NSData, fromCBPeripheral peripheral:CBPeripheral) -> SCPeer? {
        if let peer = SCPeer(fromDiscoveryData: discoveryData) {
            savedCBPeripheralPeers[peripheral] = peer
            return peer
        } else {
            return nil
        }
    }
    static func savePeer(withDiscoveryData discoveryData:NSData, fromCBCentral central:CBCentral) -> SCPeer? {
        if let peer = SCPeer(fromDiscoveryData: discoveryData) {
            savedCBCentralPeers[central] = peer
            return peer
        } else {
            return nil
        }
    }
    static func getPeer(fromCBPeripheral peripheral:CBPeripheral) -> SCPeer? {
        return savedCBPeripheralPeers[peripheral]
    }
    static func getPeer(fromCBCentral central:CBCentral) -> SCPeer? {
        return savedCBCentralPeers[central]
    }
    static func forgetPeer(fromCBPeripheral peripheral:CBPeripheral) -> SCPeer? {
        return savedCBPeripheralPeers.removeValueForKey(peripheral)
    }
    static func forgetPeer(fromCBCentral central:CBCentral) -> SCPeer? {
        return savedCBCentralPeers.removeValueForKey(central)
    }
}
