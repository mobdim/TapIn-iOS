//
//  CaptureManager.m
//  Livu
//
//  Created by Steve McFarlin on 4/4/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import "LivuCaptureManager.h"
#import "LivuBroadcastConfig.h"

#import "AVCEncoder.h"
#import "GLVideoProcessor.h"

@interface LivuCaptureManager ()
@property (assign) BOOL encode;
@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic, retain) AVCaptureVideoDataOutput *videoOutput;
@end


@implementation LivuCaptureManager

@synthesize captureSession;
@synthesize videoOutput,videoInput;
@synthesize encode, timeDeleage;
@synthesize avcEncoder;
@synthesize captureRunning;
@synthesize rotationAngle;

//@dynamic torchMode;
//@dynamic focusMode;
//@dynamic exposureMode;
@dynamic videoCaptureDevice;
@dynamic frameRate;
#pragma mark -
#pragma mark Classs lifetime
#pragma mark -


- (id) init{
	self = [super init];
	if (self) {		
        encode = NO;
        backFacingCameraActive = YES;
        //NSDictionary *ps = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];

        capture_queue = dispatch_queue_create("com.livu.captureManager.captureQueue", NULL);

        self.captureSession = [[AVCaptureSession alloc] init];
		
        //One day this is going to be a bug.
        //Create a pixel buffer to fit the largest input format
       // CVPixelBufferCreate(NULL, 640, 480, kCVPixelFormatType_32BGRA, (CFDictionaryRef) ps, &pixelBuffer);
        
        LivuBroadcastProfile* profile = [LivuBroadcastConfig activeProfile];
        switch (profile.broadcastOption) {
            case kBroadcastOptionLow:
                self.captureSession.sessionPreset = AVCaptureSessionPresetLow;
                videoProcessor = [[GLVideoProcessor alloc] initWithWidth:192 andHeight:144 usingOverlayImage:nil] ;
                break;
            case kBroadcastOption320x240:
            case kBroadcastOption352x240:
            case kBroadcastOption352x288:
                @try {
                    self.captureSession.sessionPreset = AVCaptureSessionPreset352x288;

                }
                @catch (NSException *exception) {
                    
                }
                @finally {
                    
                }
				videoProcessor = [[GLVideoProcessor alloc] initWithWidth:352 andHeight:288 usingOverlayImage:nil] ;
                break;
            case kBroadcastOptionMed:
                self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
				videoProcessor = [[GLVideoProcessor alloc] initWithWidth:480 andHeight:360 usingOverlayImage:nil] ;
                break;
            case kBroadcastOption640x360:
            case kBroadcastOption640x480:
                self.captureSession.sessionPreset = AVCaptureSessionPreset640x480;
				videoProcessor = [[GLVideoProcessor alloc] initWithWidth:640 andHeight:480 usingOverlayImage:nil] ;
				break;
			case kBroadcastOptionHD:
				self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
				videoProcessor = [[GLVideoProcessor alloc] initWithWidth:1280 andHeight:720 usingOverlayImage:nil] ;
				break;
            default:
                break;
        }
        
        [self addVideoInput];
        [self addVideoDataOutput];   
		
		[videoProcessor loadVertexShader:@"DirectDisplayShader" fragmentShader:@"DirectDisplayShader"];
		
	}
	
	return self;
}

- (void)dealloc {
	[self.captureSession stopRunning];
	self.captureSession = nil;
    self.avcEncoder = nil;
    //CVPixelBufferRelease(pixelBuffer);
    //TODO: Release queue
	[super dealloc];
}


#pragma mark -
#pragma mark Video Processing
#pragma mark -

- (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections
{
	for ( AVCaptureConnection *connection in connections ) {

		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return [[connection retain] autorelease];
			}
		}
	}
	return nil;
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {		
    
	/*
	static double stime = 0.0, ctime = 0.0, dtime = 0.0;
	static double count = 0.0;
	count += 1.0;
		
	if (stime == 0.0) {
		stime = CACurrentMediaTime();
	}
	
	ctime = CACurrentMediaTime();
	dtime = ctime - stime ;
	
	if (dtime > 1.0) {
		NSLog(@"FPS: %f", count / dtime);
		stime = ctime;
		count = 0;
	}
	*/
	
	
	//stime = ctime;
	
    if(encode) {
        if (backFacingCameraActive) {
            [avcEncoder encode:sampleBuffer];
        }
        else {
            //flipBuffer(sampleBuffer, pixelBuffer);
			//rotate180(sampleBuffer, pixelBuffer);
			//NSLog(@"angle: %d", self.rotationAngle);
			CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
			[videoProcessor processCameraFrame:imageBuffer rotationAngle:self.rotationAngle adjustAspectRatio:(self.rotationAngle == 270 || self.rotationAngle == 90)];
			
            [avcEncoder encode:sampleBuffer];
        }
    }
}

#pragma mark -
#pragma mark Encoding and capturing controll
#pragma mark -

- (void) startCapture {
	[self.captureSession startRunning];
	captureRunning = YES;
}

-(void) stopCapture{	
	[self.captureSession stopRunning];
	captureRunning = NO;
}

- (void) startEncoding{
    if(self.encode) { return;}
    // Set the flag on the capture queue.
    dispatch_sync(capture_queue, ^{
        self.encode = YES;
    });
}

- (void) stopEncoding  {
    if(!self.encode) { return;}
    // Set the flag on the caputre queue.
    dispatch_sync(capture_queue, ^{
        self.encode = NO;
    });   
}

#pragma mark -
#pragma mark Video capture setup
#pragma mark -


- (void) addVideoInput {
	
	AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];	
	
	if ( videoDevice ) {
		NSError *error;
		self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];	
		
		[self.captureSession addInput:self.videoInput];	
	}
}

- (NSUInteger) frameRate {
    return frameRate;
}

- (void) setFrameRate:(NSUInteger)fr {
    frameRate = fr;
    if (!videoOutput) {
        return;
    }
    [captureSession beginConfiguration];
    videoOutput.minFrameDuration = CMTimeMake(1, frameRate);
    [captureSession commitConfiguration];
}

- (void) addVideoDataOutput {
	
	videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    //TODO: This can cause sync issues if set to NO. Figure out why. Is it encoder backup????
	[videoOutput setAlwaysDiscardsLateVideoFrames:NO];
	videoOutput.minFrameDuration = CMTimeMake(1, frameRate);
	
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    //NSDictionary *videoSettings = nil;
	[videoOutput setVideoSettings:videoSettings]; 
	[videoOutput setSampleBufferDelegate:self queue:capture_queue];
	
	if ([self.captureSession canAddOutput:videoOutput])
		[self.captureSession addOutput:videoOutput];
	else
		NSLog(@"Couldn't add video output");	
	
	dispatch_release( capture_queue );
}

#pragma mark -
#pragma mark Device Settings
#pragma mark -

- (AVCaptureDevice*) videoCaptureDevice {
    return [[self videoInput] device];
}

- (BOOL) hasTorch {
    return [[[self videoInput] device] hasTorch];
}

- (AVCaptureTorchMode) torchMode {
    return [[[self videoInput] device] torchMode];
}

- (void) setTorchMode:(AVCaptureTorchMode) torchMode {
    
    AVCaptureDevice *device = [[self videoInput] device];
    if ([device isTorchModeSupported:torchMode] && [device torchMode] != torchMode) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setTorchMode:torchMode];
            [device unlockForConfiguration];
        } else {
            //            id delegate = [self delegate];
            //            if ([delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
            //                [delegate acquiringDeviceLockFailedWithError:error];
            //            }
        }
    }
}


- (BOOL) hasFocus {
    AVCaptureDevice *device = [[self videoInput] device];
    
    return  [device isFocusModeSupported:AVCaptureFocusModeLocked] ||
    [device isFocusModeSupported:AVCaptureFocusModeAutoFocus] ||
    [device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus];
}

- (AVCaptureFocusMode) focusMode {
    return [[[self videoInput] device] focusMode];
}

- (void) setFocusMode:(AVCaptureFocusMode)focusMode {
    if (self.videoInput == nil) { return; }
    AVCaptureDevice *device = [[self videoInput] device];
    if ([device isFocusModeSupported:focusMode] && [device focusMode] != focusMode) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusMode:focusMode];
            [device unlockForConfiguration];
        } else {
            //            id delegate = [self delegate];
            //            if ([delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
            //                [delegate acquiringDeviceLockFailedWithError:error];
            //            }
        }    
    }
}

- (BOOL) hasExposure {
    if (self.videoInput == nil) { return NO; }
    AVCaptureDevice *device = [[self videoInput] device];
    
    return  [device isExposureModeSupported:AVCaptureExposureModeLocked] ||
    [device isExposureModeSupported:AVCaptureExposureModeAutoExpose] ||
    [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure];
}

- (AVCaptureExposureMode) exposureMode {
    return [[[self videoInput] device] exposureMode];
}

- (void) setExposureMode:(AVCaptureExposureMode)exposureMode
{
    if (self.videoInput == nil) { return; }
    AVCaptureDevice *device = [[self videoInput] device];
    if ([device isExposureModeSupported:exposureMode] && [device exposureMode] != exposureMode) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setExposureMode:exposureMode];
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error Setting Exposure: %@", [error localizedDescription] );
            //            id delegate = [self delegate];
            //            if ([delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
            //                [delegate acquiringDeviceLockFailedWithError:error];
            //            }
        }
    }
}


- (void) focusAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
    if (device == nil) {
        return;
    }
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:point];
            //[device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error Setting Focus: %@", [error localizedDescription] );
            //            id delegate = [self delegate];
            //            if ([delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
            //                [delegate acquiringDeviceLockFailedWithError:error];
            //            }
        }        
    }
    
}

- (void) exposureAtPoint:(CGPoint)point
{
    AVCaptureDevice *device = [[self videoInput] device];
    if (device == nil) {
        return;
    }
    
    if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setExposurePointOfInterest:point];
            //[device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [device unlockForConfiguration];
        } else {
            NSLog(@"Error Setting Exposure: %@", [error localizedDescription] );
            //            id delegate = [self delegate];
            //            if ([delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
            //                [delegate acquiringDeviceLockFailedWithError:error];
            //            }
        }
    }    
    
}

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *) frontFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *) backFacingCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (NSUInteger) cameraCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (NSUInteger) micCount {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] count];
}

- (BOOL) hasMultipleCameras {
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 1 ? YES : NO;
}

- (BOOL) cameraToggle {
    BOOL success = NO;
    
    if ([self hasMultipleCameras]) {
        NSError *error;
        //AVCaptureDeviceInput *videoInput = [self videoInput];
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = [[videoInput device] position];
        
        if (position == AVCaptureDevicePositionBack) {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontFacingCamera] error:&error];
            [self setTorchMode:AVCaptureTorchModeOff];
            self.videoOutput.alwaysDiscardsLateVideoFrames = YES;
            backFacingCameraActive = NO;
        } else if (position == AVCaptureDevicePositionFront) {
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:&error];
            self.videoOutput.alwaysDiscardsLateVideoFrames = NO;
            backFacingCameraActive = YES;
        } else {
            goto bail;
        }
        
        AVCaptureSession *session = [self captureSession];
        if (newVideoInput != nil) {
            [session beginConfiguration];
            [session removeInput:videoInput];
            if ([session canAddInput:newVideoInput]) {
                [session addInput:newVideoInput];
                [self setVideoInput:newVideoInput];
            } else {
                [session addInput:videoInput];
            }
            [session commitConfiguration];
            success = YES;
            [newVideoInput release];
        } else if (error) {
            //            id delegate = [self delegate];
            //            if ([delegate respondsToSelector:@selector(someOtherError:)]) {
            //                [delegate someOtherError:error];
        }
    }
    
    
bail:
    return success;
}


@end

