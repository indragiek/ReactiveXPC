//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

import Foundation

/// Types that can be packed into an `XPCMessage` and sent over an XPC
/// connection conform to this protocol.
public protocol XPCPackable {
    func pack() -> XPCMessage
}

/// Packs a serializable value into an XPC message.
public func pack(serializable: XPCPackable) -> XPCMessage {
    return serializable.pack()
}

/// Packs an array of a particular type of serializable values into an XPC
/// message.
public func pack<T: XPCPackable>(array: [T]) -> XPCMessage {
    return XPCMessage.Array(array.map { $0.pack() })
}

/// Packs an array of serializable values into an XPC message.
public func pack(array: [XPCPackable]) -> XPCMessage {
    return XPCMessage.Array(array.map { $0.pack() })
}

/// Packs a dictionary of a particular type of serializable values into an 
/// XPC message.
public func pack<T: XPCPackable>(dictionary: [String: T]) -> XPCMessage {
    return XPCMessage.Dictionary(dictionary.map { $0.pack() })
}

/// Packs a dictionary of serializable values into an XPC message.
public func pack(dictionary: [String: XPCPackable]) -> XPCMessage {
    return XPCMessage.Dictionary(dictionary.map { $0.pack() })
}

/// Unpacks an `Array` value from an XPC message, if it exists.
public func unpackArray(message: XPCMessage) -> [XPCMessage]? {
    if case .Array(let array) = message {
        return array
    }
    return nil
}

/// Unpacks a `Boolean` value from an XPC message, if it exists.
public func unpackBoolean(message: XPCMessage) -> Bool? {
    if case .Boolean(let value) = message {
        return value
    }
    return nil
}

/// Unpacks an `NSData` object from an XPC message, if it exists.
public func unpackData(message: XPCMessage) -> NSData? {
    if case .Data(let data) = message {
        return data
    }
    return nil
}

/// Unpacks an `NSDate` object from an XPC message, if it exists.
public func unpackDate(message: XPCMessage) -> NSDate? {
    if case .Date(let date) = message {
        return date
    }
    return nil
}

/// Unpacks a `Dictionary` value from an XPC message, if it exists.
public func unpackDictionary(message: XPCMessage) -> [String: XPCMessage]? {
    if case .Dictionary(let dict) = message {
        return dict
    }
    return nil
}

/// Unpacks a `Double` value from an XPC message, if it exists.
public func unpackDouble(message: XPCMessage) -> Double? {
    if case .Double(let value) = message {
        return value
    }
    return nil
}

/// Unpacks an `NSFileHandle` object from an XPC message, if it exists.
public func unpackFileHandle(message: XPCMessage) -> NSFileHandle? {
    if case .FileHandle(let handle) = message {
        return handle
    }
    return nil
}

/// Unpacks an `Int64` value from an XPC message, if it exists.
public func unpackInt64(message: XPCMessage) -> Int64? {
    if case .Int64(let value) = message {
        return value
    }
    return nil
}

/// Unpacks a `String` value from an XPC message, if it exists.
public func unpackString(message: XPCMessage) -> String? {
    if case .String(let string) = message {
        return string
    }
    return nil
}


/// Unpacks a `UInt64` value from an XPC message, if it exists.
public func unpackUInt64(message: XPCMessage) -> UInt64? {
    if case .UInt64(let value) = message {
        return value
    }
    return nil
}

/// Unpacks an `NSUUID` object from an XPC message, if it exists.
public func unpackUUID(message: XPCMessage) -> NSUUID? {
    if case .UUID(let UUID) = message {
        return UUID
    }
    return nil
}

private extension Dictionary {
    init(_ elements: [Element]) {
        self.init()
        for (key, value) in elements {
            self[key] = value
        }
    }
    
    func map<MappedValue>(@noescape transform: Value throws -> MappedValue) rethrows -> [Key: MappedValue] {
        return Dictionary<Key, MappedValue>(try map { (key, value) in (key, try transform(value)) })
    }
}


extension XPCMessage: XPCPackable {
    public func pack() -> XPCMessage {
        return self
    }
}

extension Bool: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.Boolean(self)
    }
}

extension NSData: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.Data(self)
    }
}

extension NSDate: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.Date(self)
    }
}

extension Float: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.Double(Double(self))
    }
}

extension Double: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.Double(self)
    }
}

extension NSFileHandle: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.FileHandle(self)
    }
}

extension Int8: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.Int64(Int64(self))
    }
}

extension Int16: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.Int64(Int64(self))
    }
}

extension Int32: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.Int64(Int64(self))
    }
}

extension Int: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.Int64(Int64(self))
    }
}

extension Int64: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.Int64(self)
    }
}

extension String: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.String(self)
    }
}

extension UInt8: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.UInt64(UInt64(self))
    }
}

extension UInt16: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.UInt64(UInt64(self))
    }
}

extension UInt32: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.UInt64(UInt64(self))
    }
}

extension UInt: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.UInt64(UInt64(self))
    }
}

extension UInt64: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.UInt64(self)
    }
}

extension NSUUID: XPCPackable {
    public func pack() -> XPCMessage {
        return XPCMessage.UUID(self)
    }
}
