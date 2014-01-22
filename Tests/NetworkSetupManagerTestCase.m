//
//  NetworkSetupManagerTestCase.m
//  Focus
//
//  Created by Brad Jasper on 11/26/13.
//
//

#import <XCTest/XCTest.h>
#import "NetworkSetupManager.h"
#import "NSTask+runCommand.h"

@interface NetworkSetupManagerTestCase : XCTestCase

@end

@implementation NetworkSetupManagerTestCase

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testGetNetworkAdapters
{
    NSArray *networkAdapters = [NetworkSetupManager getNetworkAdapters];
    
    LogMessageCompat(@"networkAdapters= %@", networkAdapters);
    
    XCTAssertTrue([networkAdapters count] > 0, @"No network adapters found");
    
    for (NSString *adapter in networkAdapters) {
        XCTAssertTrue(adapter.length > 0, @"adapter name is empty");
    }
}

- (void)testGetAutoProxyURL
{
    XCTAssertNil([NetworkSetupManager getAutoProxyURLForNetworkAdapter:@"asdfasdf"], @"Bogus proxy url isn't null");
    XCTAssertNotNil([NetworkSetupManager getAutoProxyURLForNetworkAdapter:@"Wi-Fi"], @"Wi-Fi proxy URL shouldn't be null");
}

- (void)testSetAutoProxyURL
{
    XCTAssertTrue([NetworkSetupManager setAutoProxyURL:@"http://localhost" forNetworkAdapter:@"Wi-Fi"], @"Can't setup proxy url");
    XCTAssertEqualObjects([NetworkSetupManager getAutoProxyURLForNetworkAdapter:@"Wi-Fi"], @"http://localhost", @"Wifi doesn't match");

    
    XCTAssertTrue([NetworkSetupManager setAutoProxyURL:@"file:///Users/ljksdfs" forNetworkAdapter:@"Wi-Fi"], @"Can't setup proxy url");
    XCTAssertEqualObjects([NetworkSetupManager getAutoProxyURLForNetworkAdapter:@"Wi-Fi"], @"file:///Users/ljksdfs", @"Wifi doesn't match");
}

- (void)testGetCurrentNetworkAdapter
{
    NSString *networkAdapter = [NetworkSetupManager getActiveNetworkAdapter];
    XCTAssertNotNil(networkAdapter, @"Network adapter is nil");
}

- (void)testUnsetAllNetworkAdapters
{
    NSString *proxyURL = @"http://localhost/test_case";
    
    XCTAssertTrue([NetworkSetupManager setAutoProxyURL:proxyURL forNetworkAdapter:@"Wi-Fi"], @"Can't setup proxy url");
    XCTAssertEqualObjects([NetworkSetupManager getAutoProxyURLForNetworkAdapter:@"Wi-Fi"], proxyURL, @"Wifi doesn't match");

    [NetworkSetupManager unsetAutoProxyURLForAllNetworkAdapters:proxyURL];
    
    XCTAssertNotEqualObjects([NetworkSetupManager getAutoProxyURLForNetworkAdapter:@"Wi-Fi"], proxyURL, @"Wifi matches");
}

// Make sure only unset if it's something we've set
- (void)testUnsetAllNetworkAdaptersSoft
{
    NSString *proxyURL = @"http://localhost/test_case";
    
    XCTAssertTrue([NetworkSetupManager setAutoProxyURL:proxyURL forNetworkAdapter:@"Wi-Fi"], @"Can't setup proxy url");
    XCTAssertEqualObjects([NetworkSetupManager getAutoProxyURLForNetworkAdapter:@"Wi-Fi"], proxyURL, @"Wifi doesn't match");
    
    [NetworkSetupManager unsetAutoProxyURLForAllNetworkAdapters:@"http://other.url/test_case"];
    
    XCTAssertEqualObjects([NetworkSetupManager getAutoProxyURLForNetworkAdapter:@"Wi-Fi"], proxyURL, @"Wifi doesn't match");
    
    // Then actually unset it
    [NetworkSetupManager unsetAutoProxyURLForAllNetworkAdapters:proxyURL];
    
    XCTAssertNotEqualObjects([NetworkSetupManager getAutoProxyURLForNetworkAdapter:@"Wi-Fi"], proxyURL, @"Wifi matches");
}

- (void)testProxyURLWithSpaces
{
    NSString *proxyURL = @"/Library/Managed Preferences/Focus/com.apple.networkConnect.plist";
    
    XCTAssertTrue([NetworkSetupManager setAutoProxyURL:proxyURL forNetworkAdapter:@"Wi-Fi"], @"Can't setup proxy url");
    XCTAssertEqualObjects([NetworkSetupManager getAutoProxyURLForNetworkAdapter:@"Wi-Fi"], proxyURL, @"Wifi doesn't match");
}

@end
