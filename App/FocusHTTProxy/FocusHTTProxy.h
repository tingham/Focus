//
//  FocusHTTProxy.h
//  Focus
//
//  Created by Brad Jasper on 12/2/13.
//
//

#import <Foundation/Foundation.h>
#import "FFYDaemonController.h"

@interface FocusHTTProxy : FFYDaemonController

+ (bool)isRunning;
+ (bool)killZombiedProxies;

@end
