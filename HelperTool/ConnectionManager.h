//
//  ConnectionManager.h
//  Focus
//
//  Created by Brad Jasper on 11/24/13.
//
//

#import <Foundation/Foundation.h>

@interface ConnectionManager : NSObject

@property (atomic, strong, readwrite) NSXPCConnection *helperToolConnection;

- (void)connectAndExecuteCommandBlock:(void(^)(NSError *))commandBlock;
- (void)connectToHelperTool;

@end
