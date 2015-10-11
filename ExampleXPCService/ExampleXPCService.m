//
//  ExampleXPCService.m
//  ExampleXPCService
//
//  Created by Indragie on 10/10/15.
//  Copyright © 2015 Indragie Karunaratne. All rights reserved.
//

#import "ExampleXPCService.h"

@implementation ExampleXPCService

// This implements the example protocol. Replace the body of this class with the implementation of this service's protocol.
- (void)upperCaseString:(NSString *)aString withReply:(void (^)(NSString *))reply {
    NSString *response = [aString uppercaseString];
    reply(response);
}

@end
