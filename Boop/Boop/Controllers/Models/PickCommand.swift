//
//  PickCommand.swift
//  Boop
//
//  Created by drinking on 2020/9/28.
//  Copyright © 2020 OKatBest. All rights reserved.
//

import Foundation

enum PickCommandType {
    case picker
    case action
}

struct PickNextCommandRaw: Codable {
    let type:Int
    let title:String?
    let list:[PickItemRaw]
}

struct PickCommandRaw: Codable {
    let type:Int
    let list:[PickItemRaw]
    let title:String?
    let nextCommand:PickNextCommandRaw?
}

struct PickItemRaw: Codable {
    let title:String
    let subTitle:String?
    let extra:String?
}

class PickCommand: NSObject {
        
    init(type:PickCommandType, list:[PickItem], next:PickCommand?) {
        self.type = type
        self.list = list
        self.nextCommand = next
    }
    
    var type:PickCommandType
    var list:[PickItem]
    var title:String?
    var nextCommand:PickCommand?
    var prevCommand:PickCommand?
    
    public static func parse(string:String)-> PickCommand? {
        
        let decoder = JSONDecoder()
        if let data = string.data(using: .utf8),
            let command = try? decoder.decode(PickCommandRaw.self, from: data) {
            
            let list = command.list.map { (raw) -> PickItem in
                return PickItem(title: raw.title,subTitle: raw.subTitle,extra: raw.extra)
            }
            
            let pickCommand = PickCommand(type: command.type == 0 ? .picker : .action, list: list, next: nil)
            pickCommand.title = command.title;
            
            if let next = command.nextCommand {
                let nextList = next.list.map { (raw) -> PickItem in
                    return PickItem(title: raw.title, subTitle: raw.subTitle, extra: raw.extra)
                }
                pickCommand.nextCommand = PickCommand(type: next.type == 0 ? .picker : .action, list: nextList, next: nil)
                pickCommand.nextCommand?.prevCommand = pickCommand
                pickCommand.nextCommand?.title = next.title
            }
            
            return pickCommand
            
        }
        
        return nil
    }
    
    public func toArgs()->String {
        
        if let prev = self.prevCommand {
            
            if prev.type == .picker {
                let pickedString = prev.list.enumerated().map { (index,item) in
                    return item.picked ? index : -1
                }.filter { v in
                    return v != -1
                }.reduce("") { (result, v) -> String in
                    result + "," + String(v)
                }
                return pickedString
            }
        }
        return ""
    }
    
    
}
