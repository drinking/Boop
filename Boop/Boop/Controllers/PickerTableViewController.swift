//
//  PickerTableViewController.swift
//  Boop
//
//  Created by drinking on 2020/9/27.
//  Copyright © 2020 OKatBest. All rights reserved.
//

import Cocoa

class PickerTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var popoverView: PopoverView!
    
    @IBOutlet weak var nextButton: NSButton!
    
    @IBAction func nextButtonAction(_ sender: Any) {
        self.command = self.command?.nextCommand
    }
    
    @IBOutlet weak var prevButton: NSButton!
    
    @IBAction func prevButtonAction(_ sender: Any) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.action =  #selector(onItemClicked)
        
        let next = PickCommand(type:.action, list: [PickItem(title:"Xtem1",extra: nil),
                                                    PickItem(title:"Xtem2",extra: nil),
                                                    PickItem(title:"Xtem3",extra: nil),
                                                    PickItem(title:"Xtem4",extra: nil)],next:nil)
        
        command = PickCommand(type:.picker, list: [PickItem(title: "item1",extra: nil),
                                                   PickItem(title:"item2",extra: nil),
                                                   PickItem(title:"item3",extra: nil),
                                                   PickItem(title:"item4",extra: nil)],next:next)
        
        
    }
    
    var command: PickCommand? {
        didSet {
            tableView.reloadData()
        }
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return command?.list.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if self.command?.type == .some(.picker) {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "pickerCell"), owner: self) as! PickerTableViewCell
            
            guard let item = command?.list[row] else {
                return view
            }
            
            view.titleLabel.stringValue = item.title ?? "Not Title"
            view.checkBox.state = item.picked ? .on : .off
            
            return view
        }else {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "actionCell"), owner: self) as! ActionTableViewCell
            
            guard let item = command?.list[row] else {
                return view
            }
            view.textField?.stringValue = item.title ?? "Not Title"
            return view
        }
        
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 50
    }
        
    @objc private func onItemClicked() {
        if self.tableView.clickedRow > -1 {
            if let item = command?.list[self.tableView.clickedRow] {
                item.picked = !item.picked
                self.tableView.reloadData()
            }
        }
    }
    
}
