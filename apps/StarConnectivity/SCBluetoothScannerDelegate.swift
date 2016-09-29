//
//  SCBluetoothScannerDelegate.swift
//  GSRemote
//
//  Created by Mathieu Vignau on 9/28/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation

public protocol SCBluetoothScannerDelegate: class {
    func scanner(scanner: SCBluetoothScanner, didFindCentral central: SCPeer)
    func scanner(scanner: SCBluetoothScanner, didLooseCentral central: SCPeer)
}

public extension SCBluetoothScannerDelegate {
    func scanner(scanner: SCBluetoothScanner, didFindCentral central: SCPeer) {}
    func scanner(scanner: SCBluetoothScanner, didLooseCentral central: SCPeer) {}
}
