//
//  LivuBroadcastConfigTest.m
//  Livu
//
//  Created by Steve on 3/20/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#include <GHUnitIOS/GHUnit.h>

#include "SMFileUtil.h"
#include "AssetLoader.h"
#include "LivuBroadcastProfile.h"
#include "LivuBroadcastConfig.h"

@interface LivuBroadcastConfigTest : GHTestCase {
    
}
@end


@implementation LivuBroadcastConfigTest

- (BOOL)shouldRunOnMainThread {
    // By default NO, but if you have a UI test or test dependent on running on the main thread return YES
    return NO;
}

- (void)setUpClass {
    // Run at start of all tests in the class
    [AssetLoader overwriteAssets];
    
}

- (void)tearDownClass {
    // Run at end of all tests in the class
}

- (void)setUp {
    // Run before each test method
}

- (void)tearDown {
    // Run after each test method
}  

- (void) testConfig {
    
    LivuBroadcastProfile *profile = [LivuBroadcastConfig activeProfile];
    
    GHAssertNotNil(profile, @"Profile Is NIl");
    GHAssertEqualStrings(profile.name, @"default", @"Name is not default");
    GHAssertTrue(profile.bitrateScalar == 1.0, @"Default Max Bit Rate Scalar NOT 1.0");
    GHAssertTrue(profile.port == 1935, @"Default Port is not 1935");
    GHAssertTrue(profile.frameRate == 30, @"minFrameDuration is not 30");
    
    profile.application = @"/abc/abc";
    
    [LivuBroadcastConfig save];
    [LivuBroadcastConfig loadConfig];
    
    profile = [LivuBroadcastConfig activeProfile];
    
    GHAssertEqualStrings(profile.application, @"/abc/abc", @"application is not /abc/abc/ after save load");
    
    
    //Test a new profile
    LivuBroadcastProfile *testProfile = [[LivuBroadcastProfile alloc] init];
    testProfile.name = @"test";
    testProfile.address = @"localhost";
    testProfile.port = 1000;
    testProfile.application = @"/test/test/";
    testProfile.user = @"steve";
    testProfile.password = @"steve";
    testProfile.broadcastOption = 2;
	testProfile.broadcastType = 1;
    testProfile.frameRate = 30;
    testProfile.bitrateScalar = 0.5;
    
    [LivuBroadcastConfig setProfile:testProfile];
    [LivuBroadcastConfig setActiveProfile:testProfile.pid];
    profile = [LivuBroadcastConfig activeProfile];
    
    GHAssertNotNil(profile, @"New active profile is Nil");
    GHAssertEqualStrings(profile.name, @"test", @"Name is not test");
    GHAssertTrue(profile.bitrateScalar == 0.5, @"Default Max Bit Rate Scalar NOT 1.0");
    GHAssertTrue(profile.port == 1000, @"Default Port is not 1935");
    GHAssertTrue(profile.frameRate == 30, @"minFrameDuration is not 30");
    GHAssertEqualStrings(profile.user, @"steve", @"User is not steve");
    GHAssertEqualStrings(profile.address, @"localhost", @"Address is not localhost");
    GHAssertEqualStrings(profile.application, @"/test/test/", @"application is not /test/test/");
    GHAssertEqualStrings(profile.password, @"steve", @"Password is not steve");
    
}


@end
