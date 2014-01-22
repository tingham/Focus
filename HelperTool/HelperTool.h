
#import <Foundation/Foundation.h>

// kHelperToolMachServiceName is the Mach service name of the helper tool.  Note that the value 
// here has to match the value in the MachServices dictionary in "HelperTool-Launchd.plist".

#define kHelperToolMachServiceName @"BradJasper.focus.HelperTool"

// HelperToolProtocol is the NSXPCConnection-based protocol implemented by the helper tool 
// and called by the app.

@protocol HelperToolProtocol

@required

- (void)connectWithEndpointReply:(void(^)(NSXPCListenerEndpoint * endpoint))reply;
- (void)focus:(NSData *)authData blockedHosts:(NSArray *)hosts withReply:(void(^)(NSError * error))reply;
- (void)unfocus:(NSData *)authData withReply:(void(^)(NSError * error))reply;
- (void)uninstall:(NSData *)authData withReply:(void(^)(NSError * error))reply;

@end

// private
@interface HelperTool : NSObject
- (id)init;
- (void)run;
@end
