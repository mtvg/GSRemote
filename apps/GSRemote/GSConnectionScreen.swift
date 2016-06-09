//
//  GSConnectionScreen.swift
//  GSRemote
//
//  Created by Niophys on 6/8/16.
//  Copyright © 2016 MTVG. All rights reserved.
//

import UIKit

class GSConnectionScreen: UIViewController {
    
    var connectingPeripheral:GSPeripheral?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = connectingPeripheral?.name
        navigationItem.prompt = connectingPeripheral?.host
    }

}
