//
//  ViewController.swift
//  SCTest
//
//  Created by Niophys on 9/10/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SCBluetoothPeripheralDelegate {
    
    var peripheral:SCBluetoothPeripheral!

    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        peripheral = SCBluetoothPeripheral(peripheralPeer: SCPeer(), toCentralPeer: SCPeer(id: NSUUID(UUIDString: "0799eb34-73a7-48c0-8839-615cdf1b495b")!))
        peripheral.delegate = self
    }
    
    func peripheral(peripheral: SCBluetoothPeripheral, didReceivedData data: NSData, onPriorityQueue priorityQueue: UInt8, fromCentral central: SCPeer) {
        print("Received \(data.length) bytes on queue \(priorityQueue)")
    }
    
    @IBAction func onClick(sender: AnyObject) {
        let bytes = [UInt8](count:500, repeatedValue:UInt8(arc4random_uniform(256)))
        let data = NSData(bytes: bytes, length: bytes.count)
        let queue = arc4random_uniform(0x10)
        print("Sending \(data.length) bytes on queue \(queue)")
        peripheral.sendData(data, onPriorityQueue: UInt8(queue))
    }
    
}

