//
//  ConnectionManager.m
//  Focus
//
//  Created by Brad Jasper on 11/24/13.
//
//

#import "ConnectionManager.h"

#import "HelperTool.h"

@implementation ConnectionManager

@synthesize helperToolConnection;

- (void)connectToHelperTool
{
    assert([NSThread isMainThread]);
    if (self.helperToolConnection == nil) {
        self.helperToolConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperToolMachServiceName options:NSXPCConnectionPrivileged];
        self.helperToolConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        self.helperToolConnection.invalidationHandler = ^{
            self.helperToolConnection.invalidationHandler = nil;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.helperToolConnection = nil;
                LogMessageCompat(@"connection invalited");
            }];
        };
#pragma clang diagnostic pop
        [self.helperToolConnection resume];
    }
}

- (void)connectAndExecuteCommandBlock:(void(^)(NSError *))commandBlock
{
    assert([NSThread isMainThread]);
    [self connectToHelperTool];
    commandBlock(nil);
}



@end
