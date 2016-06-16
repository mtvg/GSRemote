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
    let chromeExtensionNativeId = "net.mtvg.gsremotehelper"
    let chromeNativeExtensionFilename = "gsremotehelper"
    let chromeBundleId = "com.google.Chrome"
    
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
    @IBOutlet weak var warningView: NSView!
    @IBOutlet weak var uninstallButton: NSButton!
    
    required init?(coder: NSCoder) {
        chromeNativeMessagingFile = chromeNativeMessagingFolder+"/"+chromeExtensionNativeId+".json"
        chromeNativeExtensionFile = chromeNativeMessagingFolder+"/"+chromeNativeExtensionFilename
        chromeExternalExtensionFile = chromeExternalExtensionsFolder+"/"+chromeExtensionId+".json"
        
        super.init(coder: coder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if !isNibInit {
            
            if !chromeIsInstalled() {
                print("Google Chrome is not installed")
                return
            }
            
            do {
                try test2()
                try test1()
            } catch InstallerError.ChromeNotFound {
                print("ChromeNotFound")
            } catch {
                
                print("other error")
            }
            
            /*uninstallButton.focusRingType = .None
            
            if checkChromeIsRunning() {
                killChromeTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(writeFilesOnChromeExit), userInfo: nil, repeats: true)
            }
            //checkExtensionStatus()
            //createNativeHostFile()
            //verifyApplicationLocation()
            */
            
            isNibInit = true
        }
    }
    
    func chromeIsInstalled()->Bool {
        if fm.fileExistsAtPath(InstallerViewController.chromeFolder) && workspace.URLForApplicationWithBundleIdentifier(chromeBundleId) != nil {
            return true
        }
        return false
    }
    
    func test1() throws {
        throw InstallerError.ChromeNotFound
    }
    
    func test2() throws {
        throw InstallerError.OtherError
    }
    
    
    @IBAction func onUninstall(sender: AnyObject) {
       /* _ = try? fm.removeItemAtPath(chromeNativeMessagingFile)
        _ = try? fm.removeItemAtPath(chromeExternalExtensionFile)
        _ = try? fm.removeItemAtPath(chromeNativeExtensionFile)
        
        statusLabel.stringValue = "Chrome Extension Uninstalled.\nMove this app to the Trash, or relaunch to install again."*/
    }
    
    /*
    func writeFilesOnChromeExit() {
        if !checkChromeIsRunning() {
            killChromeTimer?.invalidate()
            print("Chrome is dead")
            createNativeHostFile()
            workspace.openURLs([NSURL(string: "http://ff0000.com")!], withAppBundleIdentifier: "com.google.Chrome", options: .Default, additionalEventParamDescriptor: nil, launchIdentifiers: nil)
        }
    }
    
    func checkChromeIsRunning()->Bool {
        let apps = NSWorkspace.sharedWorkspace().runningApplications
        if apps.contains({$0.bundleIdentifier == "com.google.Chrome"}) {
            return true
        }
        return false
    }
    
    func checkExtensionStatus() {
        if getExtentionPath() == nil {
            print("extension not found")
        }
    }
    
    func getExtentionPath()->String? {
        if fm.fileExistsAtPath(chromeLocalState), let data = NSData(contentsOfFile: chromeLocalState) {
            let json = JSON(data: data)
            if let lastProfile = json["profile"]["last_used"].string {
                let profileExtension = NSHomeDirectory()+"/Library/Application Support/Google/Chrome/"+lastProfile+"/Extensions/"+chromeExtensionId
                if fm.fileExistsAtPath(profileExtension) {
                    return profileExtension
                }
            }
        }
        return nil
    }
    
    func verifyApplicationLocation() {
        let currentFolder = bundle.bundlePath
        if currentFolder.rangeOfString("/Applications")?.startIndex.distanceTo(currentFolder.startIndex) === 0 {
            warningView.hidden = true
        } else {
            warningView.hidden = false
        }
    }
    
    func createNativeHostFile() {
        
        
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
        
        
        if !fm.createFileAtPath(nativeMessagingHost, contents: try! nativeMessagingHostJson.rawData(), attributes: nil) {
            statusLabel.stringValue = "Could not write Google Chrome Extension file."
            return
        }
        
        
        
        if !fm.fileExistsAtPath(extensionDeploys) {
            do {
                try fm.createDirectoryAtPath(extensionDeploys, withIntermediateDirectories: false, attributes: nil)
            } catch {
                statusLabel.stringValue = "Could not locate your Google Chrome personal folder."
                return
            }
        }
        
        
        let extensionDeployJson:JSON = ["external_update_url":"https://clients2.google.com/service/update2/crx"]
        
        
        if !fm.createFileAtPath(extensionDeploy, contents: try! extensionDeployJson.rawData(), attributes: nil) {
            statusLabel.stringValue = "Could not write Google Chrome Extension file."
            return
        }
        
        statusLabel.stringValue = "Google Chrome Extension has been installed.\nPlease restart Google Chrome now."
        
    }
    */
    
}

enum InstallerError:ErrorType {
    case ChromeNotFound, OtherError
}

