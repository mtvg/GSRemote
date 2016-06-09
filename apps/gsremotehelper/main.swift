//
//  main.swift
//  gsremotehelper
//
//  Created by Niophys on 5/31/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation

let stdin = NSFileHandle.fileHandleWithStandardInput()


let bridge = GSChromeBridge()

stdinLoop: while true {
    
    let data = stdin.availableData
    
    var pointerPosition = 0
    var sectionlength:UInt32 = 0
    
    while data.length-pointerPosition > 4 {
        
        data.getBytes(&sectionlength, range: NSMakeRange(pointerPosition, 4))
        pointerPosition += 4
        
        let extractedData = data.subdataWithRange(NSMakeRange(pointerPosition, Int(sectionlength)))
        pointerPosition += Int(sectionlength)
        
        bridge.receivedDataFromChrome(extractedData)
    }
    
}

