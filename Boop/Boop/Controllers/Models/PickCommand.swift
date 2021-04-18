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

struct PickItem: Codable,Identifiable {
    let id = UUID()
    var title:String
    var subTitle:String?
    var extra:String?
    var picked:Bool = true
    
    private enum CodingKeys: String, CodingKey {
        case title
        case subTitle
        case extra
    }
}

struct PickCommand {
    var type:Int
    var list:[PickItem]
    var title:String?
    var nextCommand:Kind?
    var prevCommand:Kind?
    
    indirect enum Kind {
        case command(PickCommand)
        case empty
    }
}

extension PickCommand {
    
    public static func parse(string:String)-> PickCommand? {
        
        let decoder = JSONDecoder()
        if let data = string.data(using: .utf8),
            let command = try? decoder.decode(PickCommand.self, from: data) {
            return command;
        }
        
        return nil
    }
}

extension PickCommand : Codable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case list
        case title
        case nextCommand
        case prevCommand
    }
    
    enum CodableError: Error {
        case decoding(String)
        case encoding(String)
    }
    
    func encode(to encoder: Encoder) throws {
        // do nothing
    }

    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        guard let list = try? container.decode([PickItem].self, forKey: .list),
              let type = try? container.decode(Int.self, forKey: .type) else {
            throw CodableError.decoding("Decoding Error")
        }
        
        self.list = list
        self.type = type
        self.prevCommand = .empty
        
        if let title = try? container.decode(String.self, forKey: .title) {
            self.title = title
        }
        
        if let next = try? container.decode(PickCommand.self, forKey: .nextCommand) {
            self.nextCommand = .command(next)
        }
        
    }
    
}

