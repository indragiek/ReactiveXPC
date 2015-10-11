//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

import Foundation
import ReactiveCocoa

/// Provides a bi-directional communication channel between two processes.
/// This class creates, configures, and exposes a signal-based API for
/// communication between the two processes. Each process has an instance
/// of this class representing the endpoint in the communication channel.
public class XPCConnection: NSObject {
    private let connection: xpc_connection_t
    private let targetQueue = dispatch_queue_create("com.indragie.ReactiveXPC.XPCConnection.TargetQueue", DISPATCH_QUEUE_SERIAL)
    private let (outboundSignal, outboundSink) = Signal<XPCMessage, NoError>.pipe()
    private let (inboundSignal, inboundSink) = Signal<XPCMessage, XPCError>.pipe()
    
    /// `Next` events (signal values) sent to this sink result in an outgoing
    /// message (an XPC object) being queued to be sent over the connection.
    /// This provides a mechanism for unidirectional communication with the
    /// other process, but provides no indication that the message was
    /// successfully delivered. The connection must be resumed (by calling
    /// `resume()`) before any events will be sent over the channel.
    ///
    /// A `Completed` event sent to this sink results in the XPC connection
    /// being closed, if it was open.
    public var outboundMessagesSink: Event<XPCMessage, NoError> -> () {
        return outboundSink
    }
    
    /// Signal of XPC messages received from the other process. If the connection
    /// is invalid, this signal will error immediately after calling `resume()`.
    /// The signal will also error if the connection is interrupted, if the other
    /// process is about to terminate, or if the XPC connection is cancelled via
    /// a call to `cancel()`. The signal never completes.
    ///
    /// Note that this signal does not send messages that were sent as replies
    /// to other messages sent from this connection, only standalone messages.
    public var inboundMessagesSignal: Signal<XPCMessage, XPCError> {
        return inboundSignal
    }
    
    /// The audit session ID of the remote peer at the time the connection was made.
    public var auditSessionIdentifier: au_asid_t {
        var identifier: au_asid_t = 0
        dispatch_sync(targetQueue) {
            identifier = xpc_connection_get_asid(self.connection)
        }
        return identifier
    }
    
    /// The EGID of the remote peer at the time the connection was made.
    public var effectiveGroupIdentifier: gid_t {
        var identifier: gid_t = 0
        dispatch_sync(targetQueue) {
            identifier = xpc_connection_get_egid(self.connection)
        }
        return identifier
    }
    
    /// The EUID of the remote peer at the time the connection was made.
    public var effectiveUserIdentifier: uid_t {
        var identifier: uid_t = 0
        dispatch_sync(targetQueue) {
            identifier = xpc_connection_get_euid(self.connection)
        }
        return identifier
    }
    
    /// The PID of the remote peer.
    // See this documentation for some gotchas when using the PID:
    // https://developer.apple.com/library/prerelease/mac/documentation/System/Reference/XPC_connection_header_reference/index.html#//apple_ref/c/func/xpc_connection_get_pid
    public var processIdentifier: pid_t {
        var identifier: pid_t = 0
        dispatch_sync(targetQueue) {
            identifier = xpc_connection_get_pid(self.connection)
        }
        return identifier
    }
    
    /// The name of the remote service, or `nil` if the connection was obtained
    /// through invocation of another connection's event handler.
    public var serviceName: String? {
        var name: String?
        dispatch_sync(targetQueue) {
            let namePtr = xpc_connection_get_name(self.connection)
            if namePtr != nil {
                name = String.fromCString(namePtr)
            }
        }
        return name
    }
    
    private func commonInit() {
        xpc_connection_set_event_handler(connection) { [weak self] object in
            if let strongSelf = self {
                for error in XPCError.All {
                    if object === RXPCError(error) {
                        sendError(strongSelf.inboundSink, error)
                        return
                    }
                }
                if let deserializedObject = XPCMessage(xpcObject: object) {
                    sendNext(strongSelf.inboundSink, deserializedObject)
                }
            }
        }
        
        outboundSignal.observeNext { [weak self] object in
            if let strongSelf = self {
                dispatch_async(strongSelf.targetQueue) {
                    xpc_connection_send_message(strongSelf.connection, object.toXPCObject())
                }
            }
        }
        outboundSignal.observeCompleted { [weak self] in
            self?.cancel()
        }
    }

    /// Initializes an XPC connection to connect to a LaunchAgent or LaunchDaemon
    /// with a name advertised in a launchd.plist.
    ///
    /// Pass `true` for the `privileged` flag if the connection is being made to a
    /// process that is running in a privileged Mach bootstrap context.
    public init(machServiceName: String, privileged: Bool = false) {
        var flags = XPCConnectionOptions.None.rawValue
        if privileged {
            flags |= XPCConnectionOptions.Privileged.rawValue
        }
        connection = xpc_connection_create_mach_service(machServiceName, targetQueue, flags)
        super.init()
        commonInit()
    }
    
    /// Initializes an XPC connection to an XPC service contained within the
    /// application bundle.
    public init(serviceName: String?) {
        if let serviceName = serviceName {
            connection = xpc_connection_create(serviceName, targetQueue)
        } else {
            connection = xpc_connection_create(nil, targetQueue)
        }
        super.init()
        commonInit()
    }
    
    /// Starts or resumes handling of messages on a connection. All connections
    /// start in a suspended state, so this method must be called after creating
    /// the connection in order to send and receive messages.
    public func resume() {
        dispatch_async(targetQueue) {
            xpc_connection_resume(self.connection)
        }
    }
    
    /// Suspends communications on the connection.
    ///
    /// Suspends and resumes must be balanced.
    public func suspend() {
        dispatch_async(targetQueue) {
            xpc_connection_suspend(self.connection)
        }
    }
    
    /// Asynchronously cancels the connection such that no more messages can be
    /// sent or received.
    ///
    /// All outstanding events will be handled before the connection is cancelled,
    /// at which point the `inboundMessagesSignal` will error with
    /// `XPCError.ConnectionInvalidated`
    public func cancel() {
        dispatch_async(targetQueue) {
            xpc_connection_cancel(self.connection)
        }
    }
}

extension XPCError: ErrorType {}
private extension XPCError {
    static let All = [
        XPCError.ConnectionInterrupted,
        XPCError.ConnectionInvalid,
        XPCError.TerminationImminent
    ]
}
