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
    
    @IBOutlet weak var touchZone: UIView!
    
    @IBOutlet weak var playbackView: UIView!
    @IBOutlet weak var playheadSlider: UISlider!
    @IBOutlet weak var videoPositionLabel: UILabel!
    @IBOutlet weak var videoDurationLabel: UILabel!
    var videoDuration:Float = 0
    var videoPosition:Float = 0
    var seeking = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = selectedExtra.label
        if ![.Video,.Vimeo,.Youtube].contains(selectedExtra.type) {
            playbackView.hidden = true
        }
        
        bluetoothPeripheral.centralDataCallback = onData
        
        setupGestures()
        
    }
    
    //MARK: Video playback
    
    
    @IBAction func onToggleMute(sender: UIButton) {
        bluetoothPeripheral.sendJSON(["player":["cmd":"toggleMute"]])
    }
    
    @IBAction func onTogglePlay(sender: UIButton) {
        bluetoothPeripheral.sendJSON(["player":["cmd":"togglePlay"]])
    }
    
    @IBAction func onSliderSeek(sender: UISlider) {
        let seekTo = Int(sender.value*videoDuration)
        videoPositionLabel.text = timeFormatted(seekTo)
    }
    
    @IBAction func onSliderStart(sender: UISlider) {
        seeking = true
    }
    
    @IBAction func onSliderEnd(sender: UISlider) {
        seeking = false
        let seekTo = Int(sender.value*videoDuration)
        bluetoothPeripheral.sendJSON(["player":["cmd":"seek", "arg":seekTo]])
    }
    
    //MARK: Volume Buttons
    
    func onVolumeUp() {
        bluetoothPeripheral.sendJSON(["action":"prev"])
        bluetoothPeripheral.sendJSON(["action":"presentation"])
    }
    func onVolumeDown() {
        bluetoothPeripheral.sendJSON(["action":"next"])
        bluetoothPeripheral.sendJSON(["action":"presentation"])
    }
    
    //MARK: Bluetooth
    
    func onData(data:NSData, central:CBCentral) {
        let json = JSON(data: data)
        
        if let action = json["action"].string {
            if action == "presentation" {
                popActionReceived = true
                navigationController?.popViewControllerAnimated(true)
            }
        }
        
        if json["player"] != nil {
            if let dur = json["player"]["dur"].float, let pos = json["player"]["pos"].float {
                videoDuration = dur
                videoPosition = pos
                videoDurationLabel.text = timeFormatted(Int(videoDuration))
                if !seeking {
                    videoPositionLabel.text = timeFormatted(Int(videoPosition))
                    playheadSlider.value = videoPosition/videoDuration
                }
            }
            
            /*if let status = json["player"]["status"].string {
                
            }
            
            if let muted = json["player"]["muted"].bool {
                
            }*/
        }
    }
    
    //MARK: Virtual Mouse
    
    var originPoint:CGPoint!
    var originDate:NSDate!
    
    func setupGestures() {
        let dragRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onDragGesture))
        dragRecognizer.numberOfTapsRequired = 2
        dragRecognizer.minimumPressDuration = 0.05
        
        let scrollRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(onScrollGesture))
        scrollRecognizer.numberOfTapsRequired = 1
        scrollRecognizer.minimumPressDuration = 0.05
        scrollRecognizer.requireGestureRecognizerToFail(dragRecognizer)
        
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture))
        panRecognizer.requireGestureRecognizerToFail(scrollRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapGesture))
        tapRecognizer.requireGestureRecognizerToFail(panRecognizer)
        tapRecognizer.requireGestureRecognizerToFail(scrollRecognizer)
        tapRecognizer.requireGestureRecognizerToFail(dragRecognizer)
        
        touchZone.addGestureRecognizer(dragRecognizer)
        touchZone.addGestureRecognizer(scrollRecognizer)
        touchZone.addGestureRecognizer(panRecognizer)
        touchZone.addGestureRecognizer(tapRecognizer)
    }
    
    func onDragGesture(sender:UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            setMouseMove(sender)
            bluetoothPeripheral.sendJSON(["action":"mousestartdrag"])
        }
        if sender.state == UIGestureRecognizerState.Changed {
            sendMouseMove(sender, scrolling: false)
        }
        if sender.state == UIGestureRecognizerState.Ended {
            bluetoothPeripheral.sendJSON(["action":"mousestopdrag"])
        }
        
    }
    func onScrollGesture(sender:UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            setMouseMove(sender)
            bluetoothPeripheral.sendJSON(["action":"startscrolling"])
        }
        if sender.state == UIGestureRecognizerState.Changed {
            sendMouseMove(sender, scrolling: true)
        }
        if sender.state == UIGestureRecognizerState.Ended {
            bluetoothPeripheral.sendJSON(["action":"stopscrolling"])
        }
    }
    
    func onPanGesture(sender:UIPanGestureRecognizer) {
        if sender.state == UIGestureRecognizerState.Began {
            setMouseMove(sender)
            bluetoothPeripheral.sendJSON(["action":"setmousepos"])
        }
        if sender.state == UIGestureRecognizerState.Changed {
            sendMouseMove(sender, scrolling: false)
        }
    }
    
    func onTapGesture(sender:UITapGestureRecognizer) {
        bluetoothPeripheral.sendJSON(["action":"mouseclick"])
    }
    
    func setMouseMove(sender:UIGestureRecognizer) {
        originPoint = sender.locationInView(touchZone)
        originDate = NSDate()
    }
    
    func sendMouseMove(sender:UIGestureRecognizer, scrolling:Bool) {
        let p = sender.locationInView(touchZone)
        let now = NSDate()
        let timediff = CGFloat(now.timeIntervalSinceDate(originDate))
        var velocity = CGPoint(x: (p.x-originPoint.x)/timediff, y: (p.y-originPoint.y)/timediff)
        originPoint = p
        originDate = now
        
        velocity.x = velocity.x * max(1, abs(velocity.x)/400) / 2
        velocity.y = velocity.y * max(1, abs(velocity.y)/400) / 2
        if scrolling {
            velocity.x = velocity.x / 2
            velocity.y = velocity.y / 2
        }
        bluetoothPeripheral.sendJSON([Int(velocity.x), Int(velocity.y)], queue: "mouse")
    }
    
    //MARK: Miscs
    
    func timeFormatted(totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        let hours: Int = totalSeconds / 3600
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
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
