//
//  ExampleXPCService.h
//  ExampleXPCService
//
//  Created by Indragie on 10/10/15.
//  Copyright © 2015 Indragie Karunaratne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExampleXPCServiceProtocol.h"

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface ExampleXPCService : NSObject <ExampleXPCServiceProtocol>
@end
