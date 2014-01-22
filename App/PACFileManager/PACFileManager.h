//
//  PACFileManager.h
//  Focus
//
//  Created by Brad Jasper on 11/26/13.
//
//

#import <Foundation/Foundation.h>

@interface PACFileManager : NSObject

@property (nonatomic, strong) NSString *proxy;
@property (nonatomic, strong) NSArray *hosts;

- (id)initWithHosts:(NSArray *)hosts;
- (NSString *)output;
- (bool)writeToFile:(NSString *)filePath;

@end
