//
//  VideosViewController.h
//  TapIn
//
//  Created by Vu Tran on 8/9/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"
#import <MediaPlayer/MediaPlayer.h>
#import "LivuViewController.h"

@interface VideosViewController : UIViewController <NetworkUtilitiesDelegate, UIScrollViewDelegate>
{
    MPMoviePlayerController * movieController;
    IBOutlet UIScrollView * scrollview;
    LivuViewController * root;
    IBOutlet UINavigationBar * navbar;
    IBOutlet UIBarButtonItem * sortButton;
    IBOutlet UIBarButtonItem * refreshButton;
    IBOutlet UITabBarController * tabBar;
}
-(IBAction)toggleSort:(id)sender;
-(IBAction)backButtonTouched:(id)sender;
-(IBAction)myProfileButtonTouched:(id)sender;
@property (nonatomic, retain) MPMoviePlayerController * movieController;
@property (nonatomic, retain) LivuViewController * root;
@end
