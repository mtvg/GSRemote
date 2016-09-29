//
//  ViewController.swift
//  SCTest
//
//  Created by Niophys on 9/10/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit

class ViewController: UIViewController, SCBluetoothPeripheralDelegate, SCBluetoothScannerDelegate {
    
    var peripheral:SCBluetoothPeripheral?
    var scanner:SCBluetoothScanner?

    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.sharedApplication().idleTimerDisabled = true
        
        /*scanner = SCBluetoothScanner(serviceToBrowse: SCUUID(string: "0799eb34-73a7-48c0-8839-615cdf1b495b"))
        scanner?.centralScanTimeout = 10
        scanner?.delegate = self
        scanner?.startScanning()*/
    }
    
    func scanner(scanner: SCBluetoothScanner, didFindCentral central: SCPeer) {
        print("Found central with info: \(central.discoveryInfo)")
    }
    
    func scanner(scanner: SCBluetoothScanner, didLooseCentral central: SCPeer) {
        print("Lost central: \(central.discoveryData)")
    }
    
    func peripheral(peripheral: SCBluetoothPeripheral, didReceivedData data: NSData, onPriorityQueue priorityQueue: UInt8, fromCentral central: SCPeer) {
        print("Received \(data.length) bytes on queue \(priorityQueue)")
    }
    
    func peripheral(peripheral: SCBluetoothPeripheral, didConnectCentral central: SCPeer) {
        dispatch_async(dispatch_get_main_queue(),{
            self.label.text = "Connected"
        })
        print("peripheral didConnectCentral")
    }
    
    func peripheral(peripheral: SCBluetoothPeripheral, didDisconnectCentral central: SCPeer, withError error: NSError?) {
        dispatch_async(dispatch_get_main_queue(),{
            self.label.text = "Disconnected"
        })
        
        self.peripheral = nil
        self.peripheral?.delegate = nil
        
        
        if error != nil {
            print("peripheral didDisconnectCentral with Error")
            dispatch_async(dispatch_get_main_queue(),{
                self.connectToCentral()
            })
        } else {
            print("peripheral didDisconnectCentral")
        }
    }
    
    func connectToCentral() {
        if peripheral != nil {
            return
        }
        peripheral = SCBluetoothPeripheral(peripheralPeer: SCPeer(), toCentralPeer: SCPeer(withUUID: NSUUID(UUIDString: "0799eb34-73a7-48c0-8839-615cdf1b495b")!))
        peripheral?.delegate = self
        self.label.text = "Connecting..."
    }
    
    @IBAction func onSend(sender: AnyObject) {
        let bytes = [UInt8](count:500, repeatedValue:UInt8(arc4random_uniform(256)))
        let data = NSData(bytes: bytes, length: bytes.count)
        let queue = arc4random_uniform(0x10)
        print("Sending \(data.length) bytes on queue \(queue)")
        peripheral?.sendData(data, onPriorityQueue: UInt8(queue))
    }
    
    @IBAction func onConnect(sender: AnyObject) {
        connectToCentral()
    }
    
    @IBAction func onDisconnect(sender: AnyObject) {
        peripheral?.disconnect()
    }
    
}

