//
//  XPCObject.swift
//  ReactiveXPC
//
//  Created by Indragie on 10/9/15.
//  Copyright © 2015 Indragie Karunaratne. All rights reserved.
//

import Foundation

public enum XPCObject {
    case Array([XPCObject])
    case Boolean(Bool)
    case Data(NSData)
    case Date(NSDate)
    case Dictionary([Swift.String: XPCObject])
    case Double(Swift.Double)
    case FileHandle(NSFileHandle)
    case Int64(Swift.Int64)
    case Null
    case SharedMemory(address: UnsafeMutablePointer<Void>, length: Int)
    case String(Swift.String)
    case UInt64(Swift.UInt64)
    case UUID(NSUUID)
    
    // This isn't to save a character, it's because using Swift.String
    // directly in the implementations below result in "Type of expression
    // is ambiguous without more context"
    private typealias SwiftString = Swift.String
    
    public init?(xpcObject: xpc_object_t) {
        let type = xpc_get_type(xpcObject)
        switch type {
        case RXPCType(.Array):
            var array = [XPCObject]()
            xpc_array_apply(xpcObject) { (_, value) in
                if let object = XPCObject(xpcObject: value) {
                    array.append(object)
                }
                return true
            }
            self = .Array(array)
        case RXPCType(.Boolean):
            self = .Boolean(xpc_bool_get_value(xpcObject))
        case RXPCType(.Data):
            let data = NSData(bytes: xpc_data_get_bytes_ptr(xpcObject), length: xpc_data_get_length(xpcObject))
            self = XPCObject.Data(data)
        case RXPCType(.Date):
            let interval = NSTimeInterval(xpc_date_get_value(xpcObject))
            self = .Date(NSDate(timeIntervalSince1970: interval))
        case RXPCType(.Dictionary):
            var dictionary = [SwiftString: XPCObject]()
            xpc_dictionary_apply(xpcObject) { (key, value) in
                if let object = XPCObject(xpcObject: value), key = SwiftString.fromCString(key) {
                    dictionary[key] = object
                }
                return true
            }
            self = .Dictionary(dictionary)
        case RXPCType(.Double):
            self = .Double(xpc_double_get_value(xpcObject))
        case RXPCType(.FileHandle):
            let fileHandle = NSFileHandle(fileDescriptor: xpc_fd_dup(xpcObject))
            self = .FileHandle(fileHandle)
        case RXPCType(.Int64):
            self = .Int64(xpc_int64_get_value(xpcObject))
        case RXPCType(.Null):
            self = .Null
        case RXPCType(.SharedMemory):
            var address: UnsafeMutablePointer<Void> = nil
            let length = xpc_shmem_map(xpcObject, &address)
            self = .SharedMemory(address: address, length: length)
        case RXPCType(.String):
            if let string = SwiftString.fromCString(xpc_string_get_string_ptr(xpcObject)) {
                self = .String(string)
            } else {
                return nil
            }
        case RXPCType(.UInt64):
            self = .UInt64(xpc_uint64_get_value(xpcObject))
        case RXPCType(.UUID):
            self = .UUID(NSUUID(UUIDBytes: xpc_uuid_get_bytes(xpcObject)))
        default:
            return nil
        }
    }
    
    public func createXPCObject() -> xpc_object_t {
        switch self {
        case .Array(let objects):
            let xpcObjects = objects.map { $0.createXPCObject() }
            var xpcArray = xpc_null_create()
            (xpcObjects as [xpc_object_t?]).withUnsafeBufferPointer {
                xpcArray = xpc_array_create($0.baseAddress, xpcObjects.count)
            }
            xpcObjects.forEach { xpc_release($0) }
            return xpcArray
        case .Boolean(let value):
            return xpc_bool_create(value)
        case .Data(let data):
            return xpc_data_create(data.bytes, data.length)
        case .Date(let date):
            return xpc_date_create(Swift.Int64(date.timeIntervalSince1970))
        case .Dictionary(let dictionary):
            let keys = Swift.Array(dictionary.keys.map { $0.withCString { $0 } })
            let objects = Swift.Array(dictionary.values.map { $0.createXPCObject() })
            var xpcDictionary = xpc_null_create()
            keys.withUnsafeBufferPointer { keysPtr in
                (objects as [xpc_object_t?]).withUnsafeBufferPointer { objectsPtr in
                    xpcDictionary = xpc_dictionary_create(keysPtr.baseAddress, objectsPtr.baseAddress, 0)
                }
            }
            objects.forEach { xpc_release($0) }
            return xpcDictionary
        case .Double(let value):
            return xpc_double_create(value)
        case .FileHandle(let handle):
            return xpc_fd_create(handle.fileDescriptor)
        case .Int64(let value):
            return xpc_int64_create(value)
        case .Null:
            return xpc_null_create()
        case .SharedMemory(let address, let length):
            return xpc_shmem_create(address, length)
        case .String(let string):
            var xpcObject = xpc_null_create()
            string.withCString {
                xpcObject = xpc_string_create($0)
            }
            return xpcObject
        case .UInt64(let value):
            return xpc_uint64_create(value)
        case .UUID(let UUID):
            var bytes = [UInt8](count: 16, repeatedValue: 0)
            UUID.getUUIDBytes(&bytes)
            return xpc_uuid_create(bytes)
        }
    }
}

extension XPCObject: CustomStringConvertible {
    public var description: Swift.String {
        switch self {
        case .Array(let array):
            return "XPCObject.Array: \(array)"
        case .Boolean(let value):
            return "XPCObject.Boolean: \(value)"
        case .Data(let data):
            return "XPCObject.Data: \(data)"
        case .Date(let date):
            return "XPCObject.Date: \(date)"
        case .Dictionary(let dictionary):
            return "XPCObject.Dictionary: \(dictionary)"
        case .Double(let value):
            return "XPCObject.Double: \(value)"
        case .FileHandle(let handle):
            return "XPCObject.FileHandle: \(handle)"
        case .Int64(let value):
            return "XPCObject.Int64: \(value)"
        case .Null:
            return "XPCObject.Null"
        case .SharedMemory(let address, let length):
            return "XPCObject.SharedMemory: (address: \(address), length: \(length))"
        case .String(let string):
            return "XPCObject.String: \(string)"
        case .UInt64(let value):
            return "XPCObject.UInt64: \(value)"
        case .UUID(let UUID):
            return "XPCObject.UUID: \(UUID)"
        }
    }
}

extension XPCObject: Equatable {}

public func ==(lhs: XPCObject, rhs: XPCObject) -> Bool {
    switch (lhs, rhs) {
    case (.Array(let lhsArray), .Array(let rhsArray)):
        return lhsArray == rhsArray
    case (.Boolean(let lhsValue), .Boolean(let rhsValue)):
        return lhsValue == rhsValue
    case (.Data(let lhsData), .Data(let rhsData)):
        return lhsData == rhsData
    case (.Date(let lhsDate), .Date(let rhsDate)):
        return lhsDate == rhsDate
    case (.Dictionary(let lhsDictionary), .Dictionary(let rhsDictionary)):
        return lhsDictionary == rhsDictionary
    case (.Double(let lhsValue), .Double(let rhsValue)):
        return lhsValue == rhsValue
    case (.FileHandle(let lhsHandle), .FileHandle(let rhsHandle)):
        var lhsStat = stat()
        if (fstat(lhsHandle.fileDescriptor, &lhsStat) < 0) {
            return false
        }
        var rhsStat = stat()
        if (fstat(rhsHandle.fileDescriptor, &rhsStat) < 0) {
            return false
        }
        return (lhsStat.st_dev == rhsStat.st_dev) && (lhsStat.st_ino == rhsStat.st_ino)
    case (.Int64(let lhsValue), .Int64(let rhsValue)):
        return lhsValue == rhsValue
    case (.Null, .Null):
        return true
    case (.SharedMemory(let lhsAddress, let lhsLength), .SharedMemory(let rhsAddress, let rhsLength)):
        return (lhsAddress == rhsAddress) && (lhsLength == rhsLength)
    case (.String(let lhsString), .String(let rhsString)):
        return lhsString == rhsString
    case (.UInt64(let lhsValue), .UInt64(let rhsValue)):
        return lhsValue == rhsValue
    case (.UUID(let lhsUUID), .UUID(let rhsUUID)):
        return lhsUUID == rhsUUID
    default:
        return false
    }
}
