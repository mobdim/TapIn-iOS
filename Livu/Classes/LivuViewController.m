//
//  LivuViewController.m
//  Livu
//
//  Created by Steve on 12/26/10.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreGraphics/CoreGraphics.h>
#import "SignupViewController.h"
#import <QuartzCore/QuartzCore.h>

#import "LivuViewController.h"
#import "LivuBroadcastConfig.h"
#import "LivuBroadcastProfile.h"
#import "LivuConfigViewController.h"
#import "LivuBroadcastManager.h"
#import "LivuCaptureManager.h"
#import "LivuView.h"
#import "AVCEncoder.h"
#import "AACEncoder.h"
#import "SUIMaxSlider.h"
#import "LivuViewController+MessageHandlers.h"
#import "LivuViewController+Reachability.h"
#include "sm_math.h"
#import "SHK.h"
#import "SHKTwitter.h"
#import "SHKTwitterForm.h"
#import "UserViewController.h"
#import "SHKFacebook.h"

#define kIPadScale 1

static const unichar delta = 0x0394 ;


@interface LivuViewController (CameraViewDelegateImpl) <LivuViewDelegate>
@end


@interface LivuViewController (CameraViewHelperMethods)
- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (void) focusAtPoint:(CGPoint)point;
- (void) exposureAtPoint:(CGPoint)point;
+ (void)addAdjustingAnimationToLayer:(CALayer *)layer removeAnimation:(BOOL)remove;
+ (CGRect)cleanApertureFromPorts:(NSArray *)ports;
+ (CGSize)sizeForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize;
- (void)drawFocusBoxAtPointOfInterest:(CGPoint)point;
- (void)drawExposeBoxAtPointOfInterest:(CGPoint)point;
-(void)updateUserData;
- (void) throttleBroadcast;
@end

@interface LivuViewController ()
@property (nonatomic, retain) LivuConfigViewController *configViewController;
- (void) setupVideoPreviewLayer;
- (void) removeVideoPreviewLayer;
- (void) showActivityIndicator;
- (void) hideActivityIndicator;

@end



@implementation LivuViewController

@synthesize previewLayer, broadcastButton, configButton, log, configViewController;
@synthesize focusBox, exposeBox, torchButton, backgroundImage, previewButton, cameraButton;
@synthesize microphoneButton;
@synthesize deltaQS;
@synthesize streamBitrate, videoBitrate;
@synthesize broadcaster;
@synthesize logView, buttonPanel;
@synthesize status;
@synthesize captureManager;
@synthesize avcEncoder;
@synthesize aacEncoder;
@synthesize bitrateSlider;
@synthesize bitrateSliderView;

#pragma mark -
#pragma mark UIView methods
#pragma mark -

-(IBAction) shareButton:(id)sender
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://tapin.tv/#video/%@/", [Utilities userDefaultValueforKey:@"laststream"]]];
	SHKItem *item = [SHKItem URL:url title:@"Check out my video @TapInTV"];
    [SHKTwitter shareItem:item];
}

- (void) viewWillAppear:(BOOL)animated {
    [[Utilities sharedInstance] setDelegate:self];
    if([Utilities userDefaultValueforKey:@"user"])
    {
        NSTimer* theTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                             target:self
                                                           selector:@selector(updateUserData)
                                                           userInfo:nil
                                                            repeats:YES];
    }
    
	LivuBroadcastProfile *profile = [LivuBroadcastConfig activeProfile];
	loadingContainer.layer.cornerRadius = 15;
   
    self.broadcastButton.enabled = NO;
    self.configButton.enabled = NO;
    self.torchButton.hidden = NO;
    self.torchButton.selected = NO;
    self.torchButton.enabled = YES;
    self.cameraButton.hidden = NO;
	self.bitrateSlider.hidden = YES;
	self.bitrateSliderView.hidden = YES;


	if(profile.broadcastType == kBroadcastTypeAudio) {
	   self.bitrateSlider.hidden = YES;
	   self.bitrateSliderView.hidden = YES;
	}	   
}

- (void) viewDidAppear:(BOOL)animated {
    
    LivuBroadcastProfile *profile = [LivuBroadcastConfig activeProfile];
    
    if ([profile.address length] == 0) {
        [self openConfig:nil];
        return;
    }
    
    self.captureManager = [[[LivuCaptureManager alloc] init] autorelease];
    captureManager.frameRate = profile.frameRate;
	
	if(profile.broadcastType == kBroadcastTypeAudioVideo || profile.broadcastType == kBroadcastTypeVideo) {
		[captureManager startCapture];
		self.previewLayer.session = captureManager.captureSession;
		[self.view.layer insertSublayer:self.previewLayer atIndex:1];
	}
	
    //[self.view.layer insertSublayer:self.previewLayer atIndex:1];
    captureManager.avcEncoder = avcEncoder;
    
    self.broadcastButton.enabled = YES;
    self.configButton.enabled = YES;
    
    if([self remoteHostStatus] == ReachableViaWWAN && profile.broadcastOption > kBroadcastOptionMed) {
        profile.broadcastOption = kBroadcastOptionMed;
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: NSLocalizedString(@"Limit", @"")
                              message: NSLocalizedString(@"Large format video is not supported over cellular connections. The video setting has been reduced to 480x360", @"")
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    
    int bps = broadcastBitrates[profile.broadcastOption] * profile.bitrateScalar;
    self.videoBitrate.text = [NSString stringWithFormat:@"Video %dkbps", bps / 1000];
    
}

- (void) viewWillDisappear:(BOOL)animated {
    //Save bitrate adjustement.
    [LivuBroadcastConfig save];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.previewLayer removeFromSuperlayer];
    [captureManager stopCapture];
    self.captureManager = nil;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	switch (toInterfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            if ([self.captureManager.videoCaptureDevice position] != AVCaptureDevicePositionBack) {
                self.captureManager.rotationAngle = 270;
            } else { 
                self.captureManager.rotationAngle = 90;
            }
            break;
        case UIInterfaceOrientationLandscapeRight:
            if ([self.captureManager.videoCaptureDevice position] == AVCaptureDevicePositionBack) {
                self.captureManager.rotationAngle = 270;
            } else { 
                self.captureManager.rotationAngle = 90;
            }
            break;
        case UIInterfaceOrientationPortrait:
            self.captureManager.rotationAngle = 0;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            self.captureManager.rotationAngle = 180;
            break;
    }
    
    
	//    return NO;
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
		return YES ; 
    }
    return NO ;
	
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
       return YES ; 
    }
    return NO ;
}

-(void)updateUserData {
    [[Utilities sharedInstance] sendGet:[NSString stringWithFormat:@"web/get/user/%@", [Utilities userDefaultValueforKey:@"user"]] params:NULL];
}

- (void) willResignActive {
    willResignActive = TRUE;
	if(broadcaster.broadcasting)
		[self toggleBroadcast:self.broadcastButton];
}

- (void) didBecomeActive {
    if (willResignActive) {
		if(!broadcaster.broadcasting) {
			[self toggleBroadcast:self.broadcastButton];
			willResignActive = NO;
		}
    }
}

- (void) willEnterBackground {
	if(broadcaster.broadcasting)
		[self toggleBroadcast:self.broadcastButton];
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
//    twitterButton.hidden = YES;
//    twitterButton.enabled = NO;
    progressContainer.layer.borderColor = [UIColor whiteColor].CGColor;
    progressContainer.layer.borderWidth = 1.0f;
    progressBar.layer.borderColor = [UIColor clearColor].CGColor;
    progressBar.layer.borderWidth = 1.0f;

    [self updateUserData];
    willResignActive = NO;
    
    self.configViewController = [[LivuConfigViewController alloc] initWithNibName:@"LivuConfigViewController" bundle:nil];
    
    AudioSessionInitialize(NULL, NULL, NULL, self);
	
    //	//set the audio category
	UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
	AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory);
	AudioSessionSetActive(YES);
    
    self.log.font = [UIFont fontWithName:@"Helvetica" size:10.0];
    
    self.broadcaster = [[[LivuBroadcastManager alloc] init] autorelease];
    [self.broadcaster setCallback:[self broadcastCallback] onQueue:dispatch_get_main_queue()];
    
    self.avcEncoder = [[[AVCEncoder alloc] init] autorelease];
    avcEncoder.callback = broadcaster.avcEncoderCallback;
	avcEncoder.maxBitrate = 0;
	
    self.aacEncoder = [[[AACEncoder alloc] init] autorelease];
    aacEncoder.delegate = broadcaster;
	
    
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:nil];
    self.previewLayer.frame = CGRectMake(0, 0, 480, 320); //videoView.bounds; // Assume you want the preview layer to fill the view.
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.orientation =  AVCaptureVideoOrientationLandscapeRight;
    self.previewLayer.automaticallyAdjustsMirroring = YES;
    
    
    
    //self.bitrateSlider = [[SUIMaxSlider alloc] initWithFrame:CGRectMake(0, 270.0, 240.0, 30.0)];
    //[self.view.layer addSublayer:bitrateSlider.layer];
    //TODO: setup value with profile setting.
    //[bitrateSlider setBackgroundColor:[UIColor clearColor]];
    bitrateSlider.maximumValue = 1.0;
    bitrateSlider.minimumValue = 0.2;
    bitrateSlider.value = [LivuBroadcastConfig activeProfile].bitrateScalar;
//    [bitrateSlider addTarget:self action:@selector(changeBitrate:) forControlEvents:UIControlEventTouchUpInside];
//    [bitrateSlider addTarget:self action:@selector(changingBitrate:) forControlEvents:UIControlEventTouchDragInside];
//    [bitrateSlider addTarget:self action:@selector(changingBitrate:) forControlEvents:UIControlEventTouchDragOutside];
    
    
    NSDictionary *unanimatedActions = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNull null], @"bounds",[NSNull null], @"frame",[NSNull null], @"position", nil];
	CALayer *_focusBox = [[CALayer alloc] init];
	[_focusBox setActions:unanimatedActions];
	[_focusBox setBorderWidth:3.f];
	[_focusBox setBorderColor:[[UIColor colorWithRed:1.f green:1.f blue:1.f alpha:.8f] CGColor]];
	[_focusBox setOpacity:0.f];
	[self.view.layer addSublayer:_focusBox];
	[self setFocusBox:_focusBox];
	[_focusBox release];
	
	
	CALayer *_exposeBox = [[CALayer alloc] init];
	[_exposeBox setActions:unanimatedActions];
	[_exposeBox setBorderWidth:3.f];
	[_exposeBox setBorderColor:[[UIColor colorWithRed:0.f green:9.f blue:1.f alpha:.8f] CGColor]];
	[_exposeBox setOpacity:0.f];
	[self.view.layer addSublayer:_exposeBox];
	[self setExposeBox:_exposeBox];
	[_exposeBox release];
	[unanimatedActions release];
    
    [self setupReachability];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bitRateUpdate:) name:@"bitrate" object:nil];
}

- (void)viewDidUnload {
    self.broadcastButton = nil; self.previewLayer = nil; self.configButton = nil; 
    self.exposeBox = nil; self.focusBox = nil; self.torchButton = nil;
    self.configViewController = nil; self.backgroundImage = nil; self.log = nil;
    self.microphoneButton = nil; self.streamBitrate = nil; self.streamBitrate = nil;
    self.deltaQS = nil; self.broadcaster = nil; self.buttonPanel = nil;
    self.aacEncoder = nil; self.avcEncoder = nil; self.captureManager = nil;
    
    [LivuBroadcastConfig save];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction) userButtonToucehd:(id)sender
{
    if(![Utilities userDefaultValueforKey:@"token"])
    {
        SignupViewController * vc = [[SignupViewController alloc]init];
        [self presentModalViewController:vc animated:YES];
    }
    UserViewController * vc = [[UserViewController alloc]init];
    [self presentModalViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark
#pragma mark -

- (void) uiMessage:(NSString*) message {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        //This is some ugly code. There has to be a better way.
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [UIView animateWithDuration:0.25f
                             animations:^{
                                 self.status.alpha = 1.0;
                                 self.status.text = message;
                             }
                             completion:^(BOOL finished) {
                                 double delayInSeconds = 3.0;
                                 dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                 dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                     [UIView animateWithDuration:0.25f
                                                      animations:^{
                                                          self.status.alpha = 0.0;
                                                          self.status.text = message;
                                                      }
                                                      completion:^(BOOL finished) {
                                                          
                                                      }];
                                 });
                             }];
            
        });
    });
}


- (void) bitRateUpdate:(NSNotification *)notify {
	id data = [notify userInfo];
    NSString *bitrate = [data objectForKey:@"bitrate"];
    self.streamBitrate.text = bitrate;

    LivuBroadcastProfile* profile = [LivuBroadcastConfig activeProfile]; 
    if (profile.autoBitrateAdjust) {
        float brs = [[data objectForKey:@"bitrateScalar"] floatValue];
        profile.bitrateScalar = brs;
        self.bitrateSlider.value = brs;
        int bps = broadcastBitrates[[LivuBroadcastConfig activeProfile].broadcastOption] * brs;
        self.videoBitrate.text = [NSString stringWithFormat:@"Video %dkbps", bps / 1000]; 
    }
}


#pragma mark -
#pragma mark UI Handlers
#pragma mark -


- (IBAction)facebookButtonTouched:(id)sender 
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://tapin.tv/#video/%@/", [Utilities userDefaultValueforKey:@"laststream"]]];
	SHKItem *item = [SHKItem URL:url title:@"Check out my video @TapInTV"];
    [SHKFacebook shareItem:item];

}

- (void) setupVideoPreviewLayer  {
    
    AVCaptureSession *session = captureManager.captureSession;
    self.previewLayer.session = session;
    
    [self.view.layer setMasksToBounds:YES];
    [self.view.layer insertSublayer:self.previewLayer below:[[self.view.layer sublayers] objectAtIndex:0]];
    
    [CATransaction begin];
	CATransition *animation = [CATransition animation];
    //animation.type = kCATransitionFade;
	animation.type = kCATransitionFade;
	animation.duration = 2.0;
	
	self.backgroundImage.hidden = YES ;
	
	[[self.view layer] addAnimation:animation forKey:@"myanimationkey"];
    [[self.backgroundImage layer] addAnimation:animation forKey:@"testanimation"];
	[CATransaction commit];
    
}

- (void) removeVideoPreviewLayer {
    [CATransaction begin];
	CATransition *animation = [CATransition animation];
    //animation.type = kCATransitionFade;
	animation.type = kCATransitionFade;
	animation.duration = 2.0;
	
	self.backgroundImage.hidden = NO ;
	
	[[self.view layer] addAnimation:animation forKey:@"myanimationkey"];
    [[self.backgroundImage layer] addAnimation:animation forKey:@"testanimation"];
	[CATransaction commit];
    
    [self.previewLayer removeFromSuperlayer];
    self.previewLayer.session = nil;
    //self.previewLayer = nil;
}

- (IBAction) toggleToolbar:(UIButton*) sender {
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                CGRect frame = self.buttonPanel.frame;
                frame.origin.x = -frame.size.width;
                self.buttonPanel.frame = frame;
            }
            completion:^(BOOL done){ }
        ];
    }
    else {
        [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect frame = self.buttonPanel.frame;
            frame.origin.x = 0;
            self.buttonPanel.frame = frame;
        }
        completion:^(BOOL done){ }
        ];
    }
}

- (IBAction) openConfig:(id) sender {
    [self presentModalViewController:self.configViewController animated:YES];
//    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut 
//                    animations:^{
//                        CGRect frame = self.configViewController.view.frame;
//                        frame.origin.x = 0;
//                        self.configViewController.view.frame = frame;
//                    }
//                    completion:^(BOOL done){ }
//    ];
}

- (IBAction) toggleTorch:(UIButton*) sender {
    
//    if ( ! broadcaster.isRecording) { return ; }
    
    sender.selected = !sender.selected;
    if (sender.selected) {
        [captureManager setTorchMode:AVCaptureTorchModeOn];
    }
    else {
        [captureManager setTorchMode:AVCaptureTorchModeOff];
    }
}

-(void)showActivityIndicator
{
        [UIView animateWithDuration:.5
                         animations:^{
                             activity.hidden = NO;
                             [activity startAnimating];
                             loadingContainer.hidden = NO;
                             [activity setAlpha:1];
                             [loadingContainer setAlpha:.75f];
                         } 
                         completion:^(BOOL finished){
                         }];
}

-(void)hideActivityIndicator
{
            [UIView animateWithDuration:.5
                         animations:^{
                             [activity setAlpha:0];
                             [loadingContainer setAlpha:0];

                         } 
                         completion:^(BOOL finished){
                             activity.hidden = YES;
                             loadingContainer.hidden = YES;
                             [activity stopAnimating];
                         }];
}

- (void) throttleBroadcast 
{
    broadcastButton.enabled = YES;
}

- (IBAction) toggleBroadcast:(UIButton*) sender {
    
    //TODO: We should not set it here. Let the call back set it.
    //      Move property settings into callback
    
    broadcastButton.enabled = NO;
    if([self remoteHostStatus] == NotReachable) {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle: NSLocalizedString(@"Error", @"")
                              message: NSLocalizedString(@"A network connection is required", @"")
                              delegate: nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return ;
    }
    
    if (!sender.selected) {
        self.broadcastButton.imageView.image = [UIImage imageNamed:@"recordstart"];
        [self performSelector:@selector(throttleBroadcast) withObject:nil afterDelay:12.0f];
        [self showActivityIndicator];
        [[Utilities sharedInstance] setStreamID:@""]; //reset the streamID 
        [[Utilities sharedInstance] startLocationService];
        
    }
    else {
        self.broadcastButton.imageView.image = [UIImage imageNamed:@"recordbutton"];
        self.broadcastButton.enabled = YES;
        [captureManager stopEncoding];
        [avcEncoder stop];
        [aacEncoder stop];
        [broadcaster disconnect];
		
        self.previewButton.enabled = NO;
        self.previewButton.selected = NO;
        self.configButton.enabled = YES;
        self.torchButton.enabled = YES;
        self.torchButton.hidden = NO;
        self.cameraButton.hidden = NO;
        if(![Utilities userDefaultValueforKey:@"user"]){
            SignupViewController * vc = [[SignupViewController alloc]init];
            [self presentModalViewController:vc animated:YES];
        }
    }
    
}

- (IBAction) toggleMicrophone:(UIButton*) sender {
    sender.selected = !sender.selected;
    [self.aacEncoder mute:sender.selected];
}

- (IBAction) toggleCamera:(UIButton*) sender {
    
    sender.selected = !sender.selected;
    
    [captureManager cameraToggle];
    if (self.cameraButton.selected) {
        [captureManager setTorchMode:AVCaptureTorchModeOff];
        self.torchButton.selected = NO;
        self.torchButton.enabled = NO;
    }                                                     
    else {
        self.torchButton.enabled = YES;
        if(self.torchButton.selected) {
            [captureManager setTorchMode:AVCaptureTorchModeOn];
        }
    }
}

- (IBAction) closeLog:(id) sender {
    self.logView.hidden = YES;
}

- (IBAction) changingBitrate:(SUIMaxSlider*) sender {
    int bps = broadcastBitrates[[LivuBroadcastConfig activeProfile].broadcastOption] * sender.value;
    self.videoBitrate.text = [NSString stringWithFormat:@"Video %dkbps", bps / 1000]; 
}

- (IBAction) changeBitrate:(SUIMaxSlider*) sender {
    LivuBroadcastProfile *profile = [LivuBroadcastConfig activeProfile];
    int bps = (broadcastBitrates[profile.broadcastOption] * sender.value);// / kIPadScale;
    self.videoBitrate.text = [NSString stringWithFormat:@"Video %dkbps", bps / 1000]; 
    profile.bitrateScalar = sender.value;
    self.avcEncoder.averagebps = bps;
}


#pragma mark -
#pragma mark Logging 
#pragma mark -

- (void) displayInfo:(NSString*) msg {
    
}

- (void) log:(NSString *)text {
	
	log.text= [log.text stringByAppendingString:text];
	log.text= [log.text stringByAppendingString:@"\n"];
	
	NSRange range;
	range.location= [log.text length] - 6;
	range.length = 5;
	[log scrollRangeToVisible:range];
}

@end

#pragma mark -
#pragma mark LivuBroadcastManagerDelegate Impl.
#pragma mark -



#pragma mark -
#pragma mark CameraViewHelperMethods
#pragma mark -

@implementation LivuViewController (CameraViewHelperMethods)


- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates {
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = [[self view] frame].size;
    
    AVCaptureVideoPreviewLayer *videoPreviewLayer = self.previewLayer;
    AVCaptureSession *captureSession = videoPreviewLayer.session;
	
	if(captureSession == nil)
		return CGPointMake(0, 0);
    
    if ([videoPreviewLayer isMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }    
    
    if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
		for (AVCaptureInput *input in [captureSession inputs] ){
            
            
			for (AVCaptureInputPort *port in [input ports]) {
				if ([port mediaType] == AVMediaTypeVideo) {
					cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
					CGSize apertureSize = cleanAperture.size;
					CGPoint point = viewCoordinates;
					
					CGFloat apertureRatio = apertureSize.height / apertureSize.width;
					CGFloat viewRatio = frameSize.width / frameSize.height;
					CGFloat xc = .5f;
					CGFloat yc = .5f;
					
					if ( [[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
						if (viewRatio > apertureRatio) {
							CGFloat y2 = frameSize.height;
							CGFloat x2 = frameSize.height * apertureRatio;
							CGFloat x1 = frameSize.width;
							CGFloat blackBar = (x1 - x2) / 2;
							if (point.x >= blackBar && point.x <= blackBar + x2) {
								xc = point.y / y2;
								yc = 1.f - ((point.x - blackBar) / x2);
							}
						} else {
							CGFloat y2 = frameSize.width / apertureRatio;
							CGFloat y1 = frameSize.height;
							CGFloat x2 = frameSize.width;
							CGFloat blackBar = (y1 - y2) / 2;
							if (point.y >= blackBar && point.y <= blackBar + y2) {
								xc = ((point.y - blackBar) / y2);
								yc = 1.f - (point.x / x2);
							}
						}
					} else if ([[videoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
						if (viewRatio > apertureRatio) {
							CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
							xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2;
							yc = (frameSize.width - point.x) / frameSize.width;
						} else {
							CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
							yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2);
							xc = point.y / frameSize.height;
						}
						
					}
					
					pointOfInterest = CGPointMake(xc, yc);
					break;
				}
			}
		}
    }
    
    return pointOfInterest;
}

- (void) focusAtPoint:(CGPoint)point
{
    LivuBroadcastProfile *profile = [LivuBroadcastConfig activeProfile];
//    if(profile.broadcastType == kBroadcastTypeAudioOnly)
//        return;
    
    AVCaptureDevice *device = captureManager.videoCaptureDevice;
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:point];
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
        } else {
            /*
             id delegate = [self delegate];
             if ([delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
             [delegate acquiringDeviceLockFailedWithError:error];
             }
             */
        }        
    }
}

- (void) exposureAtPoint:(CGPoint)point
{
    LivuBroadcastProfile *profile = [LivuBroadcastConfig activeProfile];
//    if(profile.broadcastType == kBroadcastTypeAudioOnly)
//        return;
    
    AVCaptureDevice *device = captureManager.videoCaptureDevice;
    if ([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setExposurePointOfInterest:point];
            [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [device unlockForConfiguration];
        } else {
            /*
			 id delegate = [self delegate];
			 if ([delegate respondsToSelector:@selector(acquiringDeviceLockFailedWithError:)]) {
			 [delegate acquiringDeviceLockFailedWithError:error];
			 }
			 */
        }        
    }
}


+ (void)addAdjustingAnimationToLayer:(CALayer *)layer removeAnimation:(BOOL)remove
{
    if (remove) {
        [layer removeAnimationForKey:@"animateOpacity"];
    }
    if ([layer animationForKey:@"animateOpacity"] == nil) {
        [layer setHidden:NO];
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [opacityAnimation setDuration:.3f];
        [opacityAnimation setRepeatCount:1.f];
        [opacityAnimation setAutoreverses:YES];
        [opacityAnimation setFromValue:[NSNumber numberWithFloat:1.f]];
        [opacityAnimation setToValue:[NSNumber numberWithFloat:.0f]];
        [layer addAnimation:opacityAnimation forKey:@"animateOpacity"];
    }
}

+ (CGRect)cleanApertureFromPorts:(NSArray *)ports
{
    CGRect cleanAperture;
    for (AVCaptureInputPort *port in ports) {
        if ([port mediaType] == AVMediaTypeVideo) {
            cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
            break;
        }
    }
    return cleanAperture;
}

+ (CGSize)sizeForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
    
    return size;
}


- (void)drawFocusBoxAtPointOfInterest:(CGPoint)point
{
	if(!captureManager.captureRunning)
		return;
    
	AVCaptureDevice *device = captureManager.videoCaptureDevice;
    
    BOOL hasFocus =  [device isFocusModeSupported:AVCaptureFocusModeLocked] ||
	[device isFocusModeSupported:AVCaptureFocusModeAutoFocus] ||
	[device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus];
	
	
	if (hasFocus) {
        CGSize frameSize = [self.view frame].size;
        
        CGSize apertureSize = [LivuViewController cleanApertureFromPorts:[captureManager.videoInput ports]].size;
        
        CGSize oldBoxSize = [LivuViewController sizeForGravity:[self.previewLayer videoGravity] frameSize:frameSize apertureSize:apertureSize];
        
        CGPoint focusPointOfInterest = [[captureManager.videoInput device] focusPointOfInterest];
        CGSize newBoxSize;
        if (focusPointOfInterest.x == .5f && focusPointOfInterest.y == .5f) {
            newBoxSize.width = (116.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (158.f / frameSize.height) * oldBoxSize.height;
        } else {
            newBoxSize.width = (80.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (110.f / frameSize.height) * oldBoxSize.height;
        }
        
        CALayer *_focusBox = [self focusBox];
        [_focusBox setFrame:CGRectMake(0.f, 0.f, newBoxSize.width, newBoxSize.height)];
        [_focusBox setPosition:point];
        [LivuViewController addAdjustingAnimationToLayer:_focusBox removeAnimation:YES];
    }    
}

- (void)drawExposeBoxAtPointOfInterest:(CGPoint)point {
	
	if(!captureManager.captureRunning)
		return;
	
	AVCaptureDevice *device = captureManager.videoCaptureDevice;
    
    BOOL hasFocus =  [device isFocusModeSupported:AVCaptureFocusModeLocked] ||
	[device isFocusModeSupported:AVCaptureFocusModeAutoFocus] ||
	[device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus];
	
	
	if (hasFocus) {
        CGSize frameSize = [self.view frame].size;
        
        CGSize apertureSize = [LivuViewController cleanApertureFromPorts:[captureManager.videoInput ports]].size;
        
        CGSize oldBoxSize = [LivuViewController sizeForGravity:[self.previewLayer videoGravity] frameSize:frameSize apertureSize:apertureSize];
        
        CGPoint focusPointOfInterest = [[captureManager.videoInput device] focusPointOfInterest];
        CGSize newBoxSize;
        if (focusPointOfInterest.x == .5f && focusPointOfInterest.y == .5f) {
            newBoxSize.width = (290 / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (395.f / frameSize.height) * oldBoxSize.height;
        } else {
            newBoxSize.width = (114.f / frameSize.width) * oldBoxSize.width;
            newBoxSize.height = (154.f / frameSize.height) * oldBoxSize.height;
        }
        
        CALayer *_exposeBox = [self exposeBox];
        [_exposeBox setFrame:CGRectMake(0.f, 0.f, newBoxSize.width, newBoxSize.height)];
        [_exposeBox setPosition:point];
        [LivuViewController addAdjustingAnimationToLayer:_exposeBox removeAnimation:YES];
    }    
}

@end



#pragma mark -
#pragma mark CameraViewDelegate Impl.
#pragma mark -

@implementation LivuViewController (CameraViewDelegateImpl)

- (void)tapToFocus:(CGPoint)point {
	
	if(point.x == NAN || point.y == NAN)
		return;
    
    CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:point];
    [self focusAtPoint:convertedFocusPoint];
    [self drawFocusBoxAtPointOfInterest:point];    
    [captureManager focusAtPoint:point];
}

- (void)tapToExpose:(CGPoint)point {

    
    CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:point];
    [self exposureAtPoint:convertedFocusPoint];
    [self drawExposeBoxAtPointOfInterest:point];
    [captureManager exposureAtPoint:point];
}

- (void)resetFocusAndExpose {
}

- (void)cycleGravity {
}

#pragma mark - network utilities delegate
-(void)didCompleteHandeshake:(NSString *)streamID
{
    [self hideActivityIndicator];
    NSLog(@"delegate did fire %@", streamID);
    self.broadcastButton.selected = YES;
    [Utilities setUserDefaultValue:streamID forKey:@"laststream"];
    self.configButton.enabled = NO;
    twitterButton.enabled = YES;
    twitterButton.hidden = NO;
    self.cameraButton.hidden = NO;
    self.torchButton.hidden = NO;
    self.bitrateSliderView.hidden = YES;
    self.bitrateSlider.hidden = YES;
    
    [self uiMessage:NSLocalizedString(@"Connecting", @"")];
    
    [UIView animateWithDuration:0.25f
                     animations:^{
                         self.status.alpha = 1.0;
                         self.status.text = NSLocalizedString(@"Connecting", @"");
                     }
                     completion:nil];
    
    LivuBroadcastProfile* profile = [LivuBroadcastConfig activeProfile]; 
     profile.address = @"ca1.stream.tapin.tv";
    profile.application = [NSString stringWithFormat:@"/live/%@/stream", streamID];
    NSLog(@"address: %@", profile.address);
    NSLog(@"application: %@", profile.application);
    NSLog(@"profile: %@", [profile description]);

    
    if(profile.broadcastType == kBroadcastTypeAudioVideo || profile.broadcastType == kBroadcastTypeVideo) {
        AVCParameters *params = [[AVCParameters alloc] init];
        //NSLog(@" %dx%d", profile.broadcastWidth, profile.broadcastHeight);
        params.outWidth = profile.broadcastWidth;
        params.outHeight = profile.broadcastHeight;
        params.videoProfileLevel = AVVideoProfileLevelH264Baseline30;
        params.bps = (broadcastBitrates[profile.broadcastOption] * profile.bitrateScalar);// / kIPadScale;
        params.keyFrameInterval = profile.keyFrameInterval;
        avcEncoder.parameters = params;
        
        if(![avcEncoder prepareEncoder]) {
            NSLog(@"Encoder Error: %@", avcEncoder.error);
        }
        broadcaster.spspps = avcEncoder.spspps;
        broadcaster.pps = avcEncoder.pps;
        broadcaster.sps = avcEncoder.sps;
        //NSLog(@"%@", avcEncoder.sps);
        //[broadcaster setEncoder:avcEncoder];
        
        [avcEncoder start];
    }
    [broadcaster connect:profile];
    //Start these in callback when connection is started.
    
    self.streamBitrate.text = @"";
    
    self.previewButton.enabled = YES;
}

- (void) responseDidSucceed:(NSDictionary*)data {
    NSLog(@"%@", [data description]);
    userTitle.text = [data objectForKey:@"title"];
    if([data objectForKey:@"points"])
    {
        progressContainer.hidden = NO;
        userPoints.hidden = NO;
        nextTitle.hidden = NO;
        userTitle.hidden = NO;
        
        userPoints.text = [NSString stringWithFormat:@"%@ pts", [data objectForKey:@"points"]];
        nextTitle.text = [NSString stringWithFormat:[data objectForKey:@"nexttitle"]];
        progressBar.frame = CGRectMake(progressBar.frame.origin.x, progressBar.frame.origin.y, (150 * ([[data objectForKey:@"points"] floatValue] / [[data objectForKey:@"next"] floatValue])), progressBar.frame.size.height);
    }
}

-(void)handshakeDidFailWithErrors:(NSString *)error
{
    NSLog(@"%@", error);
}


@end
