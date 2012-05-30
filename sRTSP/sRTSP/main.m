//
//  main.m
//  sRTSP
//
//  Created by Steve McFarlin on 7/14/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

static NSString *sdp = @"v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=livu\r\nt=0 0\r\na=sdplang:en\r\na=range:npt=now-\r\na=control:*\r\nm=audio 10000 RTP/AVP 96\nc=IN IP4 192.168.1.50/63\r\na=rtpmap:96 mpeg4-generic/44100/1\r\na=fmtp:96 profile-level-id=1;mode=AAC-hbr;sizelength=13;indexlength=3;indexdeltalength=3;config=1208\r\na=control:trackid=1\r\nm=video 10000 RTP/AVP 97\r\nc=IN IP4 192.168.1.50/63\r\na=rtpmap:97 H264/90000a=fmtp:97 packetization-mode=1;profile-level-id=42001E;sprop-parameter-sets=Z0IAHo1oFglk,aM4JyA==\r\na=control:trackid=2";


#import <Foundation/Foundation.h>


#import "sRTSPClient.h"


void testPublish(void) {
	// insert code here...
	sRTSPClient *client = [[sRTSPClient alloc] init];
	
	client.streamType = RTSP_PUBLISH;
	client.sdp = sdp;
	client.transport = RTSP_TRANSPORT_UDP;
	
	//client.user = @"sgwowza";
	//client.pass = @"StreamDev101";
	
	//[client connectTo:@"wow.insinceurope.net" onPort:2100 withPath:@"/livu1r/livu"];
	[client connectTo:@"jfg-helix1.srv.proceau.net" onPort:554 withPath:@"/broadcast/livu"];
	
	int responseCode = [client options];
	NSLog(@"--- OPTIONS Response: %d ---\n\n %@ \n", responseCode, client.responseHeader);
	
	responseCode = [client announce];
	NSLog(@"--- ANNOUNCE Response: %d - session: %@ ---\n\n %@ \n", responseCode, client.session, client.responseHeader);
	
	responseCode = [client setup:1 withRtpPort:5000 andRtcpPort:5001];
	NSLog(@"--- SETUP Response: %d ---\n\n %@ \n", responseCode, client.responseHeader);
	
	responseCode = [client setup:2 withRtpPort:5002 andRtcpPort:5003];
	NSLog(@"--- SETUP Response: %d ---\n\n %@ \n", responseCode, client.responseHeader);
	
	responseCode = [client record];
	NSLog(@"--- RECORD Response: %d ---\n\n %@ \n", responseCode, client.responseHeader);
	
	responseCode = [client teardown];
	NSLog(@"--- TEARDOWN Response: %d ---\n\n %@ \n", responseCode, client.responseHeader);
	
	[client release];
}

void testPlay(void) {
	sRTSPClient *client = [[sRTSPClient alloc] init];
	
	[client connectTo:@"212.74.101.176" onPort:554 withPath:@"talkback"];
	
	client.streamType = RTSP_PLAY;
	client.transport = RTSP_TRANSPORT_TCP;
	
	int responseCode = [client options];
	NSLog(@"--- OPTIONS Response: %d ---\n\n %@ \n", responseCode, client.responseHeader);
	
	responseCode = [client describe];
	NSLog(@"--- DESCRIBE Response: %d - session: %d ---\n\n %@ \n", responseCode, client.session, client.responseHeader);
	
	responseCode = [client setup:1 withRtpPort:5002 andRtcpPort:5003];
	NSLog(@"--- SETUP Response: %d ---\n\n %@ \n", responseCode, client.responseHeader);
	
	responseCode = [client play];
	NSLog(@"--- PLAY Response: %d ---\n\n %@ \n", responseCode, client.responseHeader);
	
	responseCode = [client teardown];
	NSLog(@"--- TEARDOWN Response: %d ---\n\n %@ \n", responseCode, client.responseHeader);
	
	[client release];
}

int main (int argc, const char * argv[])
{
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	
	
	testPublish();
	
	
	[pool drain];
    return 0;
}

