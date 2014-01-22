
#import "HelperTool.h"

#import "Common.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
#include "NSTask+runCommand.h"
#include "Focus.h"
#include "InstallerManager.h"

@interface HelperTool () <NSXPCListenerDelegate, HelperToolProtocol>

@property (atomic, strong, readwrite) NSXPCListener *    listener;

@end

@implementation HelperTool

- (id)init
{
    self = [super init];
    if (self != nil) {
        // Set up our XPC listener to handle requests on our Mach service.
        self->_listener = [[NSXPCListener alloc] initWithMachServiceName:kHelperToolMachServiceName];
        self->_listener.delegate = self;
    }
    return self;
}

- (void)run
{
    // Tell the XPC listener to start processing requests.

    [self.listener resume];
    
    // Run the run loop forever.
    
    [[NSRunLoop currentRunLoop] run];
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection
    // Called by our XPC listener when a new connection comes in.  We configure the connection
    // with our protocol and ourselves as the main object.
{
    assert(listener == self.listener);
    #pragma unused(listener)
    assert(newConnection != nil);

    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(HelperToolProtocol)];
    newConnection.exportedObject = self;
    [newConnection resume];
    
    return YES;
}

- (NSError *)checkAuthorization:(NSData *)authData command:(SEL)command
{
    #pragma unused(authData)
    NSError *                   error;
    OSStatus                    err;
    OSStatus                    junk;
    AuthorizationRef            authRef;
    
    assert(command != nil);
    
    authRef = NULL;

    // First check that authData looks reasonable.
    
    error = nil;
    if ( (authData == nil) || ([authData length] != sizeof(AuthorizationExternalForm)) ) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil];
    }
    
    // Create an authorization ref from that the external form data contained within.
    
    if (error == nil) {
        err = AuthorizationCreateFromExternalForm([authData bytes], &authRef);
        
        // Authorize the right associated with the command.
        
        if (err == errAuthorizationSuccess) {
            AuthorizationItem   oneRight = { NULL, 0, NULL, 0 };
            AuthorizationRights rights   = { 1, &oneRight };

            oneRight.name = [[Common authorizationRightForCommand:command] UTF8String];
            assert(oneRight.name != NULL);
            
            err = AuthorizationCopyRights(
                authRef,
                &rights,
                NULL,
                kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed,
                NULL
            );
        }
        if (err != errAuthorizationSuccess) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
        }
    }

    if (authRef != NULL) {
        junk = AuthorizationFree(authRef, 0);
        assert(junk == errAuthorizationSuccess);
    }

    return error;
}


#pragma mark * HelperToolProtocol implementation

- (void)connectWithEndpointReply:(void (^)(NSXPCListenerEndpoint *))reply
{
    reply([self.listener endpoint]);
}

- (void)focus:(NSData *)authData blockedHosts:(NSArray *)hosts withReply:(void(^)(NSError * error))reply
{
    LogMessageCompat(@"Helper: focusing");
    
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error == nil) {
        
        InstallerManager *installerManager = [[InstallerManager alloc] init];
        if (![installerManager PACDirExists]) {
            [installerManager installPACDirectory];
        }
        
        Focus *focus = [[Focus alloc] initWithHosts:hosts];
        [focus focus];
    } else {
        LogMessageCompat(@"Helper error while focusing = %@", error);
    }
    
    reply(error);
}

- (void)unfocus:(NSData *)authData withReply:(void(^)(NSError * error))reply
{
    LogMessageCompat(@"Helper: unfocusing");
    
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error == nil) {
        Focus *focus = [[Focus alloc] init];
        [focus unfocus];
    }
    
    reply(error);
}

- (void)uninstall:(NSData *)authData withReply:(void(^)(NSError * error))reply
{
    LogMessageCompat(@"Helper: uninstalling");
    
    NSError *error = [self checkAuthorization:authData command:_cmd];
    if (error == nil) {
        LogMessageCompat(@"Doing it");
        InstallerManager *installerManager = [[InstallerManager alloc] init];
        [installerManager uninstall];
    }
    
    reply(error);
}

@end
