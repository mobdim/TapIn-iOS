//
//  Comment.h
//  TapIn
//
//  Created by Vu Tran on 8/12/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IPInsetLabel.h"
#import "UIHTTPImageView.h"

@interface Comment : UIView
{
    IBOutlet IPInsetLabel * text;
    IBOutlet UIButton * user;
    IBOutlet UIView * commentContainer;
    IBOutlet UIHTTPImageView * icon;
}
- (id)initWithFrame:(CGRect)frame data:(NSDictionary*)_data;
- (IBAction)iconTapped:(id)sender;
-(IBAction)userButtonTouched:(id)sender;
@property (nonatomic, retain) NSDictionary * data;
@property (nonatomic, retain) UIViewController * root;
@end
