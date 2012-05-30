//
//  LivuViewController.h
//  Livu
//
//  Created by Steve on 12/26/10.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SUIMaxSlider, LivuConfigViewController, LivuCaptureManager, LivuBroadcastManager, AVCaptureVideoPreviewLayer, LivuVideoView;
@class AVCEncoder, AACEncoder, SUIMaxSlider;

@interface LivuViewController : UIViewController {

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
    
    UILabel *streamBitrate, *videoBitrate;
    UILabel *status;
    
    
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

- (void) uiMessage:(NSString*) message;

- (void) willResignActive;
- (void) didBecomeActive;
- (void) willEnterBackground;

- (void) log:(NSString *)text;
- (void) displayInfo:(NSString*) msg;




@end

