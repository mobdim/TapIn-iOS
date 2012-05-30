//
//  AACEncoder.h
//
//  Created by Steve McFarlin on 4/20/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//
/**
 TODO:  This needs to be rewritten in the same style as AACPlayer. Currently an error in the encoder callback
        is not handled at all. 
 */


#import <Foundation/Foundation.h>

#define kAACEncoderStopped  0
#define kAACEncoderError    1

@class AACEncoder;

typedef void (^AACEncoderCallback)(int message, NSString* str);

@protocol AACEncoderDelegate <NSObject>
//- (void) AACEncoder:(AACEncoder *)encoder completedFrameData:(void * const) data withSize:(UInt32) size andTime:(Float64) time;
- (void) AACEncoder:(AACEncoder *)encoder completedFrameData:(void * const) data withSize:(UInt32) size andTime:(uint64_t) time;
@end

@interface AACEncoder : NSObject {
    id<AACEncoderDelegate> delegate;
    
    dispatch_queue_t encoder_queue;
    dispatch_queue_t callback_queue;
    AACEncoderCallback caller_callback;
    
}
@property (nonatomic, retain) id<AACEncoderDelegate> delegate;

//- (NSError*) startOnQueue:(dispatch_queue_t) encoderQueue WithCallback:(AACEncoderCallback) callback callbackQueue:(dispatch_queue_t) callbackQueue;
- (void) start;
- (void) stop;
- (void) mute:(BOOL) val;

@end
