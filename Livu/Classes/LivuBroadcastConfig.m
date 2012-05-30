//
//  LivuConfig.m
//  AlignOfSight
//
//  Created by Steve on 12/26/10.
//  Copyright 2010 Steve McFarlin All rights reserved.
//

#import "LivuBroadcastConfig.h"
#import "LivuBroadcastProfile.h"
#import "SynthesizeSingleton.h"
#import "SMFileUtil.h"
#import "defines.h"





@implementation LivuBroadcastConfig

@synthesize config = configStore, broadcastOptions;

SYNTHESIZE_SINGLETON_FOR_CLASS(LivuBroadcastConfig);

+ (LivuBroadcastConfig *)sharedInstance {
    return sharedLivuBroadcastConfig;
}

/**
     Create and initialize the singleton.
     
     Per apples docs this method gets called once by the objective-c runtime. It will be called the
     first time a message is sent to this class.
 */
+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized) {
        initialized = YES;
        sharedLivuBroadcastConfig = [[LivuBroadcastConfig alloc] init];        
        [LivuBroadcastConfig loadConfig];
    }
}

+ (void) loadConfig {
    NSString *docdir = [SMFileUtil applicationDocumentsDirectory];
    
    NSString *path = [docdir stringByAppendingPathComponent:kLivuBroadcastConfig];
    if([[NSFileManager defaultManager] fileExistsAtPath:path]) 
        sharedLivuBroadcastConfig->configStore = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    
    NSString *name = [kBroadcastOptions substringToIndex:[ kBroadcastOptions rangeOfString:@"."].location ];
    NSString *ext = [kBroadcastOptions substringFromIndex:[ kBroadcastOptions rangeOfString:@"."].location + 1 ];
    NSString *srcpath = [[NSBundle mainBundle] pathForResource:name ofType:ext];  
    sharedLivuBroadcastConfig->broadcastOptions = [[NSArray alloc] initWithContentsOfFile:srcpath];
    
    NSArray *profiles = [LivuBroadcastConfig profileIDs];
    for (NSString *pid in profiles) {
        LivuBroadcastProfile *profile = [LivuBroadcastConfig profileForID:pid];
        if (profile.active) {
            sharedLivuBroadcastConfig->activeProfile = [profile retain];
            break;
        }
    }
}

/*
 Save the config data
 
 This must be called explicitly. There are not deallocation methods for 
 this class.
 */
+ (void) save {
    
    // Make sure we dont save nothing
    if(!sharedLivuBroadcastConfig)
        return;
    
    NSString *path = [[SMFileUtil applicationDocumentsDirectory] stringByAppendingPathComponent:kLivuBroadcastConfig];
    
    //NSLog(path);
    BOOL ret = [sharedLivuBroadcastConfig->configStore writeToFile:path atomically:YES];
    ret = NO;
    //TODO: Do something
    //    if (ret) {
    //        NSLog(@"Wrote Config") ;
    //    }
    //    else {
    //        NSLog(@"Config write failed");
    //    }
}

/**
    Get a value for the key
 */
+ (LivuBroadcastProfile*) profileForID:(NSString*) pid {
    NSMutableDictionary *dict = [sharedLivuBroadcastConfig->configStore valueForKeyPath:pid];
    if (!dict) {
        return nil;
    }
    
	return [[[LivuBroadcastProfile alloc] initWithConfig:dict andID:pid] autorelease];
}

+ (NSArray*) profileIDs {
    return [sharedLivuBroadcastConfig->configStore allKeys];
}

+ (NSDictionary*) profileIdNameMap {
    NSArray *pids = [LivuBroadcastConfig profileIDs];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:[pids count] * 2];
    for (NSString* pid in pids) {
        LivuBroadcastProfile *profile = [LivuBroadcastConfig profileForID:pid];
        [dict setValue:profile.name forKey:profile.pid];
    }
    return [dict autorelease];
}


+ (BOOL) setActiveProfile:(NSString*) pid {
    
    if (pid == nil) {
        return NO;
    }
    
    LivuBroadcastProfile *profile = [LivuBroadcastConfig profileForID:pid];
    
    if (profile == sharedLivuBroadcastConfig->activeProfile) {
        return YES;
    }

    profile.active = YES;
    sharedLivuBroadcastConfig->activeProfile.active = NO ;
    
    [sharedLivuBroadcastConfig->activeProfile release];
    sharedLivuBroadcastConfig->activeProfile = [profile retain];
    
    [self save];
    
    return YES;
}

+ (LivuBroadcastProfile*) activeProfile {
    return sharedLivuBroadcastConfig->activeProfile;
}

+ (void) setProfile:(LivuBroadcastProfile*) profile {
    [sharedLivuBroadcastConfig->configStore setValue:profile.profileConfig forKeyPath:profile.pid];
}


@end
