//
//  GSPresentationScreen.swift
//  GSRemote
//
//  Created by Mathieu Vignau on 6/8/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit
import CoreBluetooth
import MediaPlayer
import AVFoundation

class GSPresentationScreen: UIViewController, VolumeHackDelegate, UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var bluetoothPeripheral:GSBluetoothPeripheral!
    var scannedPeripheral:GSScannedPeripheral!
    var selectedExtra:GSExtra?
    
    var previousExtraView:GSExtraScreen?
    var currentSlide:String = ""
    var slideExtras:[GSExtra] = []
    
    @IBOutlet weak var extraTableView: UITableView!
    
    @IBOutlet var swipeDown: UISwipeGestureRecognizer!
    @IBOutlet var swipeLeft: UISwipeGestureRecognizer!
    @IBOutlet var swipeRight: UISwipeGestureRecognizer!
    @IBOutlet var swipeUp: UISwipeGestureRecognizer!
    @IBOutlet var panGesture: UIPanGestureRecognizer!
    @IBOutlet weak var labelViewGestureNavigation: UIView!
    @IBOutlet weak var labelViewGestureLaser: UIView!
    @IBOutlet weak var touchZone: UIView!
    @IBOutlet weak var slidePickerContainer: UIView!
    @IBOutlet weak var slidePicker: UIPickerView!
    
    var navigationGestureMode = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = scannedPeripheral.name
        navigationItem.hidesBackButton = true
        
        bluetoothPeripheral.centralDisconnectionCallback = onDisconnected
        bluetoothPeripheral.centralDataCallback = onData
        
        extraTableView.delegate = self
        extraTableView.dataSource = self
        
        slidePicker.delegate = self
        slidePicker.dataSource = self
        
        updateSlideNumber()
        bluetoothPeripheral.sendJSON(["action":"ready"])
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        slidePickerContainer.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        bluetoothPeripheral.centralDataCallback = onData
        bluetoothPeripheral.sendJSON(["action":"ready"])
        navigationItem.title = scannedPeripheral.name
        AppDelegate.volumeHack.delegate = self
        
        UIApplication.sharedApplication().idleTimerDisabled = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationItem.title = ""
    }
    
    func updateSlideNumber() {
        navigationItem.prompt = "Slide "+currentSlide+" of "+scannedPeripheral.count.description
    }
    
    @IBAction func onSwipeRight(sender: UISwipeGestureRecognizer) {
        bluetoothPeripheral.sendJSON(["action":"prev"])
    }
    
    @IBAction func onSwipeLeft(sender: UISwipeGestureRecognizer) {
        bluetoothPeripheral.sendJSON(["action":"next"])
    }
    @IBAction func onSwipeUp(sender: UISwipeGestureRecognizer) {
        bluetoothPeripheral.sendJSON(["action":"goto", "slide":1])
    }
    @IBAction func onSwipeDown(sender: UISwipeGestureRecognizer) {
        slidePicker.selectRow(Int(currentSlide)!-1, inComponent: 0, animated: false)
        slidePickerContainer.hidden = false
    }
    
    @IBAction func onDoubleTapped(sender: UITapGestureRecognizer) {
        navigationGestureMode = !navigationGestureMode
        
        swipeDown.enabled = navigationGestureMode
        swipeLeft.enabled = navigationGestureMode
        swipeUp.enabled = navigationGestureMode
        swipeRight.enabled = navigationGestureMode
        panGesture.enabled = !navigationGestureMode
        labelViewGestureNavigation.hidden = !navigationGestureMode
        labelViewGestureLaser.hidden = navigationGestureMode
    }
    
    @IBAction func onPan(sender: UIPanGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            bluetoothPeripheral.sendJSON(["action":"laseron"])
        }
        if sender.state == UIGestureRecognizerState.Ended {
            bluetoothPeripheral.sendJSON(["action":"laseroff"])
        }
        if sender.state == UIGestureRecognizerState.Changed {
            var velocity = sender.velocityInView(touchZone)
            velocity.x = velocity.x * max(1, abs(velocity.x)/400) / 2
            velocity.y = velocity.y * max(1, abs(velocity.y)/400) / 2
            bluetoothPeripheral.sendJSON([Int(velocity.x), Int(velocity.y)], queue: "mouse")
        }
    }
    
    //MARK: Table View
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.slideExtras.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = self.extraTableView.dequeueReusableCellWithIdentifier("ExtraCell")! as UITableViewCell
        
        cell.textLabel?.text = self.slideExtras[indexPath.row].label
        let type = self.slideExtras[indexPath.row].type
        if type == .Youtube {
            cell.imageView?.image = UIImage(named: "youtube")
        }
        if type == .Video {
            cell.imageView?.image = UIImage(named: "video")
        }
        if type == .Vimeo {
            cell.imageView?.image = UIImage(named: "vimeo")
        }
        if type == .URL {
            cell.imageView?.image = UIImage(named: "chrome")
        }
        
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        bluetoothPeripheral.sendJSON(["action":"extra", "extra":indexPath.row])
    }
    
    func onVolumeUp() {
        bluetoothPeripheral.sendJSON(["action":"prev"])
    }
    func onVolumeDown() {
        bluetoothPeripheral.sendJSON(["action":"next"])
    }
    
    //MARK: Slide Picker
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return scannedPeripheral.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "Slide "+(row+1).description+" of "+scannedPeripheral.count.description
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        bluetoothPeripheral.sendJSON(["action":"goto", "slide":row+1])
    }
    
    @IBAction func onSlideDone(sender: AnyObject) {
        slidePickerContainer.hidden = true
    }
    
    
    //MARK: Extras
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "Extra" {
            let extra = segue.destinationViewController as! GSExtraScreen
            extra.navigationItem.prompt = navigationItem.prompt
            extra.bluetoothPeripheral = bluetoothPeripheral
            extra.scannedPeripheral = scannedPeripheral
            extra.selectedExtra = selectedExtra!
        }
    }
    
    //MARK:  Bluetooth callbacks
    
    func onData(data:NSData, central:CBCentral) {
        let json = JSON(data: data)
        
        if let slide = json["currentPage"].string {
            currentSlide = slide
            updateSlideNumber()
        }
        if let extras = json["extras"].array {
            
            slideExtras = []
            for extraJson in extras {
                if let extra = extraJson.string {
                    let extraType = GSExtraType(rawValue: String(extra[extra.startIndex]))
                    let extraLabel = extra.substringFromIndex(extra.startIndex.advancedBy(1))
                    if extraType != nil {
                        slideExtras.append(GSExtra(label: extraLabel, type: extraType!))
                    }
                    
                }
            }
            
            extraTableView.reloadData()
        }
        
        if let action = json["action"].string {
            if action == "extra", let label = json["label"].string, let typeid = json["type"].string, let type = GSExtraType(rawValue: typeid) {
                selectedExtra = GSExtra(label: label, type: type)
                performSegueWithIdentifier("Extra", sender: self)
            }
        }
    }
    
    func onDisconnected(central:CBCentral) {
        navigationController?.popToViewController((navigationController?.viewControllers[0])!, animated: true)
    }
    
    
    @IBAction func onDisconnect(sender: AnyObject) {
        bluetoothPeripheral.cancelConnection()
    }
    

}

struct GSExtra {
    let label:String
    let type:GSExtraType
}

enum GSExtraType:String {
    case Youtube="Y", Vimeo="O", Video="V", URL="U"
}


