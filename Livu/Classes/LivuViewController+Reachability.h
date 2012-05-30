//
//  AVCamRecorder+Reachability.h
//  AVCam
//
//  Created by Amos Elmaliah on 4/11/11.
//  Copyright 2011 UIMUI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "LivuViewController.h"


@interface LivuViewController (Reachability)

-(void)setupReachability;
-(NetworkStatus)remoteHostStatus;


- (void) handleNetworkChange:(NSNotification *)notice;
//- (BOOL) reachabilityTest ;

@end
