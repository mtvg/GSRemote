//
//  GSScanningScreen.swift
//  GSRemote
//
//  Created by Mathieu Vignau on 6/8/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit

class GSScanningScreen: UITableViewController {
    
    var bluetoothScanner:GSBluetoothScanner!
    var listOfPeripherals:[GSScannedPeripheral]!
    
    var selectedPeripheral:GSScannedPeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetoothScanner = GSBluetoothScanner()
        bluetoothScanner.peripheralUpdateCallback = peripheralListUpdated
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        listOfPeripherals = [GSScannedPeripheral]()
        tableView.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        navigationItem.prompt = "Scanning for presentations..."
        super.viewDidAppear(animated)
        bluetoothScanner.startScanning()
        UIApplication.sharedApplication().idleTimerDisabled = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        bluetoothScanner.stopScanning()
    }
    
    func peripheralListUpdated(newlist:[GSScannedPeripheral]) {
        listOfPeripherals = newlist
        tableView.reloadData()
        
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listOfPeripherals.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("peripheralcell")! as UITableViewCell
        
        cell.textLabel?.text = self.listOfPeripherals[indexPath.row].name
        cell.detailTextLabel?.text = self.listOfPeripherals[indexPath.row].host
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedPeripheral = listOfPeripherals[indexPath.row]
        performSegueWithIdentifier("Connection", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "Connection" {
            let viewcontroller = segue.destinationViewController as! GSConnectionScreen
            viewcontroller.scannedPeripheral = selectedPeripheral
        }
    }
}
