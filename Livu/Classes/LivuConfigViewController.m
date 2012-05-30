//
//  LivuConfigViewController.m
//  Livu
//
//  Created by Steve on 12/27/10.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import "LivuConfigViewController.h"
#import "LivuBroadcastConfig.h"
#import "LivuBroadcastProfile.h"
#import "UIView+TextUtil.h"
#import "UIButton+TextProperty.h"
#include "netutil.h"
#import "defines.h"


//This must be around 400 to 500 units larger then the frame
#define SCROLLVIEW_CONTENT_HEIGHT 300
#define SCROLLVIEW_CONTENT_WIDTH  480

#define TXT_FIELD_INDEX_MIN 0 
#define TXT_FIELD_INDEX_MAX 11

#define kVideoQualityKey        @"videoQuality"
#define kVideoOrientationKey    @"videoOrientation"


// Scroll position save
static CGPoint scrollSave;
//Hack to allow saving of view.
static BOOL isTextFieldEditing = NO;


@implementation LivuConfigViewController

@synthesize scrollView, address, port, application, user, pass, broadcastOptionButtton, videoOrientation;
@synthesize useTCP, frameRate, keyFrameInterval, autoBitrateAdjust;
@synthesize bitrateSettingLabel, broadcastTypeButton, autoRestart;

#pragma mark -
#pragma mark UIViewController Methods
#pragma mark -

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        return YES ; 
    }
    return NO ;
}

- (void) viewWillAppear:(BOOL)animated {

    CGSize size = self.view.bounds.size; 
	size.height = SCROLLVIEW_CONTENT_HEIGHT;
    size.width = SCROLLVIEW_CONTENT_WIDTH;
    (self.scrollView).contentSize = size; 

    [self loadConfig];

    [[NSNotificationCenter defaultCenter] addObserver:self  
                                             selector:@selector(keyboardWillShow:)  
                                                 name:UIKeyboardWillShowNotification  
                                               object:nil];
    
	[[NSNotificationCenter defaultCenter] addObserver:self  
											 selector:@selector(keyboardWillHide:)  
												 name:UIKeyboardWillHideNotification  
											   object:nil];
}

- (void) viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    
}

/*
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.scrollView = nil; self.address = nil; self.port = nil; self.application = nil; self.user = nil; self.pass = nil;
    self.videoOrientation = nil; self.autoBitrateAdjust = nil;
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark -
#pragma mark UI Handlers
#pragma mark -


/**
 */
- (void)keyboardWillShow:(NSNotification *)notification {
    
}

- (void)keyboardWillHide:(NSNotification*) note {
    
	if(!isTextFieldEditing) {
    
        [self.scrollView setContentOffset:scrollSave animated:YES];
	}
}

- (IBAction) toggleTransport:(UIButton*) sender {
    sender.selected = !sender.selected;
    
    if (sender.selected) {
        //self.autoBitrateAdjust.hidden = NO;
        //self.bitrateSettingLabel.hidden = NO;
    }
    else {
        //self.autoBitrateAdjust.hidden = YES;
        //self.bitrateSettingLabel.hidden = YES;
    }
}

- (IBAction) toggleButton:(UIButton*) sender {
    sender.selected = !sender.selected;
}

/*!
 */
- (IBAction) backgroundTap:(id) sender {
    isTextFieldEditing = NO;
    [self.view findAndResignFirstResonder];
    if(!isTextFieldEditing) {
        [self.scrollView setContentOffset:scrollSave animated:YES];
    }    
}

- (IBAction) nextQualitySetting: (id) sender {
    NSArray *qs = [LivuBroadcastConfig sharedInstance].broadcastOptions;
    
    broadcastOption =  (broadcastOption + 1) % [qs count];
    
    self.broadcastOptionButtton.text = [qs objectAtIndex:broadcastOption];
}

- (IBAction) nextBroadcastType: (id) sender {
	broadcastType = (broadcastType + 1) % kBroadcastTypeCount;
	
	self.broadcastTypeButton.text = broadcastTypes[broadcastType];
	
	if (broadcastType == kBroadcastTypeAudio) {
		self.broadcastOptionButtton.enabled = NO;
		self.keyFrameInterval.enabled = NO;
		self.frameRate.enabled = NO;
		//self.autoBitrateAdjust.enabled = NO;
	}
	else {
		self.broadcastOptionButtton.enabled = YES;
		self.keyFrameInterval.enabled = YES;
		self.frameRate.enabled = YES;
		//self.autoBitrateAdjust.enabled = YES;
	}
	
}

- (IBAction) close:(id) sender {
	[self saveConfig];
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction) cancel:(id) sender {
    [self dismissModalViewControllerAnimated:YES];
}

#pragma mark -
#pragma mark Text Field Handlers
#pragma mark -

-(BOOL) textFieldShouldBeginEditing:(UITextField*)textField {
	isTextFieldEditing = YES;
	
	// Calculate the distance to offset from where the control currently resides in screen space
	float llcrnr = (textField.frame.origin.y + textField.frame.size.height  + STATUS_BAR_HEIGHT + NAV_BAR_HEIGHT) - (self.scrollView.contentOffset.y);
	
	if (llcrnr < KEYBOARD_TOP_POINT_Y) {
		return YES;
	}
	
    // Calculate the distance to offset from the position within it's containers space
	float zero_llcrnr = (textField.frame.origin.y  + STATUS_BAR_HEIGHT + NAV_BAR_HEIGHT + textField.frame.size.height);
    // Calculate the delta between the two
	float add_to_zero = zero_llcrnr - llcrnr;
	//Set the absolute position of the scrool view
	float offset = (llcrnr + add_to_zero) - KEYBOARD_TOP_POINT_Y;
	CGPoint point = CGPointMake(0, offset);
	[self.scrollView setContentOffset:point animated:YES];
	
	return YES;
}


- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}


- (BOOL) textFieldDidBeginEditing:(UITextField *)textField {
    return YES;
}

- (IBAction) textFieldValueChanged:(UITextField*)textField {
    
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	//isTextFieldEditing = NO; // Yes this needs to be here. I don't know why at the moment. To tired... need sleep
    
    //TODO: Do we really need to do this? Seems like to much work for too litle.
    /*
    if (textField == self.serverAddr) {
        NSError *err;
        NSString *text = self.serverAddr.text;
        NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:@"^[a-zA-Z0-9\\-\\.]+\\.(com|org|net|mil|edu|COM|ORG|NET|MIL|EDU|info|INFO)$"
                                                                             options:NSRegularExpressionCaseInsensitive error:&err];
        NSUInteger count = [reg numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])];
        
        if (count == 1) {
            return;
        }
        
        reg = [NSRegularExpression regularExpressionWithPattern:@"^\\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\b"
                                    options:NSRegularExpressionCaseInsensitive error:&err];
        count = [reg numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])];
        
        if (count == 1) {
            return;
        }
        
        UIAlertView *errorAlert = [[UIAlertView alloc]
                                   initWithTitle: @"Input Error"
                                   message: @"The server address field is not valid. Please enter in an IP address or domain name."
                                   delegate:nil
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil];
        
        [errorAlert show];
        [errorAlert release];        
    }
    */
}


/**
 */
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	
    NSInteger nextTag = textField.tag + 1;
    
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
		[textField resignFirstResponder];
		[nextResponder becomeFirstResponder];
    }
    else{
        isTextFieldEditing = NO;
        
        //[textField resignFirstResponder];
        [textField resignFirstResponder];
		//[self closeKeyboard:textField];
    }
    
     //RETURN NO ALWAYS. See http://stackoverflow.com/questions/1214311/becomefirstresponder-doesnt-respect-keyboard-settings
    
    return NO;
}

#pragma mark -
#pragma mark Config Loading and Saving
#pragma mark -

- (void) loadConfig {
    //Get all the config items
    LivuBroadcastProfile *profile = [LivuBroadcastConfig activeProfile];
    NSArray *options = [LivuBroadcastConfig sharedInstance].broadcastOptions;
    
    if (profile == nil) {
        return ;
    }
    
    self.address.text = profile.address;
    self.port.text = [NSString stringWithFormat:@"%d", profile.port];
    self.application.text = profile.application;
    self.user.text = profile.user;
    self.pass.text = profile.password;
    broadcastOption = profile.broadcastOption;
    self.broadcastOptionButtton.text = [options objectAtIndex:profile.broadcastOption];
    self.useTCP.selected = profile.useTCP;
    self.frameRate.text = [NSString stringWithFormat:@"%d", profile.frameRate];
    self.keyFrameInterval.text = [NSString stringWithFormat:@"%d", profile.keyFrameInterval];
    //self.autoBitrateAdjust.selected = profile.autoBitrateAdjust;
    broadcastType = profile.broadcastType;
	self.autoRestart.selected = profile.autoRestart;
	
	self.broadcastTypeButton.text = broadcastTypes[broadcastType];
	
    if (self.useTCP.selected) {
        //self.autoBitrateAdjust.hidden = NO;
        //self.bitrateSettingLabel.hidden = NO;
    }
    else {
        //self.autoBitrateAdjust.hidden = YES;
        //self.bitrateSettingLabel.hidden = YES;
    }
	
	if (broadcastType == kBroadcastTypeAudio) {
		self.broadcastOptionButtton.enabled = NO;
		self.keyFrameInterval.enabled = NO;
		self.frameRate.enabled = NO;
		//self.autoBitrateAdjust.enabled = NO;
	}
	else {
		self.broadcastOptionButtton.enabled = YES;
		self.keyFrameInterval.enabled = YES;
		self.frameRate.enabled = YES;
		//self.autoBitrateAdjust.enabled = YES;
	}
    
}

- (void) saveConfig {
    
    LivuBroadcastProfile *profile = [LivuBroadcastConfig activeProfile];
    if (profile == nil) {
        return ;
    }
    
    profile.address = self.address.text;
    profile.port = [self.port.text intValue];
    profile.application = self.application.text;
    profile.user = self.user.text;
    profile.password = self.pass.text;
    profile.broadcastOption = broadcastOption;
    profile.useTCP = self.useTCP.selected;
    profile.frameRate = [self.frameRate.text intValue];
    profile.keyFrameInterval = [self.keyFrameInterval.text intValue];
    //profile.autoBitrateAdjust = self.autoBitrateAdjust.selected;
	profile.broadcastType = broadcastType;
	profile.autoRestart = self.autoRestart.selected;
	
	if([profile.application characterAtIndex:0] != '/') {
		profile.application = [NSString stringWithFormat:@"/%@",profile.application];
	}
	
    [LivuBroadcastConfig save];
}


@end
