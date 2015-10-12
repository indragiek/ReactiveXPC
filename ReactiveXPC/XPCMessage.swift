//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

import Foundation

public enum XPCMessage {
    case Array([XPCMessage])                    // XPC_TYPE_ARRAY
    case Boolean(Bool)                          // XPC_TYPE_BOOL
    case Data(NSData)                           // XPC_TYPE_DATA
    case Date(NSDate)                           // XPC_TYPE_DATE
    case Dictionary([Swift.String: XPCMessage]) // XPC_TYPE_DICTIONARY
    case Double(Swift.Double)                   // XPC_TYPE_DOUBLE
    case FileHandle(NSFileHandle)               // XPC_TYPE_FD
    case Int64(Swift.Int64)                     // XPC_TYPE_INT64
    case Null                                   // XPC_TYPE_NULL
    case String(Swift.String)                   // XPC_TYPE_STRING
    case UInt64(Swift.UInt64)                   // XPC_TYPE_UINT64
    case UUID(NSUUID)                           // XPC_TYPE_UUID
    
    // This isn't to save a character, it's because using Swift.String
    // directly in the implementations below result in "Type of expression
    // is ambiguous without more context" (Swift 2.0)
    private typealias SwiftString = Swift.String
    
    /// Initializes an `XPCMessage` using an `xpc_object_t`. This initializer
    /// will fail and return `nil` for unsupported XPC object types. See
    /// the list of cases above for the types that are supported.
    public init?(xpcObject: xpc_object_t) {
        let type = xpc_get_type(xpcObject)
        switch type {
        case RXPCType(.Array):
            var array = [XPCMessage]()
            xpc_array_apply(xpcObject) { (_, value) in
                if let message = XPCMessage(xpcObject: value) {
                    array.append(message)
                }
                return true
            }
            self = .Array(array)
        case RXPCType(.Boolean):
            self = .Boolean(xpc_bool_get_value(xpcObject))
        case RXPCType(.Data):
            let data = NSData(bytes: xpc_data_get_bytes_ptr(xpcObject), length: xpc_data_get_length(xpcObject))
            self = XPCMessage.Data(data)
        case RXPCType(.Date):
            let interval = NSTimeInterval(xpc_date_get_value(xpcObject))
            self = .Date(NSDate(timeIntervalSince1970: interval))
        case RXPCType(.Dictionary):
            var dictionary = [SwiftString: XPCMessage]()
            xpc_dictionary_apply(xpcObject) { (key, value) in
                if let message = XPCMessage(xpcObject: value), key = SwiftString.fromCString(key) {
                    dictionary[key] = message
                }
                return true
            }
            self = .Dictionary(dictionary)
        case RXPCType(.Double):
            self = .Double(xpc_double_get_value(xpcObject))
        case RXPCType(.FileHandle):
            let fileHandle = NSFileHandle(fileDescriptor: xpc_fd_dup(xpcObject), closeOnDealloc: true)
            self = .FileHandle(fileHandle)
        case RXPCType(.Int64):
            self = .Int64(xpc_int64_get_value(xpcObject))
        case RXPCType(.Null):
            self = .Null
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
    
    /// Converts the wrapped value to an `xpc_object_t` suitable for sending
    /// over an XPC connection.
    public func toXPCObject() -> xpc_object_t {
        switch self {
        case .Array(let objects):
            let xpcArray = xpc_array_create(nil, 0)
            for (index, value) in objects.enumerate() {
                xpc_array_set_value(xpcArray, index, value.toXPCObject())
            }
            return xpcArray
        case .Boolean(let value):
            return xpc_bool_create(value)
        case .Data(let data):
            return xpc_data_create(data.bytes, data.length)
        case .Date(let date):
            return xpc_date_create(Swift.Int64(date.timeIntervalSince1970))
        case .Dictionary(let dictionary):
            let xpcDictionary = xpc_dictionary_create(nil, nil, 0)
            for (key, value) in dictionary {
                xpc_dictionary_set_value(xpcDictionary, key, value.toXPCObject())
            }
            return xpcDictionary
        case .Double(let value):
            return xpc_double_create(value)
        case .FileHandle(let handle):
            return xpc_fd_create(handle.fileDescriptor)
        case .Int64(let value):
            return xpc_int64_create(value)
        case .Null:
            return xpc_null_create()
        case .String(let string):
            return xpc_string_create(string)
        case .UInt64(let value):
            return xpc_uint64_create(value)
        case .UUID(let UUID):
            var bytes = [UInt8](count: 16, repeatedValue: 0)
            UUID.getUUIDBytes(&bytes)
            return xpc_uuid_create(bytes)
        }
    }
}

extension XPCMessage: CustomStringConvertible {
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
        case .String(let string):
            return "XPCObject.String: \(string)"
        case .UInt64(let value):
            return "XPCObject.UInt64: \(value)"
        case .UUID(let UUID):
            return "XPCObject.UUID: \(UUID)"
        }
    }
}

extension XPCMessage: Equatable {}

public func ==(lhs: XPCMessage, rhs: XPCMessage) -> Bool {
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
