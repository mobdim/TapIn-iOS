//
//  LivuBroadcastManager.h
//
//  Created by Steve McFarlin on 4/11/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

/*
 TODO: Integrate this class and FFstream.
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>


#import "AVCEncoder.h"

#define kRTSPVideoNetworkError @"rtsp.networkError"
#define kRTSPVideoMediaError   @"rtsp.mediaError"
#define kRTSPVideoConnected    @"rtsp.connected"


#define kStreamSuccess				0
#define kStreamInitError			1
#define kStreamConnectionError		2
#define kStreamError				3
#define kStreamInternalError		4
#define kStreamStarted				5
#define kStreamStopped				6
#define kInvalidUserPass			7
#define kStreamRestart				8


@class LivuBroadcastProfile;
@class sRTSPClient;
@protocol AACEncoderDelegate;


typedef void (^LivuBroadcastCallback)(int message, NSString* str);

@interface LivuBroadcastManager : NSObject <AACEncoderDelegate> {
@private    
    NSData *aacCookie;
    BOOL broadcasting;
    uint64_t avStartTime;
    uint64_t audioStart;
    uint64_t audioInc;
    dispatch_queue_t sender_queue;
	dispatch_queue_t rtcp_queue;
    dispatch_queue_t caller_queue;
	dispatch_queue_t rtcp_watchdog_queue;
	dispatch_source_t rtcp_watchdog_timer;
	dispatch_semaphore_t queue_rw_sema;
    LivuBroadcastCallback caller_callback;
    AVCEncoderCallback avcEncoderCallback;
	NSMutableArray	*avQueue;
	NSMutableArray	*videoQueue;
	
	struct rtp *avc_session, *aac_session;
	uint8_t avc_session_id, aac_session_id;
	sRTSPClient *rtspClient;
	int rtcp_rr_timeout_count;
}
@property (nonatomic, readonly, copy) AVCEncoderCallback avcEncoderCallback;
@property (readonly) BOOL broadcasting;
@property (nonatomic, retain) NSData *spspps, *pps, *sps;
@property (nonatomic, readonly) int rtsp_fd;

//HACK
//- (void) setEncoder:(AVCEncoder*) encoder ;

/**
 This must be called before connecting
 @param callback A heap allocated callback
 @param dqueue Dispatch queue to call to issue the callback on.
 */
- (void) setCallback:(LivuBroadcastCallback) callback onQueue:(dispatch_queue_t) dqueue;

/**
 @abstract Start the stream
 @discussion
 
 This method should be called before the encoding is started.
 
 @param ip
 */
- (NSError*) connect:(LivuBroadcastProfile*) profile;

/**
 @abstract Disconnect from the server.
 @discussion
 
 You should not be sending any data to this class when you call this.
 */
- (NSError*) disconnect;



@end
