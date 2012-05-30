//
//  LivuBroadcastProfile.m
//  Livu
//
//  Created by Steve on 3/17/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import "LivuBroadcastProfile.h"



@implementation LivuBroadcastProfile

@synthesize profileConfig;
@dynamic pid, name, address, port, application, user, password, broadcastType, bitrateScalar, frameRate, active, useTCP, audioOnly;
@dynamic broadcastWidth, broadcastHeight, autoBitrateAdjust, autoRestart, broadcastOption;

- (id) init {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], kBroadcastProfileActive, [NSMutableDictionary dictionary],kNetworkSettings, [NSMutableDictionary dictionary], kAVSettings, nil];
    
    return [self initWithConfig:dict];
    //return 
}


- (id) initWithConfig:(NSMutableDictionary*) config {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef pid = CFUUIDCreateString(kCFAllocatorDefault,uuid);
    
    self = [self initWithConfig:config andID:(NSString*)pid];
    
    CFRelease(uuid);
    CFRelease(pid);

    return self;
}

- (id) initWithConfig:(NSMutableDictionary*) config andID:(NSString*) pid {
    self = [super init];
    if (self != nil) {
        profileConfig = [config retain];
        [profileConfig setValue:(NSString*)pid forKey:kBroadcastProfileID];
    }
    return self;
}

- (void) dealloc {
    [profileConfig release];
}


- (BOOL) audioOnly {
    if (self.broadcastType == 0) {
        return YES;
    }
    return NO;
}

- (NSString*) pid {
    return [profileConfig valueForKeyPath:kBroadcastProfileID];
}

- (NSString*) name {
    return [profileConfig valueForKeyPath:kBroadcastProfileName];
}

- (void) setName:(NSString *)name {
    [profileConfig setValue:name forKeyPath:kBroadcastProfileName];
}

- (BOOL) active {
    return [[profileConfig valueForKeyPath:kBroadcastProfileActive] boolValue];
}

- (void) setActive:(BOOL)val {
    [profileConfig setValue:[NSNumber numberWithBool:val] forKeyPath:kBroadcastProfileActive];
}

- (NSString*) address {
    return [profileConfig valueForKeyPath:kServerAddr];
}

- (void) setAddress:(NSString *)address {
    [profileConfig setValue:address forKeyPath:kServerAddr];
}

- (NSUInteger) port {
    return [[profileConfig valueForKeyPath:kServerPort] intValue];
}

- (void) setPort:(NSUInteger)port {
    [profileConfig setValue:[NSNumber numberWithInt:port] forKeyPath:kServerPort];
}

- (NSString*) application {
    return [profileConfig valueForKeyPath:kServerApp];
}

- (void) setApplication:(NSString *)application {
    [profileConfig setValue:application forKeyPath:kServerApp];
}

- (NSString*) user {
    return [profileConfig valueForKeyPath:kServerUser];
}

- (void) setUser:(NSString *)user {
    [profileConfig setValue:user forKeyPath:kServerUser];
}

- (NSString*) password {
   return [profileConfig valueForKeyPath:kServerPass];
}

- (void) setPassword:(NSString *)passwod {
    [profileConfig setValue:passwod forKeyPath:kServerPass];
}

- (NSUInteger) broadcastType {
    return [[profileConfig valueForKeyPath:kBroadcastType] intValue];
}

- (void) setBroadcastType:(NSUInteger) type {
    [profileConfig setValue:[NSNumber numberWithInt:type] forKeyPath:kBroadcastType];
}

- (NSUInteger) broadcastOption {
    return [[profileConfig valueForKeyPath:kBroadcastOption] intValue];
}

- (void) setBroadcastOption:(NSUInteger) type {
    [profileConfig setValue:[NSNumber numberWithInt:type] forKeyPath:kBroadcastOption];
}



- (NSUInteger) broadcastWidth {
    NSUInteger type = [[profileConfig valueForKeyPath:kBroadcastOption] intValue];
    NSUInteger ret = -1;
    switch (type) {
//        case kBroadcastTypeAudioOnly:   ret = 0; break;
        case kBroadcastOptionLow:         ret = 192; break;
        case kBroadcastOption320x240:     ret = 320; break;
        case kBroadcastOption352x240: 
        case kBroadcastOption352x288:     ret = 352; break;
        case kBroadcastOptionMed:         ret = 480; break;
        case kBroadcastOption640x360: 
        case kBroadcastOption640x480:     ret = 640; break;
		case kBroadcastOptionHD:			ret = 1280; break;
        default:
            break;
    }
    return ret;
}

- (NSUInteger) broadcastHeight {
    NSUInteger type = [[profileConfig valueForKeyPath:kBroadcastOption] intValue];
    NSUInteger ret = -1;
    switch (type) {
//        case kBroadcastTypeAudioOnly:   ret = 0; break;
        case kBroadcastOptionLow:         ret = 144; break;
        case kBroadcastOption320x240: 
        case kBroadcastOption352x240:     ret = 240; break;
        case kBroadcastOption352x288:     ret = 288; break;
        case kBroadcastOptionMed:         ret = 360; break;
        case kBroadcastOption640x360:     ret = 360; break;
        case kBroadcastOption640x480:     ret = 480; break;
		case kBroadcastOptionHD:			ret = 720; break;
        default:
            break;
    }
    return ret;
}


- (NSUInteger) frameRate {
    return [[profileConfig valueForKeyPath:kVideoMinFrameDuration] intValue];
}

- (void) setFrameRate:(NSUInteger) minFrameDuration {
    [profileConfig setValue:[NSNumber numberWithInt:minFrameDuration] forKeyPath:kVideoMinFrameDuration];
}

- (NSUInteger) keyFrameInterval {
    return [[profileConfig valueForKeyPath:kVideoKeyFrameInterval] intValue];
}

- (void) setKeyFrameInterval:(NSUInteger)keyFrameInterval {
    [profileConfig setValue:[NSNumber numberWithInt:keyFrameInterval] forKeyPath:kVideoKeyFrameInterval];
}


- (float_t) bitrateScalar {
    return [[profileConfig valueForKeyPath:kVideoMaxBitrateScalar] floatValue];
}

- (void) setBitrateScalar:(float_t) maxBitrateScalar {
    [profileConfig setValue:[NSNumber numberWithFloat:maxBitrateScalar] forKeyPath:kVideoMaxBitrateScalar];
}

- (BOOL) useTCP {
    return [[profileConfig valueForKeyPath:kNetworkUseTCP] boolValue];
}

- (void) setUseTCP:(BOOL)useTCP {
    [profileConfig setValue:[NSNumber numberWithBool:useTCP] forKeyPath:kNetworkUseTCP];
}

- (BOOL) autoBitrateAdjust {
    return [[profileConfig valueForKeyPath:kNetworkAutoBitrate] boolValue];
}

- (void) setAutoBitrateAdjust:(BOOL)autoBitrateAdjust {
    [profileConfig setValue:[NSNumber numberWithBool:autoBitrateAdjust] forKeyPath:kNetworkAutoBitrate];
}

- (BOOL) autoRestart {
	return [[profileConfig valueForKey:kAutoRestart] boolValue];
}

- (void) setAutoRestart:(BOOL)autoRestart {
	[profileConfig setValue:[NSNumber numberWithBool:autoRestart] forKey:kAutoRestart];
}


@end
