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
        // Open a connection to the bundled XPC service
        connection = XPCConnection(serviceName: "com.indragie.ExampleXPCService")
        // Unpack and print all strings received from the service.
        connection.inbound
            .map(unpackString)
            .ignoreNil()
            .observeNext {
               print("Received " + $0)
            }
        // Resume the connection, since it was in a suspended state.
        connection.resume()
        // Send all text typed into the text view to the XPC service.
        textView.rac_textSignal()
            .toSignalProducer()
            .map { pack($0 as! String) }
            .flatMapError { _ in SignalProducer<XPCValue, NoError>.empty }
            .start(connection.outbound)
    }
}

