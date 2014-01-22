//
//  NSTask+runCommand.h
//  Focus
//
//  Created by Brad Jasper on 11/24/13.
//
//

#import <Foundation/Foundation.h>

@interface NSTask (runCommand)

+(NSString *)runCommand:(NSString *)commandToRun;
+(NSString *)runCommand:(NSString *)commandToRun error:(NSError **)error;

@end
