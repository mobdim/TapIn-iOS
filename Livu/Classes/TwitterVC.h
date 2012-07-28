//
//  TwitterVC.h
//  TapIn
//
//  Created by Vu Tran on 6/28/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LivuViewController.h"
@interface TwitterVC : UIViewController
{
    IBOutlet UITextView * textview;
}
@property (nonatomic, retain) LivuViewController * root;
@property (nonatomic, retain) NSString * tweet;

-(IBAction)cancelButton:(id)sender;
-(IBAction)tweetButton:(id)sender;
@end
