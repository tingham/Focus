//
//  InstallerManager.m
//  Focus
//
//  Created by Brad Jasper on 11/24/13.
//
//
#import <Cocoa/Cocoa.h>

#import "InstallerManager.h"

#import <ServiceManagement/ServiceManagement.h>

#import "Focus.h"
#import "Common.h"
#import "LaunchAtLoginController.h"
#import "NSTask+runCommand.h"

@interface InstallerManager () {
    AuthorizationRef    _authRef;
}
@end

@implementation InstallerManager

@synthesize authorization;
@synthesize installed;

- (void)run
{
    self.installed = YES;
    
    [self authorize];
    
    if (![self helperToolInstalled]) {
        LogMessageCompat(@"installHelper = %d", [self installHelper]);
    }
}

- (void)uninstall
{
    NSArray *cmds = @[
        @"rm /Library/LaunchDaemons/BradJasper.focus.HelperTool.plist",
        @"rm -rf '/Library/Managed Preferences/Focus'",
        @"security -q authorizationdb remove 'BradJasper.focus.focus'",
        @"security -q authorizationdb remove 'BradJasper.focus.unfocus'",
        @"security -q authorizationdb remove 'BradJasper.focus.uninstall'",
        @"launchctl unload /Library/LaunchDaemons/BradJasper.focus.HelperTool.plist",
        @"rm /Library/PrivilegedHelperTools/BradJasper.focus.HelperTool"
    ];
    
    for (NSString *cmd in cmds) {
        LogMessageCompat(@"Running cmd = %@", cmd);
        [NSTask runCommand:cmd];
    }
    
    [[NSApplication sharedApplication] terminate:nil];
}

- (bool)helperToolInstalled
{
    bool launchd = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/LaunchDaemons/BradJasper.focus.HelperTool.plist"];

    bool helperTool = [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/PrivilegedHelperTools/BradJasper.focus.HelperTool"];
    
    return launchd && helperTool;
}

- (bool)PACDirExists
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];

    BOOL isDir;
    BOOL exists = [fileManager fileExistsAtPath:[Focus getFocusPACDir] isDirectory:&isDir];

    return exists && isDir;
}

// PAC file needs to go  in /Library/Managed Preferences/* so that Safari can access it
- (bool)installPACDirectory
{
    if ([self PACDirExists])
        return YES;
    
    LogMessageCompat(@"PACDirectory doesn't exist, creating it...");
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSError *error;
    bool success = [fileManager createDirectoryAtPath:[Focus getFocusPACDir] withIntermediateDirectories:YES attributes:nil error:&error];
    
    if (error)
    {
        LogMessageCompat(@"Error while installing PAC directory = %@", error);
        [self error:@"There was a problem while creating the required '/Library/Managed Preferences/Focus' directory. Please close the app and try running it again."];
    }
    return success && error == nil;
}

- (void)authorize
{
    OSStatus                    err;
    AuthorizationExternalForm   extForm;

    err = AuthorizationCreate(NULL, NULL, 0, &self->_authRef);
    if (err == errAuthorizationSuccess) {
        err = AuthorizationMakeExternalForm(self->_authRef, &extForm);
    }
    if (err == errAuthorizationSuccess) {
        self.authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
    }
    assert(err == errAuthorizationSuccess);
    
    // If we successfully connected to Authorization Services, add definitions for our default
    // rights (unless they're already in the database).
    
    if (self->_authRef) {
        [Common setupAuthorizationRights:self->_authRef];
    }
}

- (bool)installHelper
{
    Boolean             success;
    CFErrorRef          error;
    
    success = SMJobBless(
                         kSMDomainSystemLaunchd,
                         CFSTR("BradJasper.focus.HelperTool"),
                         self->_authRef,
                         &error
                         );
    if (error) {
        LogMessageCompat(@"An error occured while installing the helper = %@", error);
        self.installed = NO;
        CFRelease(error);
        return NO;
    }
    
    return success;
}

- (void)error:(NSString *)msg
{
    LogMessageCompat(@"ERROR = %@", msg);
    
    NSAlert *alertBox = [[NSAlert alloc] init];
    [alertBox setMessageText:@"An Error Occurred"];
    [alertBox setInformativeText:msg];
    [alertBox addButtonWithTitle:@"Ok"];
    [alertBox runModal];
}

- (bool)installAutoLaunch
{
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    [launchController setLaunchAtLogin:YES];
    return YES;
}

- (bool)uninstallAutoLaunch
{
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    [launchController setLaunchAtLogin:NO];
    return YES;
}

- (bool)willAutoLaunch
{
    LaunchAtLoginController *launchController = [[LaunchAtLoginController alloc] init];
    return [launchController launchAtLogin];
}

@end
