//
//  LivuBroadcastProfile.h
//  Livu
//
//  Created by Steve on 3/17/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import <Foundation/Foundation.h>

#define     kBroadcastProfileID     @"pid"
#define     kBroadcastProfileName   @"name"
#define     kBroadcastProfileActive @"active"

#define     kNetworkSettings        @"network"
#define     kNetworkUseTCP          @"network.useTCP"
#define     kNetworkAutoBitrate     @"network.autoBitrateAdjust"
#define     kServerAddr             @"network.address"
#define     kServerPort             @"network.port"
#define     kServerApp              @"network.application"
#define     kServerUser             @"network.user"
#define     kServerPass             @"network.pass"
#define		kAutoRestart			@"network.autoRestart"

#define     kAVSettings             @"av"
#define     kBroadcastType          @"av.broadcastType"
#define     kVideoMinFrameDuration  @"av.fps"
#define     kVideoMaxBitrateScalar  @"av.videoMaxBitrateScalar"
#define     kVideoKeyFrameInterval  @"av.keyFrameInterval"
#define		kBroadcastOption		@"av.broadcastOption"


#define     kBroadcastOptionLow			0
#define     kBroadcastOption320x240		1
#define     kBroadcastOption352x240		2
#define     kBroadcastOption352x288		3
#define     kBroadcastOptionMed			4
#define     kBroadcastOption640x360		5
#define     kBroadcastOption640x480		6
#define     kBroadcastOptionHD			7

#define		kBroadcastTypeAudio			0
#define		kBroadcastTypeVideo			1
#define		kBroadcastTypeAudioVideo	2
#define		kBroadcastTypeCount			3

static NSString *broadcastTypes[3] = {
	@"Audio", @"Video", @"Audio/Video"
};

#define     kAudioQuality               32 * 1000
#define     kBroadcastLowBitRate    128 * 1000
#define     kBroadcastMedBitRate    700 * 1000
#define     kBroadcastHighBitRate   3500 * 1000
//#define     kBroadcastOptionHDBitRate     10500 * 1000
#define     kBroadcastHDBitRate     5000 * 1000

static int broadcastBitrates[8] = {
//    kAudioQuality,
    kBroadcastLowBitRate,
    kBroadcastMedBitRate,
    kBroadcastMedBitRate,
    kBroadcastMedBitRate,
    kBroadcastMedBitRate,
    kBroadcastHighBitRate,
    kBroadcastHighBitRate,
	kBroadcastHDBitRate
};


@class LivuBroadcastConfig;

@interface LivuBroadcastProfile : NSObject {
@private
    NSMutableDictionary *profileConfig;
}

@property (nonatomic, retain) NSMutableDictionary *profileConfig;
@property (nonatomic, readonly) NSString* pid;
@property (nonatomic, retain, readwrite) NSString* name;

@property (nonatomic, assign, readwrite) BOOL active;

@property (nonatomic, retain, readwrite) NSString* address;
@property (nonatomic, assign, readwrite) NSUInteger port;
@property (nonatomic, assign, readwrite) BOOL useTCP;
@property (nonatomic, assign, readwrite) BOOL autoBitrateAdjust;
@property (nonatomic, assign, readwrite) BOOL autoRestart;
@property (nonatomic, retain, readwrite) NSString* application;
@property (nonatomic, retain, readwrite) NSString* user;
@property (nonatomic, retain, readwrite) NSString* password;

@property (nonatomic, assign, readwrite) NSUInteger broadcastType;
@property (nonatomic, assign, readwrite) NSUInteger broadcastOption;
@property (nonatomic, assign, readwrite) NSUInteger frameRate;
@property (nonatomic, assign, readwrite) NSUInteger keyFrameInterval;
@property (nonatomic, assign, readwrite) float_t bitrateScalar;

@property (nonatomic, readonly) BOOL audioOnly;
@property (nonatomic, readonly) NSUInteger broadcastWidth, broadcastHeight;

- (id) init;
- (id) initWithConfig:(NSMutableDictionary*) config;
- (id) initWithConfig:(NSMutableDictionary*) config andID:(NSString*) pid;



@end
