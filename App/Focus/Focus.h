//
//  Focus.h
//  Focus
//
//  Created by Brad Jasper on 11/25/13.
//
//

#import <Foundation/Foundation.h>

static NSString *kFocusOnNotification = @"kFocusOnNotification";
static NSString *kFocusOffNotification = @"kFocusOffNotification";

@interface Focus : NSObject

@property (nonatomic, strong) NSString *focusRCFilePath;
@property (nonatomic, strong) NSString *PACFilePath;
@property (nonatomic, strong) NSArray *hosts;

+ (NSString *)getFocusRCPath;
+ (NSString *)getFocusPACPath;
+ (NSString *)getFocusPACDir;
+ (NSArray *)getDefaultHosts;

- (id)initWithHosts:(NSArray *)hosts;
- (id)initWithHostsFile:(NSString *)filePath PACFile:(NSString *)PACFile;

- (bool)focus;
- (bool)unfocus;
- (bool)isFocusing;
- (bool)writePACFile;

@end
