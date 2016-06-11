//
//  VolumeHack.swift
//  GSRemote
//
//  Created by Niophys on 6/9/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class VolumeHack: NSObject {
    
    weak var delegate:VolumeHackDelegate?
    
    private var invalidateVolume = true
    private var originalVolume:Float = 0
    private var volumeView: MPVolumeView!
    private var ignoreNextVolume = true
    
    override init() {
        super.init()
        setupVolume()
    }
    
    private func setupVolume() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Unable to initialize AVAudioSession")
        }
        
        volumeView = MPVolumeView(frame: CGRectMake(0, -100, 100, 50))
        UIApplication.sharedApplication().windows.first!.addSubview(volumeView!)
        if let slider = volumeView.slider {
            slider.addTarget(self, action: #selector(sliderDidChange(_:)), forControlEvents: .ValueChanged)
        }
    }
    
    func recapture() {
        invalidateVolume = true
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Unable to initialize AVAudioSession")
        }
    }
    
    @objc private func sliderDidChange(sender: UISlider) {
        if invalidateVolume {
            originalVolume = sender.value
            invalidateVolume = false
            return
        }
        
        if ignoreNextVolume {
            ignoreNextVolume = false
            return
        }
        
        if sender.value > originalVolume {
            delegate?.onVolumeUp()
            ignoreNextVolume = true
        } else if sender.value < originalVolume {
            delegate?.onVolumeDown()
            ignoreNextVolume = true
        } else if sender.value == 1.0 {
            delegate?.onVolumeUp()
        } else if sender.value == 0.0 {
            delegate?.onVolumeDown()
        }
        sender.value = originalVolume
    }

}

protocol VolumeHackDelegate: class {
    func onVolumeUp()
    func onVolumeDown()
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

