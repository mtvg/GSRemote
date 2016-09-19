//
//  ViewController.swift
//  SCTest
//
//  Created by Niophys on 9/10/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var peripheral:SCBluetoothPeripheral!

    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        peripheral = SCBluetoothPeripheral(peripheralPeer: SCPeer(), toCentralPeer: SCPeer(id: NSUUID(UUIDString: "0799eb34-73a7-48c0-8839-615cdf1b495b")!))
    }
}

