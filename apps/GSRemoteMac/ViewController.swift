//
//  ViewController.swift
//  GSRemoteMac
//
//  Created by Mathieu Vignau on 6/14/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    let fm = NSFileManager.defaultManager()
    let bundle = NSBundle.mainBundle()
    let chromeExtensionId = "bejldbalomejcoebpmifodlkokjckbbo"
    
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var warningView: NSView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        createNativeHostFile()
        let currentFolder = bundle.bundlePath
        if currentFolder.rangeOfString("/Applications")?.startIndex.distanceTo(currentFolder.startIndex) === 0 {
            warningView.hidden = true
        } else {
            warningView.hidden = false
        }
    }
    
    func createNativeHostFile() {
        
        let nativeMessagingHosts = NSHomeDirectory()+"/Library/Application Support/Google/Chrome/NativeMessagingHosts/"
        if !fm.fileExistsAtPath(nativeMessagingHosts) {
            do {
                try fm.createDirectoryAtPath(nativeMessagingHosts, withIntermediateDirectories: false, attributes: nil)
            } catch {
                statusLabel.stringValue = "Could not locate your Google Chrome personal folder."
                return
            }
        }
        
        let nativeMessagingHostJson:JSON = [
            "allowed_origins":["chrome-extension://"+chromeExtensionId+"/"],
            "description": "Google Slides Remote Helper",
            "name": "net.mtvg.gsremotehelper",
            "path": bundle.pathForResource("gsremotehelper", ofType: nil)!,
            "type": "stdio"]
        
        let nativeMessagingHost = nativeMessagingHosts+"net.mtvg.gsremotehelper.json"
        if !fm.createFileAtPath(nativeMessagingHost, contents: try! nativeMessagingHostJson.rawData(), attributes: nil) {
            statusLabel.stringValue = "Could not write Google Chrome Extension file."
            return
        }
        
        
        let extensionDeploys = NSHomeDirectory()+"/Library/Application Support/Google/Chrome/External Extensions/"
        if !fm.fileExistsAtPath(extensionDeploys) {
            do {
                try fm.createDirectoryAtPath(extensionDeploys, withIntermediateDirectories: false, attributes: nil)
            } catch {
                statusLabel.stringValue = "Could not locate your Google Chrome personal folder."
                return
            }
        }
        
        
        let extensionDeployJson:JSON = ["external_update_url":"https://clients2.google.com/service/update2/crx"]
        
        let extensionDeploy = extensionDeploys+chromeExtensionId+".json"
        if !fm.createFileAtPath(extensionDeploy, contents: try! extensionDeployJson.rawData(), attributes: nil) {
            statusLabel.stringValue = "Could not write Google Chrome Extension file."
            return
        }
        
        statusLabel.stringValue = "Google Chrome Extension has been installed.\nPlease restart Google Chrome now."
        
    }


}

