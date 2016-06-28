//
//  GSConnectionScreen.swift
//  GSRemote
//
//  Created by Niophys on 6/8/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit
import CoreBluetooth
import MultipeerConnectivity

class GSConnectionScreen: UIViewController, MCSessionDelegate {
    
    var scannedPeripheral:GSScannedPeripheral!
    var bluetoothPeripheral:GSBluetoothPeripheral!
    let mpeerid = MCPeerID(displayName: "c")
    var sessionManager:MCSession!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationItem.title = scannedPeripheral.name
        navigationItem.prompt = scannedPeripheral.host
        
        sessionManager = MCSession(peer: mpeerid)
        sessionManager.delegate = self
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        print("didReceiveData")
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        
        print("didChangeState")
        print(state.rawValue)
    }
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
        print("didReceiveStream")
    }
    /*func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        
        print("didReceiveCertificate")
        certificateHandler(true)
    }*/
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
        
        print("didStartReceivingResourceWithName")
    }
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
        
        print("didFinishReceivingResourceWithName")
    }
    
    func onPresentationConnected(central:CBCentral) {
        statusLabel.text = "Connected"
        bluetoothPeripheral.centralConnectionCallback = nil
        bluetoothPeripheral.centralDataCallback = onData
        
        let peerdata = NSKeyedArchiver.archivedDataWithRootObject(mpeerid).base64EncodedStringWithOptions([])
        let slices = peerdata.split(70)
        for i in 0..<slices.count {
            bluetoothPeripheral.sendJSON(["peerdata":slices[i],"s":i+1,"t":slices.count])
        }
        
        //performSegueWithIdentifier("Presentation", sender: self)
    }
    
    func onData(data:NSData, central:CBCentral) {
        let json = JSON(data:data)
        if let multipeer = json["condata"].string {
            
            
            if json["s"].int == 0 {
                constr = ""
            }
            
            constr = constr+multipeer
            
            if let slice = json["s"].int, let total = json["t"].int where slice == total {
                if  let condata = NSData(base64EncodedString: constr, options: []), let peerdata = NSData(base64EncodedString: peerstr, options: []), let peerid = NSKeyedUnarchiver.unarchiveObjectWithData(peerdata) as? MCPeerID {
                    print("connecting now")
                    print(peerid)
                    print(condata)
                    sessionManager.connectPeer(peerid, withNearbyConnectionData: condata)
                }
            }
            
        }
        else if let multipeer = json["peerdata"].string {
            
            
            if json["s"].int == 0 {
                peerstr = ""
            }
            
            peerstr = peerstr+multipeer
            
            
            if let slice = json["s"].int, let total = json["t"].int where slice == total, let peerdata = NSData(base64EncodedString: peerstr, options: []), let peerid = NSKeyedUnarchiver.unarchiveObjectWithData(peerdata) as? MCPeerID {
                    sessionManager.nearbyConnectionDataForPeer(peerid, withCompletionHandler: { (data, error) in
                        print("ConnectionDataForPeer received")
                        let condata = data.base64EncodedStringWithOptions([])
                        let slices = condata.split(70)
                        for i in 0..<slices.count {
                            self.bluetoothPeripheral.sendJSON(["condata":slices[i],"s":i+1,"t":slices.count])
                        }
                    })
            }
            
        }
    }
    
    var peerstr = ""
    var constr = ""
    
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

