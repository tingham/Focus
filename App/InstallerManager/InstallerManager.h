//
//  InstallerManager.h
//  Focus
//
//  Created by Brad Jasper on 11/24/13.
//
//

#import <Foundation/Foundation.h>

@interface InstallerManager : NSObject

@property (atomic, copy,   readwrite) NSData * authorization;
@property (nonatomic, assign) BOOL installed;

- (void)run;
- (void)uninstall;

- (bool)willAutoLaunch;
- (bool)uninstallAutoLaunch;
- (bool)uninstallHelperTool;
- (bool)installAutoLaunch;

- (bool)PACDirExists;
- (bool)installPACDirectory;

@end
