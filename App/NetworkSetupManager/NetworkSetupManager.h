//
//  NetworkSetupManager.h
//  Focus
//
//  Created by Brad Jasper on 11/26/13.
//
//

#import <Foundation/Foundation.h>

@interface NetworkSetupManager : NSObject

+ (NSArray *)getNetworkAdapters;
+ (NSString *)getActiveNetworkAdapter;
+ (NSString *)getAutoProxyURLForNetworkAdapter:(NSString *)networkAdapter;
+ (bool)setAutoProxyURL:(NSString *)proxyURL forNetworkAdapter:(NSString *)networkAdapter;
+ (bool)unsetAutoProxyURLForAllNetworkAdapters:(NSString *)proxyURL;
+ (bool)networkAdapterMatchesAutoProxyURL:(NSString *)proxyURL;

@end
