//
//  Focus.m
//  Focus
//
//  Created by Brad Jasper on 11/25/13.
//
//

#import "Focus.h"
#import "NetworkSetupManager.h"
#import "PACFileManager.h"

@interface Focus()
@end

@implementation Focus

- (id)initWithHostsFile:(NSString *)filePath PACFile:(NSString *)PACFile
{
    self = [super init];
    if (self) {
        self.focusRCFilePath = filePath;
        self.PACFilePath = PACFile;
        [self parseHostsFile];
    }
    return self;
}

- (id)initWithHosts:(NSArray *)hosts
{
    self = [super init];
    if (self) {
        self.hosts = hosts;
        self.PACFilePath = [Focus getFocusPACPath];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.focusRCFilePath = [Focus getFocusRCPath];
        self.PACFilePath = [Focus getFocusPACPath];
        [self parseHostsFile];
    }
    return self;
}

- (NSString *)PACURI
{
    return [NSString stringWithFormat:@"file://%@", self.PACFilePath];
}

+ (NSString *)getFocusRCPath
{
    return [[NSBundle mainBundle] pathForResource:@"focus" ofType:nil];
}

+ (NSString *)getFocusPACDir
{
    return @"/Library/Managed Preferences/Focus/";
}

+ (NSString *)getFocusPACPath
{
    return [NSString stringWithFormat:@"%@com.apple.networkConnect.plist", [Focus getFocusPACDir]];
}

+ (NSArray *)parseHostsFile:(NSString *)file
{
    
    if (!file) {
        LogMessageCompat(@"Unable to find file to parse hosts");
        return nil;
    }
    
    NSError *error;
    NSString *data = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&error];
    
    NSArray *hosts = [data componentsSeparatedByString:@"\n"];
    
    // Strip out empty lines & comments
    NSPredicate *validHostPredicate = [NSPredicate predicateWithFormat:@"SELF.length > 0 AND not (SELF BEGINSWITH %@)", @"#"];
    
    return [hosts filteredArrayUsingPredicate:validHostPredicate];
}

- (void)parseHostsFile
{
    self.hosts = [Focus parseHostsFile:self.focusRCFilePath];
}

- (bool)focus
{
    // Update host file incase it changed
    
    if (![self writePACFile]) {
        LogMessageCompat(@"Couldn't write PAC file");
        return NO;
    }
    
    if (![self setActiveAdapterPAC]) {
        LogMessageCompat(@"Couldn't set active network adapter PAC");
        return NO;
    }
    
    return YES;
}

- (bool)unfocus
{
    return [NetworkSetupManager unsetAutoProxyURLForAllNetworkAdapters:self.PACURI];
}

- (bool)isFocusing
{
    return [NetworkSetupManager networkAdapterMatchesAutoProxyURL:self.PACURI];
}

- (bool)setActiveAdapterPAC
{
    NSString *networkAdapter = [NetworkSetupManager getActiveNetworkAdapter];
    
    if (!networkAdapter) {
        LogMessageCompat(@"Unable to determine active network adapter");
        return NO;
    }
    
    LogMessageCompat(@"setActiveAdapterPAC = %@", self.PACURI);
    return [NetworkSetupManager setAutoProxyURL:self.PACURI forNetworkAdapter:networkAdapter];
}

- (bool)writePACFile
{
    LogMessageCompat(@"writePacFile = %@", self.PACFilePath);
    PACFileManager *pacFileManager = [[PACFileManager alloc] initWithHosts:self.hosts];
    return [pacFileManager writeToFile:self.PACFilePath];
}

+ (NSArray *)getDefaultHosts
{
    return [Focus parseHostsFile:[Focus getFocusRCPath]];
}

@end
