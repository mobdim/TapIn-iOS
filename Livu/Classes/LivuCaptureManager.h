//
//  CaptureManager.h
//  Livu
//
//  Created by Steve McFarlin on 4/4/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>


//forwards
@class AVCEncoder, GLVideoProcessor;

@protocol VideoFrameTimeDelegate <NSObject>

- (void) pushVideoPTS:(CMTime) time;

@end

/**
 @class LivuCaptureManager
 @abstract Handles media capture.
 */
@interface LivuCaptureManager : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,NSStreamDelegate> {
	
	AVCaptureSession            *captureSession;
	//AVCaptureVideoPreviewLayer  *previewLayer;
	AVCaptureConnection         *videoConnection;
	AVCaptureVideoDataOutput    *videoOutput;
    AVCaptureDeviceInput        *videoInput;
	AVCaptureAudioDataOutput    *audioOut;
    AVCEncoder					*avcEncoder;
	GLVideoProcessor			*videoProcessor;
	
    id <VideoFrameTimeDelegate> timeDelegate;
    CVPixelBufferRef pixelBuffer;
	NSUInteger frameRate;
    BOOL encode;
    BOOL backFacingCameraActive;
    dispatch_queue_t capture_queue;
	BOOL captureRunning;
    
}
@property (nonatomic, readonly, retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic, readonly, retain) AVCaptureVideoDataOutput *videoOutput;
//@property (nonatomic, readonly, retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, readonly, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) id <VideoFrameTimeDelegate> timeDeleage;
@property (readonly) AVCaptureDevice* videoCaptureDevice;
@property (retain) AVCEncoder *avcEncoder;
@property (nonatomic, assign) NSUInteger frameRate;
@property (nonatomic, readonly) BOOL captureRunning;
@property (nonatomic, assign) int rotationAngle;


- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
- (void) addVideoInput;
- (void) addVideoDataOutput;
- (void) startEncoding;
- (void) stopEncoding ;
- (void) startCapture;
- (void) stopCapture;
- (BOOL) cameraToggle;
- (BOOL) hasTorch;
- (void) setTorchMode:(AVCaptureTorchMode) torchMode;

- (BOOL) hasMultipleCameras;
- (NSUInteger) cameraCount;

- (BOOL) hasExposure;
- (AVCaptureExposureMode) exposureMode;
- (void) exposureAtPoint:(CGPoint)point;
- (void) setExposureMode:(AVCaptureExposureMode)exposureMode;

- (BOOL) hasFocus;
- (AVCaptureFocusMode) focusMode;
- (void) setFocusMode:(AVCaptureFocusMode)focusMode;
- (void) focusAtPoint:(CGPoint)point;
@end
