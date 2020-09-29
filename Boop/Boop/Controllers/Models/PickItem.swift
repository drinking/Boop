//
//  PickItem.swift
//  Boop
//
//  Created by drinking on 2020/9/27.
//  Copyright © 2020 OKatBest. All rights reserved.
//

import Foundation

class PickItem: NSObject {
    
    init(title:String,subTitle:String?,extra:String?) {
        self.title = title
        self.extra = extra
        self.subTitle = subTitle
    }
    
    var title:String?
    var subTitle:String?
    var extra:String?
    var picked:Bool = true
}
