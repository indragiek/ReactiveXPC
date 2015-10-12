//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

// Dictionary key used to hold single XPC objects that are wrapped for
// transmission.
private let SingleValueDictionaryKey = "XPCMessage.single"

/// Wraps an XPC object for transport over an XPC connection. XPC connections
/// only support sending dictionaries, so all other object types need to be
/// wrapped in a dictionary before they can be sent.
internal struct XPCMessage {
    /// The value being wrapped.
    let value: XPCValue
    
    /// Initializes using an `XPCValue` instance.
    init(value: XPCValue) {
        self.value = value
    }
    
    /// Initializes using a Darwin `xpc_object_t`, which is then unpacked
    /// into an `XPCValue`
    init?(xpcObject: xpc_object_t) {
        if let value = XPCValue(xpcObject) {
            if case .Dictionary(let dict) = value, let wrappedValue = dict[SingleValueDictionaryKey] {
                self.value = wrappedValue
            } else {
                self.value = value
            }
        } else {
            self.value = .Null
            return nil
        }
    }
    
    /// Converts the receiver to a Darwin XPC dictionary suitable for sending
    /// over an XPC connection.
    func toDarwinXPCMessage() -> xpc_object_t {
        switch value {
        case .Dictionary:
            return value.toDarwinXPCObject()
        default:
            let dictionary = [
                SingleValueDictionaryKey: value
            ]
            return XPCValue.Dictionary(dictionary).toDarwinXPCObject()
        }
    }
}