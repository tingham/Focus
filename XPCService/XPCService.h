#import <Foundation/Foundation.h>

#define kXPCServiceName @"BradJasper.focus.XPCService"

@protocol XPCServiceProtocol

@required

- (void)installHelperToolWithReply:(void(^)(NSError * error))reply;
- (void)setupAuthorizationRights;
- (void)connectWithEndpointAndAuthorizationReply:(void(^)(NSXPCListenerEndpoint * endpoint, NSData * authorization))reply;
@end

// private
@interface XPCService : NSObject
- (id)init;
- (void)run;
@end
