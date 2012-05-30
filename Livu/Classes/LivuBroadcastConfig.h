//
//  LivuConfig.h
//  AlignOfSight
//
//  Created by Steve on 12/26/10.
//  Copyright 2010 Steve McFarlin All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LivuBroadcastProfile.h"
@class LivuBroadcastProfile;

@interface LivuBroadcastConfig : NSObject {
    NSMutableDictionary *configStore;
    NSArray             *broadcastOptions;
    LivuBroadcastProfile *activeProfile;
}
@property (nonatomic, readonly) NSMutableDictionary *config;
@property (nonatomic, readonly) NSArray *broadcastOptions;

/*!
    The only instance of the config class.
 */
+ (LivuBroadcastConfig *)sharedInstance;

+ (NSArray*) profileIDs;

/*!
 @abstract Return a Id to Name map
 @discussion
 
    The dictionary contains all the unique IDs for the
    profile names.
     
 */
+ (NSDictionary*) profileIdNameMap;

/*!
 @abstract Return the active profile
 @result The active profile
 */
+ (LivuBroadcastProfile*) activeProfile;

/*!
 @abstract Set the active profile
 @param pid The profile ID
 @result YES is successful NO if not.
 */
+ (BOOL) setActiveProfile:(NSString*) pid;

/*!
 @abstract Set the profile.
 @discussion This updates the profile if it exists, otherwize it creates it in the config.
 @param profile 
 
 */
+ (void) setProfile:(LivuBroadcastProfile*) profile;

/*!
 @abstract Get a profile for the given ID
 @param pid The profile ID
 @result The broadcast profile or nil if it does not exist
 */
+ (LivuBroadcastProfile*) profileForID:(NSString*) pid;


+ (void) save;

+ (void) loadConfig;

@end
