//
//  LivuViewController+MessageHandlers.m
//  Livu
//
//  Created by Steve McFarlin on 5/11/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LivuBroadcastManager.h"
//#import "TCPBufferMonitor.h"
//#import "ffstream.h"

@class LivuViewController;

@interface LivuViewController (LivuViewController_MessageHandlers)

- (LivuBroadcastCallback) broadcastCallback;
//- (void) uiMessage:(NSString*) message;
- (void) resetUI;

@end
@implementation LivuViewController (LivuViewController_MessageHandlers)

- (void) resetUI {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        
    });
}

- (LivuBroadcastCallback) broadcastCallback {
    LivuBroadcastCallback callback = ^(int message, NSString *str) {
        NSLog(@"Broadcast Message: %@", str);
		LivuBroadcastProfile* profile = [LivuBroadcastConfig activeProfile]; 
        switch (message) {
            case kStreamStopped:
                [self uiMessage:@"Stream Ended"];
                self.broadcastButton.selected = NO;
                self.broadcastButton.enabled = YES;
                self.cameraButton.hidden = YES;
                self.torchButton.hidden = YES;
                self.configButton.enabled = YES;
                self.bitrateSlider.enabled = YES;
                //              self.settingsButton.enabled = YES;
                
                //                [self resetUI];
				if(profile.useTCP) {
					//tcp_monitor_stop();
					self.streamBitrate.hidden = YES;
				}
				
                break;
				
            case kStreamInitError:
            case kStreamConnectionError:
            case kStreamInternalError:
			case kStreamError:
                
                [captureManager stopEncoding];
                [avcEncoder stop];
                [aacEncoder stop];
                
				if(profile.useTCP) {
					//tcp_monitor_stop();
					self.streamBitrate.hidden = YES;
				}
				
                [self uiMessage:@"Connection Error"];
                self.broadcastButton.enabled = YES;
                self.broadcastButton.selected = NO;
                self.microphoneButton.selected = NO;
                self.cameraButton.hidden = YES;
                self.torchButton.hidden = YES;
                self.configButton.enabled = YES;
                self.bitrateSlider.enabled = YES;
				
				if(profile.autoRestart) {
					
					[self uiMessage:@"Restarting Stream"];
					
					UIAlertView *alert = [[UIAlertView alloc]
										  initWithTitle: NSLocalizedString(@"Stream Error", @"")
										  message: NSLocalizedString(@"The connecton was lost. Restarting in 5 seconds", @"")
										  delegate: nil
										  cancelButtonTitle:@"Cancel"
										  otherButtonTitles:nil];
					[alert show];
					
					double delayInSeconds = 5.0;
					dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
					dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
						
						if(alert.visible) {
							[self toggleBroadcast:self.broadcastButton];
							[alert dismissWithClickedButtonIndex:0 animated:NO];
						}
						
						[alert release];
					});
				}
				
				
                break;
				
			case kInvalidUserPass:
				[captureManager stopEncoding];
                [avcEncoder stop];
                [aacEncoder stop];
                
				if(profile.useTCP) {
					//tcp_monitor_stop();
					self.streamBitrate.hidden = YES;
				}
				
                [self uiMessage:@"Invalid User or Pass"];
                self.broadcastButton.enabled = YES;
                self.broadcastButton.selected = NO;
                self.microphoneButton.selected = NO;
                self.cameraButton.hidden = YES;
                self.torchButton.hidden = YES;
                self.configButton.enabled = YES;
                self.bitrateSlider.enabled = YES;
				
				break;
				
            case kStreamStarted:
                [self uiMessage:@"Stream Started"];
                self.broadcastButton.enabled = YES;
                self.broadcastButton.selected = YES;
                self.microphoneButton.selected = NO;
                self.configButton.enabled = NO;
                
				if(profile.broadcastType == kBroadcastTypeAudioVideo || profile.broadcastType == kBroadcastTypeVideo) {
					[captureManager startCapture];
					self.bitrateSlider.hidden = NO;
					self.cameraButton.hidden = NO;
					self.torchButton.hidden = NO;
					self.bitrateSliderView.hidden = NO;
					
					if ([captureManager hasTorch]) {
						self.torchButton.hidden = NO;
					}
					
					if(profile.broadcastWidth < 640) {
						if ([self.captureManager hasMultipleCameras]) {
							self.cameraButton.hidden = NO;
						}
					}
					
					if(profile.useTCP) {
						//tcp_monitor_start(self.avcEncoder, broadcaster.rtsp_fd, [profile.address cStringUsingEncoding:NSASCIIStringEncoding], profile.autoBitrateAdjust, broadcastBitrates[profile.broadcastType]);
						self.streamBitrate.hidden = NO;
					}
					
					if (profile.useTCP && profile.autoBitrateAdjust) {
						self.bitrateSlider.enabled = NO;
					}
					
				}
				else {
					self.bitrateSlider.hidden = YES;
					self.bitrateSliderView.hidden = YES;
					self.cameraButton.hidden = YES;
					self.torchButton.hidden = YES;
				}
				                
				
                [captureManager startEncoding];
                
				if(profile.broadcastType == kBroadcastTypeAudioVideo || profile.broadcastType == kBroadcastTypeAudio) {
					[aacEncoder start];
				}
                
                //                self.settingsButton.enabled = NO;
                break;
				
			case kStreamRestart:
				[self uiMessage:@"Restarting Stream"];
				break;
        }
        //[aacEncoder stop];
    };
    
    return [[callback copy] autorelease];
}


@end
