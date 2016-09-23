//
//  SCDataTransmission.swift
//  GSRemote
//
//  Created by Niophys on 9/22/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation

internal class SCDataTransmission: NSObject {
    
    private let PACKET_SIZE = 20
    private var transmissionQueues = [UInt8:SCTransmissionQueue]()
    private var transmissionQueuesKeys = [UInt8]()
    
    private var lastTransmitedQueue:SCTransmissionQueue?
    private var lastTransmitedLength = 0
    
    var lastPacketErrorCount = 0
    
    func getNextPacket(repeatLastPacket:Bool=false) -> NSData? {
        
        if !repeatLastPacket, let queue = lastTransmitedQueue {
            
            queue.bytesSent += lastTransmitedLength
            
            if queue.bytesSent == queue.dataQueue[0].length {
                queue.dataQueue.removeFirst()
                queue.bytesSent = 0
            }
            
            lastPacketErrorCount = 0
        }
        
        if repeatLastPacket {
            lastPacketErrorCount += 1
        }
        
        for key in transmissionQueuesKeys {
            let queue = transmissionQueues[key]!
            if queue.dataQueue.count > 0 {
                
                // Header byte 4 last bits = priority queue
                var header:UInt8 = key << 4
                let packet = NSMutableData()
                var size = queue.dataQueue[0].length
                if queue.bytesSent == 0 {
                    // Mark packet header as begining of data, add header byte to packet
                    header |= 1
                    packet.appendBytes(&header, length: 1)
                    packet.appendBytes(&size, length: 4)
                } else {
                    // Add header byte to packet
                    packet.appendBytes(&header, length: 1)
                }
                
                let range = NSMakeRange(queue.bytesSent, min(PACKET_SIZE-packet.length, size-queue.bytesSent))
                packet.appendData(queue.dataQueue[0].subdataWithRange(range))
                
                lastTransmitedQueue = queue
                lastTransmitedLength = range.length
                
                return packet
            }
        }
        
        return nil
    }
    
    func addToQueue(data:NSData, onPriorityQueue priorityQueue:UInt8, flushQueue:Bool) {
        if priorityQueue > 0xF {
            return
        }
        
        if transmissionQueues[priorityQueue] == nil {
            transmissionQueues[priorityQueue] = SCTransmissionQueue()
            transmissionQueuesKeys = transmissionQueues.keys.sort(>)
        }
        
        let queue = transmissionQueues[priorityQueue]!
        
        if flushQueue {
            queue.dataQueue.removeAll()
            queue.bytesSent = 0
        }
        
        queue.dataQueue.append(data)
    }
    
    private class SCTransmissionQueue {
        var dataQueue = [NSData]()
        var bytesSent = 0
    }
    
}
