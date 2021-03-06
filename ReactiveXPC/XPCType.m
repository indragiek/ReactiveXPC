//  Copyright © 2015 Indragie Karunaratne. All rights reserved.

#import "XPCType.h"
#import <xpc/xpc.h>

xpc_type_t RXPCType(XPCType type) {
    switch (type) {
        case XPCTypeNull:
            return XPC_TYPE_NULL;
        case XPCTypeArray:
            return XPC_TYPE_ARRAY;
        case XPCTypeBoolean:
            return XPC_TYPE_BOOL;
        case XPCTypeData:
            return XPC_TYPE_DATA;
        case XPCTypeDate:
            return XPC_TYPE_DATE;
        case XPCTypeDictionary:
            return XPC_TYPE_DICTIONARY;
        case XPCTypeDouble:
            return XPC_TYPE_DOUBLE;
        case XPCTypeFileHandle:
            return XPC_TYPE_FD;
        case XPCTypeInt64:
            return XPC_TYPE_INT64;
        case XPCTypeString:
            return XPC_TYPE_STRING;
        case XPCTypeUInt64:
            return XPC_TYPE_UINT64;
        case XPCTypeUUID:
            return XPC_TYPE_UUID;
    }
    return NULL;
}

xpc_object_t RXPCError(XPCError error) {
    switch (error) {
        case XPCErrorNone:
            return NULL;
        case XPCErrorConnectionInterrupted:
            return XPC_ERROR_CONNECTION_INTERRUPTED;
        case XPCErrorConnectionInvalid:
            return XPC_ERROR_CONNECTION_INVALID;
        case XPCErrorTerminationImminent:
            return XPC_ERROR_TERMINATION_IMMINENT;
    }
    return NULL;
}
