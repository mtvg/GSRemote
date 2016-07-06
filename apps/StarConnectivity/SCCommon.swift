//
//  SCCommon.swift
//  GSRemote
//
//  Created by Niophys on 7/2/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation
import CoreBluetooth

struct SCCommon {
    static let DISCOVERYINFO_CHARACTERISTIC_UUID = CBUUID(string: "4B090A0B-4AD5-45B9-9FCF-FA6CA47339BB")
    static let CENTRAL_TX_CHARACTERISTIC_UUID = CBUUID(string: "C7D2F0D7-6B65-4010-897F-705C08F79B5A")
    static let CENTRAL_RX_CHARACTERISTIC_UUID = CBUUID(string: "BCD602FB-8AAA-4BF4-89CD-E5B11BF4840F")
}


public typealias SCUUID = CBUUID