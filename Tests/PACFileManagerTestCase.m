//
//  PACFileManagerTestCase.m
//  Focus
//
//  Created by Brad Jasper on 11/26/13.
//
//

#import <XCTest/XCTest.h>
#import "PACFileManager.h"

@interface PACFileManagerTestCase : XCTestCase

@end

@implementation PACFileManagerTestCase

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testPACFileOutput
{
    NSArray *blockedHosts = [NSArray arrayWithObjects:@"facebook.com", @"twitter.com", nil];
    PACFileManager *pacFileManager = [[PACFileManager alloc] initWithHosts:blockedHosts];
    
    NSString *output = [pacFileManager output];
    LogMessageCompat(@"pacFile = %@", output);
    XCTAssertTrue([output rangeOfString:@"facebook.com"].location != NSNotFound , @"Output string doesn't contain facebook");
    XCTAssertTrue([output rangeOfString:@"twitter.com"].location != NSNotFound , @"Output string doesn't contain Twitter");
    XCTAssertTrue([output rangeOfString:@"localhost:8401"].location != NSNotFound , @"Output string doesn't contain proxy");
    XCTAssertTrue([output rangeOfString:@"DIRECT"].location != NSNotFound , @"Output string doesn't contain DIRECT");
    
    pacFileManager.proxy = @"localhost:8888";
    output = [pacFileManager output];

    XCTAssertTrue([output rangeOfString:@"localhost:8888"].location != NSNotFound , @"Output string doesn't contain proxy");

}

- (void)testPACWriteFile
{
    NSString *filePath = @"/tmp/test_pac_file";
    NSArray *blockedHosts = [NSArray arrayWithObjects:@"facebook.com", @"twitter.com", nil];
    
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    XCTAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:filePath], @"File already exists");
    
    PACFileManager *pacFileManager = [[PACFileManager alloc] initWithHosts:blockedHosts];
    [pacFileManager writeToFile:filePath];
    
    XCTAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:filePath], @"File already exists");
}

@end
