import SwiftUI
import SavannaKit

final class ModelData: ObservableObject {
    @Published var list: [PickItem] = []
    @Published var type : Int = 0
}

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
                Image(systemName: (picked == true ? "checkmark.square" : "square"))
                Text("\(item.title)").font(.system(size: 18))
            }
            Divider()
        }.padding(3).onTapGesture {
            picked.toggle()
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

struct MainView: SwiftUI.View {
    
    @EnvironmentObject var command:ModelData
    var script:Script?
    var runAction:((Int)->())
    
    var body: some SwiftUI.View {
      VStack {
            if (command.type == 0) {
                VStack(alignment:.trailing) {
                    NaviBar()
                    List(command.list.indices) { i in
                        PickRow(item: command.list[i], picked:$command.list[i].picked)
                    }
                }
            }else {
                List {
                    ForEach(command.list.indices) { i in
                        ActionRow(item: command.list[i], index:i).onTapGesture {
                            self.runAction(i)
                        }
                    }
                }
            }
      }.frame(width: 500, height: 300, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
  }

}


class SwiftUIHostingViewController: NSHostingController<AnyView> {
    
    weak var popoverViewController:PopoverViewController?
    
    var data:ModelData = ModelData()

    var command: PickCommand? {
        didSet {
            data.list = command!.list
            data.type = command!.type
            self.rootView = AnyView(MainView(runAction: { (cmd) in
                self.script?.args =  "\(self.args):\(cmd)"
                _ = self.scriptManager?.runScript(self.script!,into:self.editorView!)
                self.dismiss(nil)
            }).environmentObject(data))
        }
    }
    
    var args:String {
        
        var command:PickCommand = self.command!
        var loop = true
        while loop {
            if let c = command.prevCommand {
                switch c {
                case .command(let raw):
                    command = raw
                    break
                default:
                    loop = false
                    break
                }
            }
        }
        
        let pickedList = command.list.enumerated().map { (index,element)  in
            return element.picked == true ? index : -1
        }.filter { (v) -> Bool in
            return v > -1
        }
        let args = pickedList.reduce("") { (result, v) -> String in
            result + "," + String(v)
        }
        return args
    }

    var scriptManager: ScriptManager?
    var editorView: SyntaxTextView?
    var script:Script?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder,rootView: AnyView(MainView(runAction: { (Int) in }).environmentObject(ModelData())));
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        setupKeyHandlers()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        if let e = event {
            NSEvent.removeMonitor(e)
        }
        self.script?.args = nil
        popoverViewController?.setupKeyHandlers()
        
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
//                self.runAction(Int(theEvent.keyCode) - 18)
            }
            
            // Return an empty event to avoid the funk sound
            return nil
        }
        
        
        event = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: keyHandler)
        
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
                if let _ = self.command {
                    self.command?.list = data.list
                    raw.prevCommand = .command(self.command!)
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
