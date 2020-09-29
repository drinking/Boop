//
//  PickerTableViewController.swift
//  Boop
//
//  Created by drinking on 2020/9/27.
//  Copyright © 2020 OKatBest. All rights reserved.
//

import Cocoa
import SavannaKit

class PickerTableViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    weak var editorView: SyntaxTextView?
    var script:Script?
    var scriptManager:ScriptManager?
    
    @IBOutlet weak var overlayView: OverlayView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var popoverView: PopoverView!
    @IBOutlet weak var titleView:NSTextField!
    @IBOutlet weak var nextButton: NSButton!
    
    @IBAction func nextButtonAction(_ sender: Any) {
        self.command = self.command?.nextCommand
    }
    
    @IBOutlet weak var prevButton: NSButton!
    
    @IBAction func prevButtonAction(_ sender: Any) {
        if(self.command?.prevCommand != nil) {
            self.command = self.command?.prevCommand
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.action =  #selector(onItemClicked)
        
    }
    
    var command: PickCommand? {
        didSet {
            tableView.reloadData()
            self.prevButton.isEnabled = self.command?.prevCommand != nil
            self.nextButton.isEnabled = self.command?.nextCommand != nil
            self.titleView.stringValue = self.command?.title ?? "Picker"
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
            view .subTitleLabel.stringValue = item.subTitle ?? ""
            view.checkBox.state = item.picked ? .on : .off
            
            return view
        }else {
            let view = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "actionCell"), owner: self) as! ActionTableViewCell
            
            guard let item = command?.list[row] else {
                return view
            }
            view.textField?.stringValue = item.title ?? "Not Title"
            view.subTitle.stringValue = item.subTitle ?? ""
            return view
        }
        
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 50
    }
        
    @objc private func onItemClicked() {
        
        
        if self.tableView.clickedRow > -1 &&
            command?.type == .some(.picker) {
            if let item = command?.list[self.tableView.clickedRow] {
                item.picked = !item.picked
                self.tableView.reloadData()
            }
        }
        
        if command?.type == .some(.action) {
            
            guard let script = self.script, let textView = self.editorView else {
                self.popoverView.hide()
                return
            }
            
            script.args = "\(command!.toArgs()):\(self.tableView.clickedRow)"
            _ = scriptManager?.runScript(script, into: textView)
            hide()
            
        }
        
    }
    
    func hide() {
        self.popoverView.hide()
        self.overlayView.hide()
        self.editorView = nil
        self.script?.args = nil
        self.script = nil
        self.scriptManager = nil
        self.command = nil
    }
    
}
