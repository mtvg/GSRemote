//
//  SCDataReception.swift
//  GSRemote
//
//  Created by Niophys on 9/22/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation

internal class SCDataReception: NSObject {
    var onData:((NSData, UInt8)->())?
    
    private var receptionQueues = [UInt8:SCReceptionQueue]()
    
    func parsePacket(data:NSData) {
        var packetPointer = 0
        
        var header:UInt8 = 0
        data.getBytes(&header, length: 1)
        packetPointer += 1
        
        let priorityQueue:UInt8 = header >> 4
        if receptionQueues[priorityQueue] == nil {
            receptionQueues[priorityQueue] = SCReceptionQueue()
        }
        
        let queue = receptionQueues[priorityQueue]!
        
        if header&1 == 1 {
            data.getBytes(&queue.totalLength, range: NSMakeRange(packetPointer, 4))
            packetPointer += 4
        }
        
        queue.dataBuffer.appendData(data.subdataWithRange(NSMakeRange(packetPointer, data.length-packetPointer)))
        if queue.dataBuffer.length == queue.totalLength {
            if onData != nil {
                onData!(queue.dataBuffer, priorityQueue)
            }
            
            queue.dataBuffer.length = 0
            queue.totalLength = 0
        }
        
    }
    
    private class SCReceptionQueue {
        var dataBuffer = NSMutableData()
        var totalLength:Int = 0
    }
}
    
