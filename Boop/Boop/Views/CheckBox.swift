//
//  CheckBox.swift
//  Boop
//
//  Created by drinking on 2020/10/12.
//  Copyright © 2020 OKatBest. All rights reserved.
//

import Cocoa

class CheckBox : NSButton {
    
    var item:PickItem! {
        didSet {
            self.state = item.picked == true ? .on : .off
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        item.picked = item.picked == true ? false : true
    }
}
