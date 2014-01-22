//
//  NSTask+runCommand.m
//  Focus
//
//  Created by Brad Jasper on 11/24/13.
//
//

#import "NSTask+runCommand.h"

@implementation NSTask (runCommand)

+(NSString *)runCommand:(NSString *)commandToRun
{
    NSError *error;
    return [NSTask runCommand:commandToRun error:&error];
}

+(NSString *)runCommand:(NSString *)commandToRun error:(NSError **)error
{
    NSTask *task;
    task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/sh"];
    
    NSArray *arguments = [NSArray arrayWithObjects:
                          @"-c" ,
                          [NSString stringWithFormat:@"%@", commandToRun],
                          nil];
    
//    LogMessageCompat(@"run command: %@",commandToRun);
    [task setArguments: arguments];
    
    NSPipe *pipe;
    pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSFileHandle *file;
    file = [pipe fileHandleForReading];
    
    [task launch];
    [task waitUntilExit];
    
    NSData *data;
    data = [file readDataToEndOfFile];
    
    if (task.terminationStatus != 0) {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"runCommand didn't complete successfully" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"BradJasper.focus" code:101 userInfo:errorDetail];
    }
    
    NSString *output;
    output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return output;
}

@end
