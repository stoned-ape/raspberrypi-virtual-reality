//
//  AppDelegate.swift
//  pi_vr
//
//  Created by Apple1 on 11/14/21.
//

import Cocoa
import SwiftUI
import SceneKit


var leftview=true

struct ContentView:View{
    var body:some View{
        HStack{
            GameViewController()
            GameViewController()
        }.frame(width: CGFloat(sc_width),height: CGFloat(sc_height), alignment: .center)
    }
}


@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    func applicationDidFinishLaunching(_ aNotification: Notification){
        pi_acc=vec3(0,-1,0)
        client()
        let contentView = ContentView()
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: sc_width, height: sc_height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = true
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
}
