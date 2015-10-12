//
//  AppDelegate.swift
//  ExampleApp
//
//  Created by Indragie on 10/10/15.
//  Copyright © 2015 Indragie Karunaratne. All rights reserved.
//

import Cocoa
import ReactiveXPC
import ReactiveCocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    @IBOutlet var textView: NSTextView!
    var connection: XPCConnection!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        connection = XPCConnection(serviceName: "com.indragie.ExampleXPCService")
        connection.inbound
            .map(unpackString)
            .ignoreNil()
            .observeNext {
               print("Received " + $0)
            }
        connection.resume()
        textView.rac_textSignal()
            .toSignalProducer()
            .map { pack($0 as! String) }
            .flatMapError { _ in SignalProducer<XPCValue, NoError>.empty }
            .start(connection.outbound)
    }
}

