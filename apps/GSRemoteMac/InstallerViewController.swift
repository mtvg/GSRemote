//
//  ViewController.swift
//  GSRemoteMac
//
//  Created by Mathieu Vignau on 6/14/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Cocoa

class InstallerViewController: NSViewController {
    
    let fm = NSFileManager.defaultManager()
    let bundle = NSBundle.mainBundle()
    let workspace = NSWorkspace.sharedWorkspace()
    
    let chromeExtensionId = "bejldbalomejcoebpmifodlkokjckbbo"
    let chromeNativeExtensionId = "net.mtvg.gsremotehelper"
    let chromeNativeExtensionDescription = "Google Slides Remote Helper"
    let chromeNativeExtensionFilename = "gsremotehelper"
    let chromeBundleId = "com.google.Chrome"
    let installedURL = NSURL(string: "https://client-projects.com/_transfer/redx/gsremote/install.html#")!
    
    static let chromeFolder = NSHomeDirectory()+"/Library/Application Support/Google/Chrome"
    let chromeLocalStateFile = chromeFolder+"/Local State"
    let chromeNativeMessagingFolder = chromeFolder+"/NativeMessagingHosts"
    let chromeExternalExtensionsFolder = chromeFolder+"/External Extensions"
    let chromeNativeMessagingFile:String
    let chromeNativeExtensionFile:String
    let chromeExternalExtensionFile:String
    
    var isNibInit = false
    var killChromeTimer:NSTimer?
    
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var descriptionTextField: NSTextField!
    @IBOutlet weak var warningView: NSView!
    @IBOutlet weak var uninstallButton: NSButton!
    @IBOutlet weak var installButton: NSButton!
    @IBOutlet weak var buttonView: NSView!
    @IBOutlet weak var waitingIndicator: NSProgressIndicator!
    
    required init?(coder: NSCoder) {
        chromeNativeMessagingFile = chromeNativeMessagingFolder+"/"+chromeNativeExtensionId+".json"
        chromeNativeExtensionFile = chromeNativeMessagingFolder+"/"+chromeNativeExtensionFilename
        chromeExternalExtensionFile = chromeExternalExtensionsFolder+"/"+chromeExtensionId+".json"
        
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if !isNibInit {
            
            NSApplication.sharedApplication().activateIgnoringOtherApps(true)
            
            installButton.focusRingType = .None
            uninstallButton.focusRingType = .None
            
            if !chromeIsInstalled() {
                statusLabel.stringValue = "Chrome Not Installed"
                descriptionTextField.stringValue = "Please install Google Chrome before installing this extension."
                installButton.enabled = false
                uninstallButton.enabled = false
                return
            }
            
            isNibInit = true
        }
    }
    
    func chromeIsInstalled()->Bool {
        if fm.fileExistsAtPath(InstallerViewController.chromeFolder) && workspace.URLForApplicationWithBundleIdentifier(chromeBundleId) != nil {
            return true
        }
        return false
    }
    
    func chromeIsRunning()->Bool {
        let apps = NSWorkspace.sharedWorkspace().runningApplications
        if apps.contains({$0.bundleIdentifier == chromeBundleId}) {
            return true
        }
        return false
    }
    
    @IBAction func onInstall(sender: AnyObject) {
        
        installButton.enabled = false
        uninstallButton.enabled = false
        
        statusLabel.stringValue = "Installing"
        
        if chromeIsRunning() {
            waitingIndicator.startAnimation(self)
            descriptionTextField.stringValue = "Quit Google Chrome now, it will automatically relaunch when the installation is complete."
            killChromeTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(installExtension), userInfo: nil, repeats: true)
        } else {
            installExtension()
        }
        
    }
    
    func installExtension() {
        if chromeIsRunning() {
            return
        }
        
        killChromeTimer?.invalidate()
        waitingIndicator.stopAnimation(self)
        descriptionTextField.stringValue = "Now installing the extension..."
        
        do {
            try fm.removeItemAtPath(chromeNativeMessagingFile)
            try fm.removeItemAtPath(chromeExternalExtensionFile)
            try fm.removeItemAtPath(chromeNativeExtensionFile)
        } catch {
            
        }
        
        if !createNativeHostFile() {
            statusLabel.stringValue = "Error"
        } else {
            workspace.openURLs([installedURL], withAppBundleIdentifier: chromeBundleId, options: .Default, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
            NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(terminateInstaller), userInfo: nil, repeats: false)
        }
        
    }
    
    func terminateInstaller() {
        NSApplication.sharedApplication().terminate(self)
    }
    
    @IBAction func onUninstall(sender: AnyObject) {
        
        installButton.enabled = false
        uninstallButton.enabled = false
        
        statusLabel.stringValue = "Uninstalling"
        
        if chromeIsRunning() {
            waitingIndicator.startAnimation(self)
            descriptionTextField.stringValue = "Quit Google Chrome now to delete the extension files."
            killChromeTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(uninstallExtension), userInfo: nil, repeats: true)
        } else {
            uninstallExtension()
        }
    }
    
    func uninstallExtension() {
        if chromeIsRunning() {
            return
        }
        
        killChromeTimer?.invalidate()
        waitingIndicator.stopAnimation(self)
        descriptionTextField.stringValue = "Now uninstalling the extension..."
        
        do {
            try fm.removeItemAtPath(chromeNativeMessagingFile)
            try fm.removeItemAtPath(chromeExternalExtensionFile)
            try fm.removeItemAtPath(chromeNativeExtensionFile)
        } catch {
            statusLabel.stringValue = "Error"
            descriptionTextField.stringValue = "An error occured while deleting the extension files. The extension might have already been uninstalled."
            return
        }
        
        statusLabel.stringValue = "Uninstalled"
        descriptionTextField.stringValue = "The extension files have been removed. If the extension is still visible in Chrome, you can manually remove it from Chrome."
        
    }
    
    func createNativeHostFile() -> Bool {
        
        
        if !fm.fileExistsAtPath(chromeNativeMessagingFolder) {
            do {
                try fm.createDirectoryAtPath(chromeNativeMessagingFolder, withIntermediateDirectories: false, attributes: nil)
            } catch {
                descriptionTextField.stringValue = "Could not locate your Google Chrome personal folder."
                return false
            }
        }
        
        do {
            try fm.copyItemAtPath(bundle.pathForResource(chromeNativeExtensionFilename, ofType: nil)!, toPath: chromeNativeExtensionFile)
        } catch {
            descriptionTextField.stringValue = "Could not write Native Extension file."
            return false
        }
        
        let nativeMessagingHostJson:JSON = [
            "allowed_origins":["chrome-extension://"+chromeExtensionId+"/"],
            "description": chromeNativeExtensionDescription,
            "name": chromeNativeExtensionId,
            "path": chromeNativeExtensionFile,
            "type": "stdio"]
        
        if !fm.createFileAtPath(chromeNativeMessagingFile, contents: try! nativeMessagingHostJson.rawData(), attributes: nil) {
            descriptionTextField.stringValue = "Could not write Native Extension file."
            return false
        }
        
        
        
        if !fm.fileExistsAtPath(chromeExternalExtensionsFolder) {
            do {
                try fm.createDirectoryAtPath(chromeExternalExtensionsFolder, withIntermediateDirectories: false, attributes: nil)
            } catch {
                descriptionTextField.stringValue = "Could not locate your Google Chrome personal folder."
                return false
            }
        }
        
        
        let extensionDeployJson:JSON = ["external_update_url":"https://clients2.google.com/service/update2/crx"]
        
        
        if !fm.createFileAtPath(chromeExternalExtensionFile, contents: try! extensionDeployJson.rawData(), attributes: nil) {
            descriptionTextField.stringValue = "Could not write Google Chrome Extension file."
            return false
        }
        
        return true
        
    }
 
    
}


