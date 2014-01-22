//
//  Focus_Tests.m
//  Focus Tests
//
//  Created by Brad Jasper on 11/25/13.
//
//

#import <XCTest/XCTest.h>
#import "Focus.h"
#import "NetworkSetupManager.h"

@interface FocusTests : XCTestCase
@end

@implementation FocusTests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testFocusInitToSaneParams
{
    Focus *focus = [[Focus alloc] initWithHostsFile:@"/tmp/empty_focus" PACFile:@"/tmp/empty_focus.pac"];
    XCTAssertEqualObjects(focus.focusRCFilePath, @"/tmp/empty_focus", @"Path's aren't empty");
}

- (void)testFocusReadHostFromFile
{
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/basic_focus" contents:[@"facebook.com\ntwitter.com\n\n\n# commented out\nreddit.com" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    
    Focus *focus = [[Focus alloc] initWithHostsFile:@"/tmp/basic_focus" PACFile:@"/tmp/empty_focus.pac"];
    [focus focus];
    NSArray *testHosts = @[@"facebook.com", @"twitter.com", @"reddit.com"];
    XCTAssertEqualObjects(focus.hosts, testHosts, @"Hosts don't match");
    [focus unfocus];
}


- (void)testFocus
{
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/basic_focus" contents:[@"facebook.com\ntwitter.com" dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];

    Focus *focus = [[Focus alloc] initWithHostsFile:@"/tmp/basic_focus" PACFile:@"/tmp/basic_focus.pac"];
    NSArray *testHosts = @[@"facebook.com", @"twitter.com"];

    XCTAssertTrue([focus focus], @"focus didn't succeed");
    XCTAssertEqualObjects(focus.hosts, testHosts, @"Hosts don't match");
    
     // This is wrong, it's testing the implementation, but I can't find
     // a better way to validate the PAC file is working (network libraries don't use it)
     NSString *adapter = [NetworkSetupManager getActiveNetworkAdapter];
     NSString *currPacFile = [NetworkSetupManager getAutoProxyURLForNetworkAdapter:adapter];
     XCTAssertEqualObjects(currPacFile, @"file:///tmp/basic_focus.pac", @"Pac files aren't equal - %@", currPacFile);
     
     XCTAssertTrue([focus unfocus], @"Unfocus didn't succeed");
     NSString *newPacFile = [NetworkSetupManager getAutoProxyURLForNetworkAdapter:adapter];
     XCTAssertNotEqualObjects(currPacFile, newPacFile, @"Pac files should be diff");
}

- (void)testFocusInitWithHosts
{
    Focus *focus = [[Focus alloc] initWithHosts:@[@"facebook.com", @"twitter.com"]];
    focus.PACFilePath = @"/tmp/basic_focus.pac";
    
    NSArray *testHosts = @[@"facebook.com", @"twitter.com"];
    
    XCTAssertTrue([focus focus], @"focus didn't succeed");
    XCTAssertEqualObjects(focus.hosts, testHosts, @"Hosts don't match");
    
    // This is wrong, it's testing the implementation, but I can't find
    // a better way to validate the PAC file is working (network libraries don't use it)
    NSString *adapter = [NetworkSetupManager getActiveNetworkAdapter];
    NSString *currPacFile = [NetworkSetupManager getAutoProxyURLForNetworkAdapter:adapter];
    XCTAssertEqualObjects(currPacFile, @"file:///tmp/basic_focus.pac", @"Pac files aren't equal - %@", currPacFile);
    
    XCTAssertTrue([focus unfocus], @"Unfocus didn't succeed");
    NSString *newPacFile = [NetworkSetupManager getAutoProxyURLForNetworkAdapter:adapter];
    XCTAssertNotEqualObjects(currPacFile, newPacFile, @"Pac files should be diff");
    
}
@end
