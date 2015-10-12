//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

import Foundation

/// Types that can be packed into an `XPCValue` and sent over an XPC
/// connection conform to this protocol.
public protocol XPCPackable {
    func pack() -> XPCValue
}

/// Packs a serializable value into an XPC value.
public func pack(serializable: XPCPackable) -> XPCValue {
    return serializable.pack()
}

/// Packs an array of a particular type of serializable values into an XPC
/// value.
public func pack<T: XPCPackable>(array: [T]) -> XPCValue {
    return XPCValue.Array(array.map { $0.pack() })
}

/// Packs an array of serializable values into an XPC value.
public func pack(array: [XPCPackable]) -> XPCValue {
    return XPCValue.Array(array.map { $0.pack() })
}

/// Packs a dictionary of a particular type of serializable values into an 
/// XPC value.
public func pack<T: XPCPackable>(dictionary: [String: T]) -> XPCValue {
    return XPCValue.Dictionary(dictionary.map { $0.pack() })
}

/// Packs a dictionary of serializable values into an XPC value.
public func pack(dictionary: [String: XPCPackable]) -> XPCValue {
    return XPCValue.Dictionary(dictionary.map { $0.pack() })
}

/// Unpacks an `Array` value from an XPC value, if it exists.
public func unpackArray(object: XPCValue) -> [XPCValue]? {
    if case .Array(let array) = object {
        return array
    }
    return nil
}

/// Unpacks a `Boolean` value from an XPC value, if it exists.
public func unpackBoolean(object: XPCValue) -> Bool? {
    if case .Boolean(let value) = object {
        return value
    }
    return nil
}

/// Unpacks an `NSData` object from an XPC value, if it exists.
public func unpackData(object: XPCValue) -> NSData? {
    if case .Data(let data) = object {
        return data
    }
    return nil
}

/// Unpacks an `NSDate` object from an XPC value, if it exists.
public func unpackDate(object: XPCValue) -> NSDate? {
    if case .Date(let date) = object {
        return date
    }
    return nil
}

/// Unpacks a `Dictionary` value from an XPC value, if it exists.
public func unpackDictionary(object: XPCValue) -> [String: XPCValue]? {
    if case .Dictionary(let dict) = object {
        return dict
    }
    return nil
}

/// Unpacks a `Double` value from an XPC value, if it exists.
public func unpackDouble(object: XPCValue) -> Double? {
    if case .Double(let value) = object {
        return value
    }
    return nil
}

/// Unpacks an `NSFileHandle` object from an XPC value, if it exists.
public func unpackFileHandle(object: XPCValue) -> NSFileHandle? {
    if case .FileHandle(let handle) = object {
        return handle
    }
    return nil
}

/// Unpacks an `Int64` value from an XPC value, if it exists.
public func unpackInt64(object: XPCValue) -> Int64? {
    if case .Int64(let value) = object {
        return value
    }
    return nil
}

/// Unpacks a `String` value from an XPC value, if it exists.
public func unpackString(object: XPCValue) -> String? {
    if case .String(let string) = object {
        return string
    }
    return nil
}


/// Unpacks a `UInt64` value from an XPC value, if it exists.
public func unpackUInt64(object: XPCValue) -> UInt64? {
    if case .UInt64(let value) = object {
        return value
    }
    return nil
}

/// Unpacks an `NSUUID` object from an XPC value, if it exists.
public func unpackUUID(object: XPCValue) -> NSUUID? {
    if case .UUID(let UUID) = object {
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


extension XPCValue: XPCPackable {
    public func pack() -> XPCValue {
        return self
    }
}

extension Bool: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.Boolean(self)
    }
}

extension NSData: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.Data(self)
    }
}

extension NSDate: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.Date(self)
    }
}

extension Float: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.Double(Double(self))
    }
}

extension Double: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.Double(self)
    }
}

extension NSFileHandle: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.FileHandle(self)
    }
}

extension Int8: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.Int64(Int64(self))
    }
}

extension Int16: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.Int64(Int64(self))
    }
}

extension Int32: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.Int64(Int64(self))
    }
}

extension Int: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.Int64(Int64(self))
    }
}

extension Int64: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.Int64(self)
    }
}

extension String: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.String(self)
    }
}

extension UInt8: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.UInt64(UInt64(self))
    }
}

extension UInt16: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.UInt64(UInt64(self))
    }
}

extension UInt32: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.UInt64(UInt64(self))
    }
}

extension UInt: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.UInt64(UInt64(self))
    }
}

extension UInt64: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.UInt64(self)
    }
}

extension NSUUID: XPCPackable {
    public func pack() -> XPCValue {
        return XPCValue.UUID(self)
    }
}
