//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

import Foundation

public typealias ConnectionHandler = XPCConnection -> Bool

private var connections = [XPCConnection]()
private var connectionHandler: ConnectionHandler = { _ in false }
private let connectionsLock: NSLock = {
    let lock = NSLock()
    lock.name = "com.indragie.ReactiveXPC.ActiveConnections"
    return lock
}()

private func lock(lock: NSLocking, @noescape criticalSection: () -> ()) {
    lock.lock()
    criticalSection()
    lock.unlock()
}

/// Listens for incoming XPC connections and allows a handler to accept or
/// reject them.
public func listen(handler: ConnectionHandler) {
    connectionHandler = handler
    // `xpc_main` never returns.
    xpc_main {
        let connection = XPCConnection(connection: $0)
        if connectionHandler(connection) {
            lock(connectionsLock) {
                connections.append(connection)
            }
            connection.inboundMessages.observeError { [weak connection] _ in
                if let connection = connection {
                    lock(connectionsLock) {
                        if let index = connections.indexOf(connection) {
                            connections.removeAtIndex(index)
                        }
                    }
                }
            }
        }
    }
}
