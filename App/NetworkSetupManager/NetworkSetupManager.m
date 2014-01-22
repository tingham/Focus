//
//  NetworkSetupManager.m
//  Focus
//
//  Created by Brad Jasper on 11/26/13.
//
//

#ifdef DEBUG
#define NETWORKSETUP @"/Users/brad/bin/sudonetworksetup"
//#define NETWORKSETUP @"/usr/sbin/networksetup"
#else
#define NETWORKSETUP @"/usr/sbin/networksetup"
#endif

#import "NetworkSetupManager.h"
#import "NSTask+runCommand.h"

@implementation NetworkSetupManager

+ (NSArray *)getNetworkAdapters
{
    NSString *command = [NSString stringWithFormat:@"%@ -listallnetworkservices", NETWORKSETUP];
    NSString *output = [NSTask runCommand:command];
    NSArray *networkAdapters = [output componentsSeparatedByString:@"\n"];
    
    NSPredicate *validAdapter = [NSPredicate predicateWithFormat:@"SELF.length > 0"];
    
    return [networkAdapters filteredArrayUsingPredicate:validAdapter];
}

+ (NSString *)getActiveNetworkAdapter
{
    NSString *guid = [self getActiveNetworkAdapterGUID];
    
    if (guid == nil) {
        return nil;
    }
    
    NSString *command = [NSString stringWithFormat:@"echo 'open|||get Setup:/Network/Service/%@|||d.show' | tr '|||' '\n' | scutil | grep 'UserDefinedName' | awk -F': ' '{print $2}'", guid];
    NSString *output = [NSTask runCommand:command];
    NSString *cleanedOutput = [output stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return cleanedOutput;
}

+ (NSString *)getActiveNetworkAdapterGUID
{
    NSString *command = @"echo 'open|||get State:/Network/Global/IPv4|||d.show' | tr '|||' '\n' | scutil | grep 'PrimaryService' | awk '{print $3}'";
    NSString *output = [NSTask runCommand:command];
    NSString *cleanedOutput = [output stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    return cleanedOutput;
}

+ (NSString *)getAutoProxyURLForNetworkAdapter:(NSString *)networkAdapter
{
#pragma unused(networkAdapter)
    NSString *command = [NSString stringWithFormat:@"%@ -getautoproxyurl '%@' | head -n1 | awk '{print substr($0, index($0, $2))}'", NETWORKSETUP, networkAdapter];
    NSString *output = [NSTask runCommand:command];
    NSString *cleanedOutput = [output stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // Unknown network adapter
    if ([cleanedOutput rangeOfString:@"Error"].location != NSNotFound) {
        return nil;
    }
    
    return cleanedOutput;
}

+ (bool)setAutoProxyURL:(NSString *)proxyURL forNetworkAdapter:(NSString *)networkAdapter
{
    NSString *command = [NSString stringWithFormat:@"%@ -setautoproxyurl '%@' '%@'", NETWORKSETUP, networkAdapter, proxyURL];
    
    LogMessageCompat(@"command = %@", command);
    
    NSError *error;
    NSString *output = [NSTask runCommand:command error:&error];
    NSString *cleanedOutput = [output stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    // Successfull command returns nothing & 0 success
    return error == nil && cleanedOutput.length == 0;
}

+ (bool)unsetAutoProxyURLforNetworkAdapter:(NSString *)networkAdapter
{
    [NetworkSetupManager setAutoProxyURL:@"none" forNetworkAdapter:networkAdapter];

    NSString *command = [NSString stringWithFormat:@"%@ -setautoproxystate '%@' off", NETWORKSETUP, networkAdapter];
    
    LogMessageCompat(@"command = %@", command);
    
    NSError *error;
    NSString *output = [NSTask runCommand:command error:&error];
    NSString *cleanedOutput = [output stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    // Successfull command returns nothing & 0 success
    return error == nil && cleanedOutput.length == 0;
}

+ (bool)unsetAutoProxyURLForAllNetworkAdapters:(NSString *)proxyURL
{
    bool success = YES;
    
    for (NSString *adapter in [NetworkSetupManager getNetworkAdapters]) {
        NSString *adapterProxyURL = [NetworkSetupManager getAutoProxyURLForNetworkAdapter:adapter];
        if ([adapterProxyURL isEqualToString:proxyURL]) {
            if (![NetworkSetupManager unsetAutoProxyURLforNetworkAdapter:adapter]) {
                success = NO;
            }
        }
    }
    
    
    return success;
}

+ (bool)networkAdapterMatchesAutoProxyURL:(NSString *)proxyURL
{
    for (NSString *adapter in [NetworkSetupManager getNetworkAdapters]) {
        NSString *adapterProxyURL = [NetworkSetupManager getAutoProxyURLForNetworkAdapter:adapter];
        if ([adapterProxyURL isEqualToString:proxyURL]) {
            return YES;
        }
    }
    
    
    return NO;
}

@end
