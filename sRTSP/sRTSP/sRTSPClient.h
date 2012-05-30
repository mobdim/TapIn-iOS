//
//  sRTSPClient.h
//  sRTSPClient
//
//  Created by Steve McFarlin on 7/14/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import <Foundation/Foundation.h>

#define RTSP_OK				200
#define RTSP_BAD_USER_PASS	401

#define SOCK_ERR_RESOLVE	-1
#define SOCK_ERR_CREATE		-2
#define SOCK_ERR_CONNECT	-3
#define SOCK_ERR_WRITE		-4
#define SOCK_ERR_READ		-5

#define RTSP_RESP_ERR		-6
#define RTSP_RESP_ERR_SESSION -7 //Bad session number retuned

/* Lower transport type */
enum _rtsp_transport {
	RTSP_TRANSPORT_UDP = 0,
	RTSP_TRANSPORT_TCP = 1
};

enum StreamType {
	RTSP_PLAY,
	RTSP_PUBLISH
};

typedef enum _rtsp_transport rtsp_transport_t;
typedef enum StreamType stream_t;


/*!
 @class SMRtspClient
 
 @abstract Partially implements the RTSP protocol
 
 @discussion
 
 TLDR; It's a hack to setup connections to a Wowza sever for live streaming.
 
 This class is a quick hack of the RTSP protocol. It is nowhere near the complete spec, and quite possibly
 what it does implement is not correct. It is primarly intended for setting up the connection to a Wowza 
 server. With that said....
 
 This class is a very thin implementation of RTSP. It does not maintain any state, nor does it parse or
 interpret SDP. It only implements enough for someone with knowlege of RTSP to call the sequence of functions
 nessasary to setup the communication lines for streaming to or from a RTSP server with a RTP library such
 as oRTP or JRTP. Even then you may need to modfy this as many request header fields are "hard coded".
 
 The user is responsible for parsing of the response headers for any information needed. The only values
 this class parses are those that are needed to create and maintain the RTSP session (session ID for example).
 
 The class does have a bit of code duplication. I went for this as I am not familar with the spec and I did
 not want a messey send request function that did everything based on state/switches (which I have seen).
 
 */
@interface sRTSPClient : NSObject {
@private
	
	NSString	*host;
	NSString	*path;
	int			port;
	NSString	*user;
	NSString	*pass;
	
	int			sock;
	rtsp_transport_t transport;
	stream_t	streamType;
	NSString	*sdp;

	NSMutableDictionary *responseHeader;
	
	int			cSeq;
	NSString	*session, *authentication;
	int			mediaCount;
	int			channelCount;
	
}
@property (nonatomic, assign) rtsp_transport_t transport;
@property (nonatomic, retain, readonly) NSString *host, *path;
@property (nonatomic, copy) NSString *user, *pass;
@property (nonatomic, assign, readonly) int port;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, retain, readonly) NSDictionary *responseHeader;
@property (nonatomic, copy) NSString *sdp;
@property (nonatomic, readonly) int mediaCount;
@property (nonatomic, copy, readonly) NSString *session;
@property (nonatomic, copy, readonly) NSString *authentication;
@property (nonatomic, assign, readonly) int sock;
@property (nonatomic, assign) stream_t streamType;


/*!
 @abstract Connect to a RTSP server.
 
 @param host Host address
 @param port Host connection port
 @param path Resrouce path
 
 @result 0 for success negative otherwize.
 */
- (int) connectTo:(NSString*) host onPort:(int) port withPath:(NSString*) path;

/*!
 @abstract Send OPTIONS request
 
 @result int RTSP response code or negative if socket error.
 */
- (int) options;

/*!
 @abstract Send ANNOUNCE request
 
 @discussion The SDP sould be set before calling this function.
 
 @result int RTSP response code or negative if socket error.
 */
- (int) announce;


/*!
 @abstract DESCRIBE request
 
 */
- (int) describe;

/*!
 @abstract Send SETUP request
 
 @discussion
 
 This will send the SETUP request to the server. For UDP requests you need to pass in
 the client ports used for RTP and RTCP. For TCP these are not used. For TCP the interleave
 is auto calculated based on the number of calls to this function. The first call is 0-1 and
 the next 2-3 and so on.
 
 @param streamID The ID of the stream
 @param rtpPort RTP port
 @param rtspPort RTCP port
 @result int The RTSP response code or negative if socket error.
 */
- (int) setup:(int) streamID withRtpPort:(int) rtpPort andRtcpPort:(int) rtcpPort;

/*!
 @abstract Send RECORD request
 
 @result int RTSP response code or negative if socket error.
 */
- (int) record;

/*!
 @abstract Send PLAY request
 
 @result int RTSP response code or negative if socket error.
 */
- (int) play;


/*!
 @abstract Send TEARDOWN request
 
 @result int RTSP response code or negative if socket error.
 */
- (int) teardown;


@end
