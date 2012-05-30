//
//  LivuBroadcastProfileTest.m
//  Livu
//
//  Created by Steve on 3/20/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import "LivuBroadcastProfileTest.h"
#import "LivuBroadcastProfile.h"

@implementation LivuBroadcastProfileTest

- (void)setUp
{
    [super setUp];
   
    //Build profile
    NSMutableDictionary *network = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"localhost",@"address",[NSNumber numberWithInt:1935], @"port", @"/live/livu/", @"application", @"livu", @"user", @"password", @"pass", nil];
    NSMutableDictionary *av = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kBroadcastTypeAudioOnly],@"broadcastType", [NSNumber numberWithInt:30], @"videoMinFrameDuration", [NSNumber numberWithFloat:1.0], @"videoMaxBitrateScalar", nil];
    
    profile_data = [[NSMutableDictionary dictionaryWithObjectsAndKeys:@"default", @"name", [NSNumber numberWithBool:NO], @"active", network, @"network", av, @"av", nil] retain];
    
    STAssertNotNil(profile_data, @"Profile creation failed");
}

- (void)tearDown {
    // Tear-down code here.
    [profile_data release];
    [super tearDown];
}

- (void) setTest:(LivuBroadcastProfile*) profile {
    
    profile.active = YES;
    STAssertTrue(profile.active == YES, @"Profile active is not true");
    
    profile.address = @"addr";
    STAssertTrue([profile.address compare:@"addr"] == NSOrderedSame, @"Profile Address is not equal");
    
    profile.port = 10;
    STAssertTrue(profile.port == 10, @"Profile port is not equal");
    
    profile.application = @"app";
    STAssertTrue([profile.application compare:@"app"] == NSOrderedSame, @"Profile application is not equal");
    
    profile.user = @"usr";
    STAssertTrue([profile.user compare:@"usr"] == NSOrderedSame, @"Profile user is not equal");
    
    profile.password = @"pass";
    STAssertTrue([profile.password compare:@"pass"] == NSOrderedSame, @"Profile pass is not equal");
    
    profile.broadcastType = kBroadcastOptionLow;
    STAssertTrue(profile.broadcastType == kBroadcastOptionLow, @"Profile type is not equal");
    
    profile.frameRate = 10;
    STAssertTrue(profile.frameRate == 10, @"Profile minFrameDuration is not equal");
    
    profile.bitrateScalar = 0.5;
    STAssertTrue(profile.bitrateScalar == 0.5, @"Profile maxBitrateScalar is not equal");
    
}

- (void)testProfile {
    NSString *profileName = @"Test Profile";
    
    LivuBroadcastProfile *profile = [[LivuBroadcastProfile alloc] initWithConfig:profile_data];
    NSLog(@"PID: %@", profile.pid);
    //Test profile
    profile.name = profileName;
    
    STAssertTrue(profile.active == NO, @"Profile active is not NO");
    
    STAssertNotNil(profile.name, @"Profile Name is Nil");
    STAssertTrue([profile.name compare:profileName] == NSOrderedSame, @"Profile Name is not equal");
    
    STAssertNotNil(profile.address, @"Profile addres is Nil");
    STAssertTrue([profile.address compare:@"localhost"] == NSOrderedSame, @"Profile Address is not equal");
    
    STAssertTrue(profile.port == 1935, @"Profile port is not equal");
    
    STAssertNotNil(profile.application, @"Profile application is Nil");
    STAssertTrue([profile.application compare:@"/live/livu/"] == NSOrderedSame, @"Profile application is not equal");
    
    STAssertNotNil(profile.user, @"Profile user is Nil");
    STAssertTrue([profile.user compare:@"livu"] == NSOrderedSame, @"Profile user is not equal");
    
    STAssertNotNil(profile.password, @"Profile user is Nil");
    STAssertTrue([profile.password compare:@"password"] == NSOrderedSame, @"Profile pass is not equal");
    
   
    STAssertTrue(profile.broadcastType == kBroadcastTypeAudioOnly, @"Profile type is not equal");
    
   
    STAssertTrue(profile.frameRate == 30, @"Profile minFrameDuration is not equal");
    
   
    STAssertTrue(profile.bitrateScalar == 1.0, @"Profile maxBitrateScalar is not equal");
    
    [self setTest:profile];
    
    [profile release];
}

- (void) testProfileCreation {
    LivuBroadcastProfile *profile = [[LivuBroadcastProfile alloc] init];
    
    profile.name = @"test";
    STAssertNotNil(profile.name, @"Profile Name is Nil");
    STAssertTrue([profile.name compare:@"test"] == NSOrderedSame, @"Profile Name is not equal");

    [self setTest:profile];

}

@end




