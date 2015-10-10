//
//  XPCType.h
//  ReactiveXPC
//
//  Created by Indragie on 10/9/15.
//  Copyright © 2015 Indragie Karunaratne. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(uint64_t, XPCConnectionOptions) {
    XPCConnectionOptionsNone = 0,
    XPCConnectionOptionsPrivileged = XPC_CONNECTION_MACH_SERVICE_PRIVILEGED,
    XPCConnectionOptionsListener = XPC_CONNECTION_MACH_SERVICE_LISTENER
};

typedef NS_ENUM(NSInteger, XPCType) {
    XPCTypeNull = 0,
    XPCTypeArray,
    XPCTypeBoolean,
    XPCTypeData,
    XPCTypeDate,
    XPCTypeDictionary,
    XPCTypeDouble,
    XPCTypeFileHandle,
    XPCTypeInt64,
    XPCTypeString,
    XPCTypeUInt64,
    XPCTypeUUID
};

xpc_type_t RXPCType(XPCType type);

typedef NS_ENUM(NSInteger, XPCError) {
    XPCErrorNone = 0,
    XPCErrorConnectionInterrupted,
    XPCErrorConnectionInvalid,
    XPCErrorTerminationImminent
};

xpc_object_t RXPCError(XPCError error);
