//
//  GSExtraScreen.swift
//  GSRemote
//
//  Created by Mathieu Vignau on 6/9/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit
import CoreBluetooth

class GSExtraScreen: UIViewController, VolumeHackDelegate {
    
    var bluetoothPeripheral:GSBluetoothPeripheral!
    var scannedPeripheral:GSScannedPeripheral!
    var selectedExtra:GSExtra!
    
    var popActionReceived = false
    
    var tapTimeout:NSTimer?
    var dragging =  false
    
    @IBOutlet weak var touchZone: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = selectedExtra.label
        
        bluetoothPeripheral.centralDataCallback = onData
        
    }
    
    func onVolumeUp() {
        bluetoothPeripheral.sendJSON(["action":"prev"])
        bluetoothPeripheral.sendJSON(["action":"presentation"])
    }
    func onVolumeDown() {
        bluetoothPeripheral.sendJSON(["action":"next"])
        bluetoothPeripheral.sendJSON(["action":"presentation"])
    }
    
    func onData(data:NSData, central:CBCentral) {
        let json = JSON(data: data)
        
        if let action = json["action"].string {
            if action == "presentation" {
                popActionReceived = true
                navigationController?.popViewControllerAnimated(true)
            }
        }
    }
    
    @IBAction func onTap(sender: UITapGestureRecognizer) {
        tapTimeout?.invalidate()
        tapTimeout = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: #selector(tapTimeoutCallback), userInfo: nil, repeats: false)
    }
    
    func tapTimeoutCallback() {
        bluetoothPeripheral.sendJSON(["action":"mouseclick"])
    }
    
    @IBAction func onPan(sender: UIPanGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            bluetoothPeripheral.sendJSON(["action":"setmousepos"])
            if tapTimeout?.valid == true {
                tapTimeout?.invalidate()
                dragging = true
                bluetoothPeripheral.sendJSON(["action":"mousestartdrag"])
            }
        }
        if sender.state == UIGestureRecognizerState.Ended {
            if dragging {
                bluetoothPeripheral.sendJSON(["action":"mousestopdrag"])
                dragging = false
            }
        }
        if sender.state == UIGestureRecognizerState.Changed {
            let velocity = sender.velocityInView(touchZone)
            bluetoothPeripheral.sendJSON([Int(velocity.x), Int(velocity.y)], queue: "mouse")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        popActionReceived = false
        AppDelegate.volumeHack.delegate = self
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if !popActionReceived && bluetoothPeripheral != nil && bluetoothPeripheral.isConnected {
            bluetoothPeripheral.sendJSON(["action":"presentation"])
        }
    }
    

}
