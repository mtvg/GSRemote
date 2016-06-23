//
//  GSConnectionScreen.swift
//  GSRemote
//
//  Created by Niophys on 6/8/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit
import CoreBluetooth

class GSConnectionScreen: UIViewController {
    
    var scannedPeripheral:GSScannedPeripheral!
    var bluetoothPeripheral:GSBluetoothPeripheral!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.title = scannedPeripheral.name
        navigationItem.prompt = scannedPeripheral.host
    }
    
    func onPresentationConnected(central:CBCentral) {
        statusLabel.text = "Connected"
        bluetoothPeripheral.centralConnectionCallback = nil
        
        performSegueWithIdentifier("Presentation", sender: self)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        bluetoothPeripheral = GSBluetoothPeripheral(withCBUUID: CBUUID(string: scannedPeripheral.uuid))
        bluetoothPeripheral.centralConnectionCallback = onPresentationConnected
        
        activityIndicator.startAnimating()
        statusLabel.text = "Establishing connection..."
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        activityIndicator.stopAnimating()
    }

    @IBAction func cancelConnection(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
        bluetoothPeripheral.cancelConnection()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Presentation" {
            let presentation:GSPresentationScreen = segue.destinationViewController as! GSPresentationScreen
            presentation.bluetoothPeripheral = bluetoothPeripheral
            presentation.scannedPeripheral = scannedPeripheral
        }
    }
}
