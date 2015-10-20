## ReactiveXPC

This is a work-in-progress experiment in using [ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa) signals as a front end to communication over [XPC Services](https://developer.apple.com/library/mac/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingXPCServices.html).

### Overview

ReactiveXPC uses a sum type ([`XPCValue`](https://github.com/indragiek/ReactiveXPC/blob/master/ReactiveXPC/XPCValue.swift)) to model the various types of values that can be serialized over an XPC connection. At the moment, it supports all of the types supported by the [C XPC Services API](https://developer.apple.com/library/prerelease/mac/documentation/System/Reference/XPCServicesFW/index.html) except for shared memory regions and `IOSurfaceRef`. Convenience functions are provided for unpacking and packing native types (`Bool`, `String`, etc.) to and from `XPCValue`. These functions can be composed nicely using operators like `map`. 

ReactiveXPC provides a front-end to a bidirectional XPC channel using a combination of a signal and a sink. Values put on the sink (`XPCConnection.outbound`) are serialized and sent over the connection, and the signal (`XPCConnection.inbound`) sends incoming values sent by the process at the other end of the connection.

### Example

The provided example application and XPC service do the same task as the XPC service template that Apple provides with Xcode. The application sends text to the XPC service, which uppercases the text and sends it back. The code is concise enough that I can show it right here:

**Application**

```swift
@IBOutlet var textView: NSTextView!
private var connection: XPCConnection!

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
```

**XPC Service**

```swift
// Listen for incoming connections, and subscribe to the `inbound` signal
// to receive strings sent by the app, uppercase them, and send them back.
listen { connection in
    connection.inbound
        .ignoreErrors()
        .map(unpackString)
        .ignoreNil()
        .map { $0.uppercaseString }
        .map(pack)
        .observe(connection.outbound)
    connection.resume()
    return true
}
```

### Getting Started

ReactiveXPC supports [Carthage](https://github.com/Carthage/Carthage). Add this line to your Cartfile:

```
github "indragiek/ReactiveXPC"
```

Or add the Xcode project as a subproject, link `ReactiveXPC.framework`, and add a Copy Files phase to copy the framework to your application bundle's Frameworks folder.

### Contact

* Indragie Karunaratne
* [@indragie](http://twitter.com/indragie)
* [http://indragie.com](http://indragie.com)

### License

ReactiveXPC is licensed under the MIT License. See `LICENSE` for more information.
