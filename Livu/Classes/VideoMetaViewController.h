//
//  VideoMetaViewController.h
//  TapIn
//
//  Created by Vu Tran on 8/11/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIHTTPImageView.h"
#import "Utilities.h"


@interface VideoMetaViewController : UIViewController <NetworkUtilitiesDelegate, CLLocationManagerDelegate>
{
    NSString * streamID;
    IBOutlet UIView * upperView;
    IBOutlet UIScrollView * scrollView;
    IBOutlet UILabel * locationText;
    IBOutlet UILabel * pointsText;
    IBOutlet UILabel * viewCountText;
    IBOutlet UILabel *noComment;
    IBOutlet UIButton * addButton;
    IBOutlet UIButton * userButton;
    IBOutlet UISegmentedControl * voteController;
    IBOutlet UILabel * metaLabel;
    IBOutlet UIToolbar * toolbar;
}
@property (nonatomic, retain) NSString * streamID;
-(IBAction)shareButtonTouched:(id)sender;
-(IBAction)commentButtonTouched:(id)sender;
-(IBAction)userButtonTouched:(id)sender;
-(IBAction)doneButtonTouched:(id)sender;
-(IBAction)segmentedControlTouched:(UISegmentedControl*)sender;
@end
