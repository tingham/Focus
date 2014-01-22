//
//  FocusHTTProxy.m
//  Focus
//
//  Created by Brad Jasper on 12/2/13.
//
//

#import "FocusHTTProxy.h"
#import "NSTask+runCommand.h"

@interface FocusHTTProxy(Private)
@end

@implementation FocusHTTProxy

- (id)init
{
    self = [super self];
    if (self)
    {
        NSString *proxyPath = [[NSBundle mainBundle] pathForResource:@"FocusBlackholeProxy.py" ofType:nil];
        NSString *templatePath = [[NSBundle mainBundle] pathForResource:@"template.html" ofType:nil];
        
        LogMessageCompat(@"proxyPath = %@", proxyPath);
        
        self.launchPath = @"/usr/bin/python";
        self.startArguments = @[proxyPath, @"--template", templatePath];
    }
    return self;
}

+ (bool)isRunning
{
    NSError *error;
    NSString *output = [NSTask runCommand:@"ps aux | grep FocusBlackholeProxy.py | grep -v grep" error:&error];
    
    if (error != nil) return NO;
    
    NSString *cleanedOutput = [output stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    return cleanedOutput.length > 0;
}

+ (bool)killZombiedProxies
{
    NSError *error;
    [NSTask runCommand:@"ps aux | grep FocusBlackholeProxy | grep -v grep | awk '{print $2}' | xargs kill" error:&error];
    
    return error == nil;
}

@end
