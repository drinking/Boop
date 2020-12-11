import SwiftUI

struct PickRow: View {
    @State var item: PickItem

    var body: some View {
        HStack {
            Image(systemName: (self.item.picked == true ?
                                "checkmark.square" : "square"))
            Text("\(item.title)")
        }.onTapGesture {
            self.item.picked = self.item.picked != true
        }
    }
}

struct ActionRow: View {
    @State var item: PickItem

    var body: some View {
        HStack {
            Text("\(item.title)")
            Text("\(item.subTitle ?? "")")
        }.onTapGesture {
//            script.args = "\(command!.toArgs()):\(self.tableView.clickedRow)"
//            _ = scriptManager?.runScript(script, into: textView)
        }
    }
}


struct SecondView: View {
    var command: PickCommand?
    
    
    var body: some View {
      VStack {
        
        if let cmd = command {
            if (cmd.type == 0) {
                List(cmd.list) { item in
                    PickRow(item: item)
                }
            }else {
                List(cmd.list) { item in
                    ActionRow(item: item).onTapGesture {
//                        self.command?.toArgs() item.
                    }
                }
            }
        }
        
//          Text("Second View").font(.system(size: 36))
//          Text("Loaded by SecondView").font(.system(size: 14))
        
        
        
      }.frame(width: 500, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
  }
}


class SwiftUIHostingViewController: NSHostingController<SecondView> {

    var command: PickCommand? {
        didSet {
//            for i in 1 ... self.command!.list.count {
//                self.command!.list[i-1].id = i
//            }
            self.rootView.command = self.command
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder,rootView: SecondView());
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyHandlers()
    }
    
    func setupKeyHandlers() {
        
        
        // 125 is down arrow
        // 126 is up
        // 53 is escape
        // 36 is enter
        
        var keyHandler: (_: NSEvent) -> NSEvent?
        keyHandler = {
            (_ theEvent: NSEvent) -> NSEvent? in
            if theEvent.keyCode == 53 { // ESCAPE
                self.dismiss(nil)
            }else if theEvent.keyCode == 123 { // left arrow
                self.backward()
            }else if theEvent.keyCode == 124 { // right arrow
                self.forward()
            }
            
            // Return an empty event to avoid the funk sound
            return nil
        }
        
        
        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: keyHandler)
        
    }
    
    func backward() {
        if let c = self.command?.prevCommand {
            switch c {
            case .command(let raw):
                self.command = raw
                break
            default:
                break
            }
        }
    }
    
    func forward() {
        switch self.command?.nextCommand {
            case .command(var raw):
                if let c = self.command {
                    raw.prevCommand = .command(c)
                }
//                for i in 1 ... raw.list.count {
//                    raw.list[i-1].id = i
//                }
                self.command = raw
                break
            default:
                break
        }
    }

    func reverse() {
        guard let list = command?.list else {
            return
        }
        
        command?.list =  list.map { (item) -> PickItem in
            return PickItem(title: item.title,
                               subTitle: item.subTitle,
                               extra: item.extra,
                               picked: item.picked == true ? false : true)
        }
        
    }
    

}
