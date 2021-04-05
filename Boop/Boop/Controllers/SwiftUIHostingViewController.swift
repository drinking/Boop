import SwiftUI
import SavannaKit

struct PickRow: SwiftUI.View {
    var item: PickItem
    @Binding var picked:Bool
    var body: some SwiftUI.View {
        HStack {
            Image(systemName: (self.picked == true ? "checkmark.square" : "square"))
            Text("\(item.title)")
        }.onTapGesture {
            self.picked = self.picked != true
        }
    }
}

struct ActionRow: SwiftUI.View {
    @State var item: PickItem

    var body: some SwiftUI.View {
        HStack {
            Text("\(item.title)")
            Text("\(item.subTitle ?? "")")
        }
    }
}


struct MainView: SwiftUI.View {
    
    @State var pickIndex:[Bool] = Array(repeating: true, count: 256)
    var command: PickCommand? {
        willSet {
            // todo if command.list count exceed 256 breaks
        }
    }
    
    var script:Script?
    var textView:SavannaKit.SyntaxTextView?
    var scriptManager: ScriptManager?
    
    var body: some SwiftUI.View {
      VStack {
        
        if let cmd = command {
            if (cmd.type == 0) {
                List {
                    ForEach(cmd.list.indices) { i in
                        PickRow(item: cmd.list[i], picked:self.$pickIndex[i])
                    }
                }
            }else {
                
                List {
                    ForEach(cmd.list.indices) { i in
                        ActionRow(item: cmd.list[i]).onTapGesture {
                            
                            let pickedList = pickIndex[0...cmd.list.count].enumerated().map { (index,element)  in
                                return element == true ? index : -1
                            }.filter { (v) -> Bool in
                                return v > -1
                            }
                            
                            let argus = pickedList.reduce("") { (result, v) -> String in
                                result + "," + String(v)
                            }
                            
                            self.script?.args =  "\(argus):\(i)"
                            _ = self.scriptManager?.runScript(self.script!,into:self.textView!)
                        }
                    }
                }
            }
        }
      }.frame(width: 500, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
  }
}


class SwiftUIHostingViewController: NSHostingController<MainView> {

    var command: PickCommand? {
        didSet {
            self.rootView.command = command
        }
    }
    
    var scriptManager: ScriptManager? {
        didSet {
            self.rootView.scriptManager = scriptManager
        }
    }
    var editorView: SyntaxTextView? {
        didSet {
            self.rootView.textView = editorView
        }
    }
    
    var script:Script? {
        didSet {
            self.rootView.script = script
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder,rootView: MainView());
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyHandlers()
    }
    
    func setupKeyHandlers() {

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
