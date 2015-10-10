//
//  XPCType.h
//  ReactiveXPC
//
//  Created by Indragie on 10/9/15.
//  Copyright © 2015 Indragie Karunaratne. All rights reserved.
//

#import <Foundation/Foundation.h>

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
    XPCTypeSharedMemory,
    XPCTypeString,
    XPCTypeUInt64,
    XPCTypeUUID
};

xpc_type_t RXPCType(XPCType type);
