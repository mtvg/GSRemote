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

class GSPresentationScreen: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var bluetoothPeripheral:GSBluetoothPeripheral!
    var scannedPeripheral:GSScannedPeripheral!
    var selectedExtra:GSExtra?
    
    var previousExtraView:GSExtraScreen?
    var currentSlide:String = ""
    var slideExtras:[String] = []
    
    @IBOutlet weak var extraTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = scannedPeripheral.name
        navigationItem.hidesBackButton = true
        
        bluetoothPeripheral.centralDisconnectionCallback = onDisconnected
        bluetoothPeripheral.centralDataCallback = onData
        
        //setupVolume()
        extraTableView.delegate = self
        extraTableView.dataSource = self
        
        updateSlideNumber()
        bluetoothPeripheral.sendJSON(["action":"ready"])
        
        print("loading GSPresentationScreen")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        bluetoothPeripheral.centralDataCallback = onData
        navigationItem.title = scannedPeripheral.name
        
        /*
        if previousExtraView != nil {
            volumeView.slider?.removeTarget(previousExtraView!, action: #selector(sliderDidChange(_:)), forControlEvents: .ValueChanged)
            volumeView.slider?.addTarget(self, action: #selector(sliderDidChange(_:)), forControlEvents: .ValueChanged)
            previousExtraView = nil
        }*/
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationItem.title = ""
        
        if isMovingFromParentViewController() || self.isBeingDismissed() {
            
            print("unlading GSPresentationScreen")
            
            /*
            volumeView.removeFromSuperview()
            if previousExtraView != nil {
                volumeView.slider?.removeTarget(previousExtraView!, action: #selector(sliderDidChange(_:)), forControlEvents: .ValueChanged)
                volumeView.slider?.addTarget(self, action: #selector(sliderDidChange(_:)), forControlEvents: .ValueChanged)
                previousExtraView = nil
            } else {
                volumeView.slider?.removeTarget(self, action: #selector(sliderDidChange(_:)), forControlEvents: .ValueChanged)
            }
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                print("Unable to initialize AVAudioSession")
            }*/
        }
    }
    
    func updateSlideNumber() {
        navigationItem.prompt = "Slide "+currentSlide+" of "+scannedPeripheral.count.description
    }
    
    @IBAction func onSwipeRight(sender: UISwipeGestureRecognizer) {
        bluetoothPeripheral.sendJSON(["action":"next"])
    }
    
    @IBAction func onSwipeLeft(sender: UISwipeGestureRecognizer) {
        bluetoothPeripheral.sendJSON(["action":"prev"])
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
        
        cell.textLabel?.text = self.slideExtras[indexPath.row]
        //cell.textLabel?.textColor = UIColor.whiteColor()
        //cell.backgroundColor = UIColor.clearColor()
        
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
    
    //MARK: Extras
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "Extra" {
            let extra = segue.destinationViewController as! GSExtraScreen
            extra.navigationItem.prompt = navigationItem.prompt
            extra.bluetoothPeripheral = bluetoothPeripheral
            extra.scannedPeripheral = scannedPeripheral
            extra.selectedExtra = selectedExtra!
            /*
            previousExtraView = extra
            volumeView.slider?.addTarget(previousExtraView!, action: #selector(sliderDidChange(_:)), forControlEvents: .ValueChanged)
            volumeView.slider?.removeTarget(self, action: #selector(sliderDidChange(_:)), forControlEvents: .ValueChanged)
            */
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
                    slideExtras.append(extra)
                }
            }
            
            extraTableView.reloadData()
        }
        
        if let action = json["action"].string {
            if action == "extra", let label = json["label"].string, let type = json["type"].string {
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
    
    //MARK: Volume Control
    
    var originalVolume:Float = 0
    var volumeView: MPVolumeView!
    var ignoreNextVolume = true
    func setupVolume() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Unable to initialize AVAudioSession")
        }
        
        self.volumeView = MPVolumeView(frame: CGRectMake(0, -100, 100, 50))
        UIApplication.sharedApplication().windows.first!.addSubview(self.volumeView!)
        if let slider = self.volumeView.slider {
            slider.addTarget(self, action: #selector(sliderDidChange(_:)), forControlEvents: .ValueChanged)
        }
    }
    
    @objc private func sliderDidChange(sender: UISlider) {
        if AppDelegate.invalidateVolume {
            originalVolume = sender.value
            AppDelegate.invalidateVolume = false
            return
        }
        
        if ignoreNextVolume {
            ignoreNextVolume = false
            return
        }
        
        if sender.value > originalVolume {
            onVolumeUp()
            ignoreNextVolume = true
        } else if sender.value < originalVolume {
            onVolumeDown()
            ignoreNextVolume = true
        } else if sender.value == 1.0 {
            onVolumeUp()
        } else if sender.value == 0.0 {
            onVolumeDown()
        }
        sender.value = originalVolume
    }
    

}

private extension MPVolumeView
{
    var slider: UISlider? {
        for view in self.subviews {
            if let isSlider = view as? UISlider {
                return isSlider
            }
        }
        return nil
    }
}

struct GSExtra {
    let label:String
    let type:String
}
