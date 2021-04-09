import SwiftUI
import SavannaKit


struct PickRowViewPreview: SwiftUI.View {
    var body: some SwiftUI.View {
        VStack(alignment:.leading) {
            HStack {
                Image(systemName: "checkmark.square")
                Text("title is a title").font(.system(size: 18))
            }
            Divider()
        }.padding(3)
        .onTapGesture {
            
        }
    }
}

struct ActionRowPreview: SwiftUI.View {
    var body: some SwiftUI.View {
        HStack {
            Text("[1]").font(.system(size: 18)).padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 3))
            VStack(alignment: .leading) {
                Text("this is a title").font(.system(size: 18))
                Text("this is a subtitle").font(.system(size: 15)).padding(1)
                Divider()
            }
        }
        
    }
}


struct PickRow: SwiftUI.View {
    var item: PickItem
    @Binding var picked:Bool
    var body: some SwiftUI.View {
        VStack(alignment:.leading) {
            HStack {
                Image(systemName: (self.picked == true ? "checkmark.square" : "square"))
                Text("\(item.title)").font(.system(size: 18))
            }
            Divider()
        }.padding(3).onTapGesture {
            self.picked = self.picked != true
        }
    }
}

struct ActionRow: SwiftUI.View {
    @State var item: PickItem
    var index:Int
    var body: some SwiftUI.View {
        
        HStack {
            Text("[\(index + 1)]").font(.system(size: 18)).padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 3))
            VStack(alignment: .leading) {
                Text("\(item.title)").font(.system(size: 18))
                Text("\(item.subTitle ?? "")").font(.system(size: 15)).padding(1)
                Divider()
            }
        }
    }
}

typealias RUNFUNC = (Int)->Void

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
    
    var runAction:((Int)->())?
    
    
    var body: some SwiftUI.View {
      VStack {
        
        if let cmd = command {
            if (cmd.type == 0) {
                VStack(alignment:.trailing) {
                    NaviBar()
                    List {
                        ForEach(cmd.list.indices) { i in
                            PickRow(item: cmd.list[i], picked:self.$pickIndex[i])
                        }
                    }
                }
            }else {
                
                List {
                    ForEach(cmd.list.indices) { i in
                        ActionRow(item: cmd.list[i], index:i).onTapGesture {
                            self.runAction?(i)
                        }
                    }
                }
            }
        }
      }.frame(width: 500, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
  }
}


class SwiftUIHostingViewController: NSHostingController<MainView> {
    
    weak var popoverViewController:PopoverViewController?

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
    
    override func viewWillAppear() {
        super.viewWillAppear()
        setupKeyHandlers()
        self.rootView.runAction = self.runAction
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if let e = event {
            NSEvent.removeMonitor(e)
        }
        self.script?.args = nil
//        popoverViewController?.setupKeyHandlers()
        
    }
    
    var event:Any?
    
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
            
            if(theEvent.keyCode >= 18 && theEvent.keyCode <= 26) {
                self.runAction(i: Int(theEvent.keyCode) - 18)
            }
            
            // Return an empty event to avoid the funk sound
            return nil
        }
        
        
        event = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: keyHandler)
        
    }
    
    func runAction(i:Int) {
        
        guard let cmd = self.command else {
            return
        }
        
        
        let pickedList = self.rootView.pickIndex[0...cmd.list.count].enumerated().map { (index,element)  in
            return element == true ? index : -1
        }.filter { (v) -> Bool in
            return v > -1
        }
        let argus = pickedList.reduce("") { (result, v) -> String in
            result + "," + String(v)
        }
        
        self.script?.args =  "\(argus):\(i)"
        _ = self.scriptManager?.runScript(self.script!,into:self.editorView!)
        self.dismiss(nil)
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

}


struct NaviBar: SwiftUI.View {
    var body: some SwiftUI.View {
        HStack {
            SwiftUI.Button("Inverse") {
                print("Button tapped!")
            }
            Spacer()
            Text("Board")
            Spacer()
            SwiftUI.Button("<") {
                print("Button tapped!")
            }
            SwiftUI.Button(">") {
                print("Button tapped!")
            }
        }.padding(10)
    }
}


struct ContentView_Previews: PreviewProvider {
    
    var pickIndex:[Bool] = Array(repeating: true, count: 256)
    
    static var previews: some SwiftUI.View {
        
        VStack(alignment:.trailing) {
            NaviBar()
            List {
                ForEach([1,2,3,4,5], id: \.self) { i in
                    PickRowViewPreview()
                }
            }
        }
        
//        List {
//            ForEach([1,2,3,4,5], id: \.self) { i in
//                ActionRowPreview()
//            }
//        }
    }
}
