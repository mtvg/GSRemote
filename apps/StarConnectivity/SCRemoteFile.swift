//
//  SCRemoteFile.swift
//  GSRemote
//
//  Created by Niophys on 7/2/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import Foundation

public class SCRemoteFile {
    static public func set(file filename:String, fromPeer peer:SCPeer, withData data:NSData, completion:((String, NSError?)->())?) {
        
    }
    static public func get(file filename:String, fromPeer peer:SCPeer, completion:((String, NSData?, NSError?)->())) {
        
    }
}

extension NSData {
    func MD5() -> NSData {
        let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))!
        CC_MD5(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        return NSData(data: result)
    }
}
