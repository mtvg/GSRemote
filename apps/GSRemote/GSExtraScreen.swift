//
//  GSExtraScreen.swift
//  GSRemote
//
//  Created by Mathieu Vignau on 6/9/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit
import CoreBluetooth

class GSExtraScreen: UIViewController {
    
    var bluetoothPeripheral:GSBluetoothPeripheral!
    var scannedPeripheral:GSScannedPeripheral!
    var selectedExtra:GSExtra!
    
    var popActionReceived = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = selectedExtra.label
        
        bluetoothPeripheral.centralDataCallback = onData
        
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        popActionReceived = false
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if !popActionReceived && bluetoothPeripheral != nil && bluetoothPeripheral.isConnected {
            bluetoothPeripheral.sendJSON(["action":"presentation"])
        }
    }
    

}
