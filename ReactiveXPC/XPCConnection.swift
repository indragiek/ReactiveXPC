//
//  XPCConnection.swift
//  ReactiveXPC
//
//  Created by Indragie on 10/10/15.
//  Copyright © 2015 Indragie Karunaratne. All rights reserved.
//

import Foundation
import ReactiveCocoa

public class XPCConnection: NSObject {
    private let connection: xpc_connection_t
    private let targetQueue = dispatch_queue_create("com.indragie.ReactiveXPC.XPCConnection.TargetQueue", DISPATCH_QUEUE_SERIAL)
    private let (outboundSignal, outboundSink) = Signal<XPCObject, NoError>.pipe()
    private let (inboundSignal, inboundSink) = Signal<XPCObject, XPCError>.pipe()
    
    public var outboundMessagesSink: Event<XPCObject, NoError> -> () {
        return outboundSink
    }
    
    public var inboundMessagesSignal: Signal<XPCObject, XPCError> {
        return inboundSignal
    }
    
    public var auditSessionIdentifier: au_asid_t {
        var identifier: au_asid_t = 0
        dispatch_sync(targetQueue) {
            identifier = xpc_connection_get_asid(self.connection)
        }
        return identifier
    }
    
    public var effectiveGroupIdentifier: gid_t {
        var identifier: gid_t = 0
        dispatch_sync(targetQueue) {
            identifier = xpc_connection_get_egid(self.connection)
        }
        return identifier
    }
    
    public var effectiveUserIdentifier: uid_t {
        var identifier: uid_t = 0
        dispatch_sync(targetQueue) {
            identifier = xpc_connection_get_euid(self.connection)
        }
        return identifier
    }
    
    public var processIdentifier: pid_t {
        var identifier: pid_t = 0
        dispatch_sync(targetQueue) {
            identifier = xpc_connection_get_pid(self.connection)
        }
        return identifier
    }
    
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
                if let deserializedObject = XPCObject(xpcObject: object) {
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

    public init(machServiceName: String, privileged: Bool = false) {
        var flags = XPCConnectionOptions.None.rawValue
        if privileged {
            flags |= XPCConnectionOptions.Privileged.rawValue
        }
        connection = xpc_connection_create_mach_service(machServiceName, targetQueue, flags)
        super.init()
        commonInit()
    }
    
    public init(serviceName: String?) {
        if let serviceName = serviceName {
            connection = xpc_connection_create(serviceName, targetQueue)
        } else {
            connection = xpc_connection_create(nil, targetQueue)
        }
        super.init()
        commonInit()
    }
    
    public func resume() {
        dispatch_async(targetQueue) {
            xpc_connection_resume(self.connection)
        }
    }
    
    public func suspend() {
        dispatch_async(targetQueue) {
            xpc_connection_suspend(self.connection)
        }
    }
    
    public func cancel() {
        dispatch_async(targetQueue) {
            xpc_connection_cancel(self.connection)
            sendCompleted(self.inboundSink)
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
