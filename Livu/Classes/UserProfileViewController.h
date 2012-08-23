//
//  UserProfileViewController.h
//  TapIn
//
//  Created by Vu Tran on 8/13/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"
#import "UIHTTPImageView.h"
#import <MediaPlayer/MediaPlayer.h>

@interface UserProfileViewController : UIViewController <NetworkUtilitiesDelegate>
{
    IBOutlet UILabel * following;
    IBOutlet UILabel * followers;
    IBOutlet UILabel * points;
    IBOutlet UINavigationBar * navBar;
    IBOutlet UILabel * userVideos;
    IBOutlet UIHTTPImageView * userIcon;
    IBOutlet UIScrollView * scrollview;
    IBOutlet UIBarButtonItem * followButton;
    IBOutlet UIView * upperView;
}
-(void)loadPage;
-(IBAction)followButtonTouched:(id)sender;
-(IBAction)backButtonTouched:(id)sender;
@property(nonatomic, retain) NSString * user;
@property (nonatomic, retain) MPMoviePlayerController * movieController;
@property(nonatomic) BOOL didShowLogin;
@end
