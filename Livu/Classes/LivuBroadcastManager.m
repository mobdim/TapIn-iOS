//
//  LivuBroadcastManager.m
//  LivuBraodcastManager
//
//  Created by Steve McFarlin on 4/11/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

/**
 Notes - 
 
 Currently I am submiting the sending of AV data on a 'sender' queue. The use of GCD as a queue
 works well with UDP, and avoids creating one or more queues to poll a AV data queue for data to
 send. However, with TCP this can cause issues if the netowrk throughput is lower then what is 
 being put on the line. In this case the serial queue will start to queue a lot of tasks. 
 This causes issues when shutting down this class as the shutdown procedure is submitted to the
 same queue. Right now I simply susped the queue, flip a flag, and then resume the GCD dispatch
 queue. This will have the effect of draining the jobs.
 
 */

#import "LivuBroadcastManager.h"

#include <QuartzCore/QuartzCore.h>
#include <mach/mach.h>
#include <mach/mach_time.h>

#import "AACEncoder.h"
#import "AVCEncoder.h"
#import "rtp.h"
#import "rtpenc_aac.h"
#import "rtpenc_h264.h"
#import "sRTSPClient.h"
//#include "ffstream.h"
#include "base64.h"
#import "sm_math.h"

//#include "libavformat/avformat.h"
//#include "libavutil/avassert.h"

#include "LivuBroadcastProfile.h"
#define kQueueMaximumDepth 100

//static NSString *fullsdp = @"v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=Livu\r\nc=IN IP4 192.168.1.50\r\nt=0 0\r\na=tool:Livu RTP\r\nm=audio 0 RTP/AVP 96\r\nb=AS:64\r\na=rtpmap:96 MPEG4-GENERIC/44100/1\r\na=fmtp:96 profile-level-id=1;mode=AAC-hbr;sizelength=13;indexlength=3;indexdeltalength=3; config=1208\r\na=control:streamid=0\r\nm=video 0 RTP/AVP 97\r\nb=AS:64\r\na=rtpmap:97 H264/90000\r\na=fmtp:97 packetization-mode=1;sprop-parameter-sets=Z0IAHo1oFglk,aM4JyA==\r\na=control:streamid=1";

static NSString *fullsdp = @"v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=Livu\r\nc=IN IP4 %@\r\nt=0 0\r\na=tool:Livu RTP\r\nm=audio 0 RTP/AVP 96\r\nb=AS:64\r\na=rtpmap:96 MPEG4-GENERIC/44100/1\r\na=fmtp:96 profile-level-id=1;mode=AAC-hbr;sizelength=13;indexlength=3;indexdeltalength=3; config=1208\r\na=control:trackid=1\r\nm=video 0 RTP/AVP 97\r\nb=AS:64\r\na=rtpmap:97 H264/90000\r\na=fmtp:97 packetization-mode=1;sprop-parameter-sets=%@,%@\r\na=control:trackid=2";


//AU Headers
static NSString *audio_sdp = @"v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=Livu\r\nc=IN IP4 %@\r\nt=0 0\r\na=tool:Livu RTP\r\nm=audio 0 RTP/AVP 97\r\nb=AS:64\r\na=rtpmap:96 MPEG4-GENERIC/44100/1\r\na=fmtp:97 profile-level-id=1;mode=AAC-hbr;sizelength=13;indexlength=3;indexdeltalength=3; config=1208\r\na=control:trackid=1";

static NSString *video_sdp = @"v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=Livu\r\nc=IN IP4 %@\r\nt=0 0\r\na=tool:Livu RTP\r\nm=video 0 RTP/AVP 97\r\nb=AS:64\r\na=rtpmap:97 H264/90000\r\na=fmtp:97 packetization-mode=1;sprop-parameter-sets=%@,%@\r\na=control:trackid=1";



static struct timeval timeout;
#define kRTCPTimeout 10

enum avtype {
	AV_TYPE_AUDIO,
	AV_TYPE_VIDEO
};
typedef enum avtype AVType;


@interface LivuBroadcastManager() 
@property (nonatomic, readwrite, copy) AVCEncoderCallback avcEncoderCallback;
@property (nonatomic, readwrite, retain) LivuBroadcastProfile *profile;
- (void) setupAVCEncoderCallback;
- (int) setupRTPUDPConnection;
- (int) setupRTPTCPConnection;
- (void) disconnectInternal:(int) reason;
- (void) receivedRTCP;
- (void) streamAudio;
@end

@interface AVPacket : NSObject {
@public
	NSData *data;
	AVType type;
	uint32_t size;
	uint64_t time;
	uint64_t sample_time;
}
@end

@implementation AVPacket 
- (void) dealloc {
	[data release];
	[super dealloc];
}

@end


void rtp_aac_session_callback(struct rtp *session, rtp_event *e) {
	//NSLog(@"Received AAC RTP Callback");
	LivuBroadcastManager *man = (LivuBroadcastManager*) rtp_get_userdata(session);
	[man receivedRTCP];
}

void rtp_avc_session_callback(struct rtp *session, rtp_event *e) {
	
	LivuBroadcastManager *man = (LivuBroadcastManager*) rtp_get_userdata(session);
	[man receivedRTCP];
	
	//NSLog(@"Received AVC RTP Callback");
	if(e->type == RX_RR) {
		//NSLog(@"Received AVC RR packet");
		//rtp_update(session);
		//rtp_send_ctrl(session, pkt->fields.ts, NULL);
	}
}


void rtcp_session_callback(struct rtp *session, uint32_t rtp_ts, int max_size) {
     LOG_EXPR(session);
    
	//NSLog(@"Received RTCP Callback");
}


@implementation LivuBroadcastManager

@synthesize spspps, broadcasting, avcEncoderCallback, sps, pps;
@synthesize profile;
@dynamic rtsp_fd;



#pragma mark -
#pragma mark Lifecycle management
#pragma mark -

- (id) init {
    self = [super init];
    if (self) {
        [self setupAVCEncoderCallback];
		aac_session_id = 96;
		avc_session_id = 97;
		timeout.tv_sec = 5;
		timeout.tv_usec = 0;
		avQueue = [[NSMutableArray alloc] initWithCapacity:100];
		videoQueue = [[NSMutableArray alloc] initWithCapacity:100];
		caller_queue = NULL;
		caller_callback = nil;
    }
    return self;
}

- (void) dealloc {
    self.avcEncoderCallback = nil;
	self.profile = nil;
	
	if (self.broadcasting) {
		[self disconnect];
	}
	
	if(caller_callback != nil)
		[caller_callback release];
	
	if(caller_queue != NULL)
		dispatch_release(caller_queue);
	
	[super dealloc];
}


- (int) rtsp_fd {
	return rtspClient.sock;
}


#pragma mark -
#pragma mark Connection Management
#pragma mark -

- (void) receivedRTCP {
	
}


//HACK
//- (void) setEncoder:(AVCEncoder*) encoder {
//    set_encoder(encoder);
//}

- (void) setCallback:(LivuBroadcastCallback) callback onQueue:(dispatch_queue_t) dqueue {
	if(caller_callback != nil)
		[caller_callback release];
	
    caller_callback = [callback retain];
	
	if(caller_queue != NULL)
		dispatch_release(caller_queue);
	
    caller_queue = dqueue;
    if(dqueue == NULL) {
        dqueue = dispatch_get_main_queue();
    }
    dispatch_retain(caller_queue);

}

- (NSString*) generateSDP {
	unsigned char csps[32], cpps[32];
	NSString *b64sps = nil, *b64pps = nil, *sdp = nil;
	
	if (profile.broadcastType != kBroadcastTypeAudio) {
		int length = base64encode([sps bytes] + 4, [sps length] - 4, csps, 32);
		csps[length] = '\0';
		b64sps = [NSString stringWithCString:(const char*)csps encoding:NSASCIIStringEncoding];
		
		//NSLog(@"SPS Len: %d", length);
		
		length = base64encode([pps bytes] + 4, [pps length] - 4, cpps, 32);
		cpps[length] = '\0';
		b64pps = [NSString stringWithCString:(const char*)cpps encoding:NSASCIIStringEncoding];
	}
	
	switch (profile.broadcastType) {
		case kBroadcastTypeAudio:
			sdp = [NSString stringWithFormat:audio_sdp, self.profile.address];
			break;
			
		case kBroadcastTypeVideo: 
			sdp = [NSString stringWithFormat:video_sdp, self.profile.address, b64sps, b64pps];
			break;
			
		case kBroadcastTypeAudioVideo:
			sdp = [NSString stringWithFormat:fullsdp, self.profile.address, b64sps, b64pps];
			break;
		default:
			break;
	}
	return [[sdp retain] autorelease];
}

- (int) setupRTPUDPConnection {
	NSString *transport;
	//NSLog(@"Transport Line: %@", transport);
	NSArray *kvs;
	NSArray *ports;
	int track_id = 1;
	
	rtspClient = [[sRTSPClient alloc] init] ;
	
	//TODO: Check result codes and return error
	
	rtspClient.sdp = [self generateSDP];
	
	//NSLog(@"SDP File: %@\n\n", rtspClient.sdp);
	
	NSLog(@"Connecting to IP %@", self.profile.address);
	
	int responseCode = [rtspClient connectTo:self.profile.address onPort:self.profile.port withPath:self.profile.application];
	
	if(responseCode != 0) {return responseCode;}
	
	rtspClient.user = self.profile.user;
	rtspClient.pass = self.profile.password;
	
	responseCode = [rtspClient options];
	
	if(responseCode != RTSP_OK) {return responseCode;}
	
	responseCode = [rtspClient announce];
	
	if(responseCode != RTSP_OK) {return responseCode;}
	
	rtspClient.transport = RTSP_TRANSPORT_UDP;
	rtspClient.streamType = RTSP_PUBLISH;

	if (profile.broadcastType != kBroadcastTypeVideo) {
		//Setup AAC
		responseCode = [rtspClient setup:(track_id++) withRtpPort:5000 andRtcpPort:5001];
		
		if(responseCode != RTSP_OK) {return responseCode;}
		
		transport = [rtspClient.responseHeader objectForKey:@"Transport"];
		//NSLog(@"Transport Line: %@", transport);
		kvs = [transport componentsSeparatedByString:@";"];
		for (NSString *kv in kvs) {
			if ([kv hasPrefix:@"server_port"]) {
				NSRange eq = [kv rangeOfString:@"="];
				NSString *p = [kv substringFromIndex:eq.location + 1];
				//NSLog(@"Ports: %@", p);
				ports = [p componentsSeparatedByString:@"-"];
				//NSLog(@"RTP Port: %@ - RTCP Port: %@",[ports objectAtIndex:0], [ports objectAtIndex:1] );
			}
		}
		
		aac_session = rtp_init_udp([self.profile.address cStringUsingEncoding:NSASCIIStringEncoding], 5000, [[ports objectAtIndex:0] intValue], 60, 2000, rtp_aac_session_callback, self);
		
		if(aac_session == NULL) {
			NSLog(@"Session is NULL");
			return -1;
		}
	}
	
	if (profile.broadcastType != kBroadcastTypeAudio) {
		//Setup AVC
		responseCode = [rtspClient setup:(track_id) withRtpPort:5002 andRtcpPort:5003];
		
		if(responseCode != RTSP_OK) {
			rtp_done(aac_session);
			return responseCode;
		}
		
		//TODO setup rtp
		
		transport = [rtspClient.responseHeader objectForKey:@"Transport"];
		//NSLog(@"Transport Line: %@", transport);
		kvs = [transport componentsSeparatedByString:@";"];
		//NSArray *ports;
		for (NSString *kv in kvs) {
			if ([kv hasPrefix:@"server_port"]) {
				NSRange eq = [kv rangeOfString:@"="];
				NSString *p = [kv substringFromIndex:eq.location + 1];
				//NSLog(@"Ports: %@", p);
				ports = [p componentsSeparatedByString:@"-"];
				//NSLog(@"RTP Port: %@ - RTCP Port: %@",[ports objectAtIndex:0], [ports objectAtIndex:1] );
			}
		}
		
		avc_session = rtp_init_udp([self.profile.address cStringUsingEncoding:NSASCIIStringEncoding], 5002, [[ports objectAtIndex:0] intValue], 60, 2000, rtp_avc_session_callback, self);
		
		if(avc_session == NULL) {
			NSLog(@"Session is NULL");
		}
	}
	
	responseCode = [rtspClient record];
	
	if(responseCode != RTSP_OK) {
		rtp_done(aac_session);
		rtp_done(avc_session);
		return responseCode;
	}
	
	broadcasting = YES;
	return responseCode;
}

- (int) setupRTPTCPConnection {
	
	int stream_id = 0;
	int track_id = 1;
	rtspClient = [[sRTSPClient alloc] init] ;
	//TODO: Check result codes and return error
	rtspClient.sdp = [self generateSDP];
	
	int responseCode = [rtspClient connectTo:self.profile.address onPort:self.profile.port withPath:self.profile.application];
	
	if(responseCode != 0) {return responseCode;}
	
	rtspClient.user = self.profile.user;
	rtspClient.pass = self.profile.password;
	
	responseCode = [rtspClient options];
	
	if(responseCode != RTSP_OK) {return responseCode;}
	
	responseCode = [rtspClient announce];
	
	if(responseCode != RTSP_OK) {return responseCode;}
	
	rtspClient.transport = RTSP_TRANSPORT_TCP;
	rtspClient.streamType = RTSP_PUBLISH;
	
	
	if (profile.broadcastType != kBroadcastTypeVideo) {
		//Setup AAC
		responseCode = [rtspClient setup:track_id++ withRtpPort:5000 andRtcpPort:5001];
		
		if(responseCode != RTSP_OK) {return responseCode;}
		
		aac_session = rtp_init_tcp(rtspClient.sock, 4, stream_id, 60, 2000, rtp_aac_session_callback, self);
		
		if(aac_session == NULL) {
			NSLog(@"Session is NULL");
		}
	
		stream_id += 2 ;
	}
	
	if(profile.broadcastType != kBroadcastTypeAudio) {
		//Setup AVC
		responseCode = [rtspClient setup:track_id withRtpPort:5002 andRtcpPort:5003];
		
		if(responseCode != RTSP_OK) {
			rtp_done(aac_session);
			return responseCode;
		}
		
		avc_session = rtp_init_tcp(rtspClient.sock, 4, stream_id, 60, 2000, rtp_avc_session_callback, self);
		
		if(avc_session == NULL) {
			NSLog(@"Session is NULL");
		}
	}
	
	responseCode = [rtspClient record];
	
	if(responseCode != RTSP_OK) {
		rtp_done(avc_session);
		rtp_done(aac_session);
		return responseCode;
	}
	
	broadcasting = YES;
	return responseCode;
}


- (NSError*) connect:(LivuBroadcastProfile*) _profile {
    
    if(self.broadcasting) return [NSError errorWithDomain:@"Attempt to start broadcaster while running" code:-1 userInfo:nil];
    
    sender_queue = dispatch_queue_create("com.stevemcfarlin.LivuBroadcastManager.sender_queue", 0);
	rtcp_queue = dispatch_queue_create("com.stevemcfarlin.LivuBroadcastManager.rtcp_queue", 0);
    avStartTime = 0;
    audioStart = 0;
    audioInc = 0;
	rtcp_rr_timeout_count = 0;
	int ret ;
	self.profile = _profile;
    
	if(profile.useTCP) {
		ret = [self setupRTPTCPConnection];
	}
	else {
		ret = [self setupRTPUDPConnection];
	}
	
	switch(ret) {
		case(RTSP_OK) : 
			dispatch_async(caller_queue, ^{
				caller_callback(kStreamStarted, @"Started");
			});
			
			if(!profile.useTCP) {
				
				rtcp_watchdog_queue = dispatch_queue_create("rtcp_watchdog_queue", 0);
				rtcp_watchdog_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, rtcp_watchdog_queue);
				dispatch_release(rtcp_watchdog_queue);
				
				dispatch_source_set_timer(rtcp_watchdog_timer, dispatch_walltime(NULL, 0), 5ull * NSEC_PER_SEC, 0);
				dispatch_source_set_event_handler(rtcp_watchdog_timer, ^{
					
					if(!broadcasting) return;
					
					rtcp_rr_timeout_count++;
					int ret = 0;
					if (profile.broadcastType != kBroadcastTypeAudio) {
						ret = rtp_recv(avc_session, &timeout, 0);
					}
					
					if (profile.broadcastType != kBroadcastTypeVideo) {
						ret = rtp_recv(aac_session, &timeout, 0);
					}
					
					if (ret) {
						rtcp_rr_timeout_count = 0;
					}
					
					if (rtcp_rr_timeout_count >= 2) {
						NSLog(@"RTCP Timeout. Shutting Down");
						dispatch_async(dispatch_get_main_queue(), ^{
							[self disconnectInternal:kStreamError];
						});
						dispatch_suspend(rtcp_watchdog_timer);
					}
					
				});
				
				dispatch_resume(rtcp_watchdog_timer);
			}
			
			queue_rw_sema = dispatch_semaphore_create(0);
			
			dispatch_async(sender_queue, ^{
				switch (profile.broadcastType) {
					case kBroadcastTypeAudio:
						[self streamAudio];
						break;
					case kBroadcastTypeVideo:
						//[self streamVideo];
						break;
					case kBroadcastTypeAudioVideo:
						//[self streamAudioVideo];
						break;
						
					default:
						break;
				}
			});
			
			break;
		case(RTSP_BAD_USER_PASS) :
			dispatch_async(caller_queue, ^{
				caller_callback(kInvalidUserPass, @"Bad user/pass");
			});
			break;
		default:
			dispatch_async(caller_queue, ^{
				caller_callback(kStreamError, @"RTSP Error");
			});
			
		if(self.profile.autoRestart) {
//		  if(YES) {
			caller_callback(kStreamRestart, @"Stream Restart");
			dispatch_async(dispatch_get_main_queue(), ^{
				[self connect:self.profile];
			});
		}
	};
	
    return nil;
}

- (void) disconnectInternal:(int) reason {
	//A block may be executing currently, but that is alright
	
	if (!broadcasting) { return; }
	
	if(!profile.useTCP) {
		dispatch_suspend(rtcp_watchdog_timer);
		dispatch_source_cancel(rtcp_watchdog_timer);
	}
	
//	//resume to drain any pending AV sending blocks
	broadcasting = NO;
	
	if (profile.broadcastType == kBroadcastTypeAudio) {	
		dispatch_semaphore_signal(queue_rw_sema);
		dispatch_release(queue_rw_sema);
	}
	@try {
   
	dispatch_sync(sender_queue, ^{		
		broadcasting = NO;
		
		if(reason != kStreamError) {
			if (profile.broadcastType != kBroadcastTypeAudio) {
				rtp_send_bye(avc_session);
			}
			if (profile.broadcastType != kBroadcastTypeVideo) {
				rtp_send_bye(aac_session);
			}
			[rtspClient teardown];
		}
		
		if (profile.broadcastType != kBroadcastTypeVideo)
			rtp_done(aac_session);
		if (profile.broadcastType != kBroadcastTypeAudio)
			rtp_done(avc_session);
		
		[rtspClient release];
		[avQueue removeAllObjects];
		[videoQueue removeAllObjects];
	});
    }
    @catch (NSException *exception) {
        
    }
    @finally {
        
    }
	dispatch_release(sender_queue);
	
	dispatch_async(caller_queue, ^{
		switch (reason) {
			case kStreamStopped:
				caller_callback(reason, @"Stopped");
				break;
			
			case kStreamError:
				caller_callback(reason, @"Stream Error");
				break;
				
			default:
				caller_callback(reason, @"Unknown Error");
				break;
		}
	});
}

- (NSError*) disconnect {
    
	[self disconnectInternal:kStreamStopped];
	
    return nil;
}

//static uint64_t packet_count = 0;

- (void) streamAudio {
    
    int ret = 0;
    static int64_t last_pts = 0;
    
	while (broadcasting) {
        if ([avQueue count] == 0) {
			dispatch_semaphore_wait(queue_rw_sema, DISPATCH_TIME_FOREVER);
			
            continue;
        }
        
        AVPacket *packet = [avQueue objectAtIndex:0];
        
        last_pts = packet->sample_time;
        
        //This should never happen but it is.... mainly with UDP for some dumb reason.
        if(packet == nil) {
            continue;
        }
        
        ret = send_aac_au(aac_session, packet->time, aac_session_id, [packet->data bytes], packet->size, &timeout);
        
        @synchronized(avQueue) {
            [avQueue removeObjectAtIndex:0];
        }   
    }
}

- (void) sendAV:(AVPacket*) vpkt {
	AVPacket *apkt;
	int ret = 0;
	
	if (!broadcasting) { return; }
	
	while ([avQueue count]) {
		@synchronized (avQueue) {
			apkt = [avQueue objectAtIndex:0];
		}
		//Will the time stamps ever wrap? SM: Yes.
		//NSLog(@"sendVideoFrame count=%d | %llu | %llu | %lld", [avQueue count], apkt->sample_time, vpkt->sample_time, vpkt->sample_time - apkt->sample_time);
		if(apkt->sample_time < vpkt->sample_time) {
			ret = send_aac_au(aac_session, apkt->time, aac_session_id, [apkt->data bytes], apkt->size, &timeout);
		}
		else {
			break;
		}
		
		@synchronized (avQueue) {
			[avQueue removeObjectAtIndex:0];
		}
	}
	ret = send_nal(avc_session, vpkt->time, avc_session_id, (uint8_t*) [vpkt->data bytes], vpkt->size, &timeout);
	//NSLog(@"Sent AV");
	
}

- (void) setupAVCEncoderCallback {
    AVCEncoderCallback cb = ^(const void* buffer, uint32_t length, CMTime pts) {
        if(!broadcasting) return;
		
		NSData *data = [[NSData alloc] initWithBytes:buffer length:length];
		
		AVPacket *packet = [[AVPacket alloc] init];
		packet->data = data;
		packet->size = length;
		packet->time = pts.value;
		packet->type = AV_TYPE_VIDEO;
		packet->sample_time = pts.value;
		dispatch_async(sender_queue, ^{
			[self sendAV:packet];
		});
		
		[packet release];		
    };
    
    self.avcEncoderCallback = cb;
}

#pragma mark -
#pragma mark AACEncoder Callback
#pragma mark -
- (void) AACEncoder:(AACEncoder *)encoder completedFrameData:(void * const) data withSize:(UInt32) size andTime:(uint64_t) time {
    
    if(!broadcasting) return;

	//NSLog(@"Audio PTS: %llu", time);
	
	//TODO: Rescale using math.
    if(audioStart == 0) {
        audioInc = audioStart = rescale(time, kAVBaseTime, 44100);
    }
    else {
        audioInc += 1024;
    }
	
    NSData *buff = [[NSData alloc] initWithBytes:data length:size];

	AVPacket *packet = [[AVPacket alloc] init];
	packet->data = buff;
	packet->size = size;
	packet->time = audioInc;
	packet->type = AV_TYPE_AUDIO;
	packet->sample_time = time;
    	
	@synchronized(avQueue) {
		[avQueue addObject:packet];
	}
	
	if(profile.broadcastType == kBroadcastTypeAudio) {
		dispatch_semaphore_signal(queue_rw_sema);
	}
	
	[packet release];

}

@end


