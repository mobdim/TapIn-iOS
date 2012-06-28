//
//  LivuViewController.h
//  Livu
//
//  Created by Steve on 12/26/10.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"

@class SUIMaxSlider, LivuConfigViewController, LivuCaptureManager, LivuBroadcastManager, AVCaptureVideoPreviewLayer, LivuVideoView;
@class AVCEncoder, AACEncoder, SUIMaxSlider;

@interface LivuViewController : UIViewController <NetworkUtilitiesDelegate> {

    UIButton *broadcastButton;
    UIButton *configButton;
    UIButton *torchButton;
    UIButton *previewButton;
    UIButton *microphoneButton;
    UIButton *cameraButton;
    UITextView *log;
    UIView *logView;
    UIView *buttonPanel;
	UIView *bitrateSilderView;
    UIImageView *backgroundImage;
    IBOutlet UIButton * twitterButton;
    IBOutlet UILabel * userTitle;
    IBOutlet UILabel * userPoints;
    IBOutlet UILabel * nextTitle;
    IBOutlet UIButton * facebookButton;
    IBOutlet UIImageView * progressBar;
    UILabel *streamBitrate, *videoBitrate;
    UILabel *status;
    IBOutlet UILabel *helperText;
    IBOutlet UIView * loadingContainer;
    IBOutlet UIActivityIndicatorView * activity;
    IBOutlet UIView * progressContainer;
    IBOutlet UILabel * activityText;
    IBOutlet UILabel * viewerCount;
    
        
    SUIMaxSlider                *bitrateSlider;
    LivuConfigViewController    *configViewController;
    AVCaptureVideoPreviewLayer  *previewLayer;
    LivuBroadcastManager        *broadcaster;
    LivuCaptureManager          *captureManager;
    AACEncoder                  *aacEncoder;
    AVCEncoder                  *avcEncoder;
    CALayer						*focusBox;
	CALayer						*exposeBox;
    
    //What do these do?
    BOOL    toolbarVisisble;
    BOOL    willResignActive;
    
}
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, retain) IBOutlet UIButton *broadcastButton, *configButton, *torchButton, *previewButton, *microphoneButton, *cameraButton;
@property (nonatomic, retain) IBOutlet UITextView *log;
@property (nonatomic, retain) IBOutlet UIView *logView, *buttonPanel, *bitrateSliderView;
@property (nonatomic, retain) CALayer *focusBox, *exposeBox;
@property (nonatomic, readonly, retain) LivuConfigViewController *configViewController;
@property (nonatomic, retain) IBOutlet UIImageView *backgroundImage;
@property (nonatomic, retain) IBOutlet UILabel *deltaQS;
@property (nonatomic, retain) IBOutlet UILabel *streamBitrate, *videoBitrate;
@property (nonatomic, retain) IBOutlet UILabel *status;
@property (nonatomic, retain) IBOutlet SUIMaxSlider *bitrateSlider;
@property (nonatomic, retain) LivuBroadcastManager *broadcaster;
@property (nonatomic, retain) LivuCaptureManager *captureManager;
@property (nonatomic, retain) AACEncoder *aacEncoder;
@property (nonatomic, retain) AVCEncoder *avcEncoder;
@property (nonatomic, retain) IBOutlet UIButton * twitterButton;

- (IBAction) openConfig:(id) sender;
- (IBAction) toggleBroadcast:(UIButton*) sender;
- (IBAction) toggleTorch:(UIButton*) sender;
- (IBAction) togglePreview:(UIButton*) sender;
- (IBAction) toggleMicrophone:(UIButton*) sender;
- (IBAction) toggleCamera:(UIButton*) sender;
- (IBAction) closeLog:(id) sender;
- (IBAction) toggleToolbar:(UIButton*) sender;
- (IBAction) changeBitrate:(id) sender;
- (IBAction) changingBitrate:(SUIMaxSlider*) sender;
- (IBAction) userButtonToucehd:(id)sender;
- (IBAction)facebookButtonTouched:(id)sender;

-(void) startUserTimer;
- (void) uiMessage:(NSString*) message;

- (void) willResignActive;
- (void) didBecomeActive;
- (void) willEnterBackground;

- (void) log:(NSString *)text;
- (void) displayInfo:(NSString*) msg;




@end

