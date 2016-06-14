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
    var scrolling =  false
    
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
    
    @IBAction func onTap(sender: UITapGestureRecognizer) {
        tapTimeout?.invalidate()
        tapTimeout = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: #selector(tapTimeoutCallback), userInfo: nil, repeats: false)
    }
    
    func tapTimeoutCallback() {
        bluetoothPeripheral.sendJSON(["action":"mouseclick"])
    }
    
    @IBAction func onPan(sender: UIPanGestureRecognizer) {
        
        if sender.state == UIGestureRecognizerState.Began {
            let touches = sender.numberOfTouches()
            if touches == 1 {
                bluetoothPeripheral.sendJSON(["action":"setmousepos"])
                if tapTimeout?.valid == true {
                    tapTimeout?.invalidate()
                    dragging = true
                    bluetoothPeripheral.sendJSON(["action":"mousestartdrag"])
                }
            }
            if touches == 2 {
                bluetoothPeripheral.sendJSON(["action":"startscrolling"])
                scrolling = true
            }
        }
        
        if sender.state == UIGestureRecognizerState.Changed {
            var velocity = sender.velocityInView(touchZone)
            velocity.x = velocity.x * max(1, abs(velocity.x)/400) / 2
            velocity.y = velocity.y * max(1, abs(velocity.y)/400) / 2
            if scrolling {
                velocity.x = velocity.x / 2
                velocity.y = velocity.y / 2
            }
            bluetoothPeripheral.sendJSON([Int(velocity.x), Int(velocity.y)], queue: "mouse")
        }
        
        if sender.state == UIGestureRecognizerState.Ended {
            if scrolling {
                bluetoothPeripheral.sendJSON(["action":"stopscrolling"])
                scrolling = false
            }
            if dragging {
                bluetoothPeripheral.sendJSON(["action":"mousestopdrag"])
                dragging = false
            }
        }
        
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
