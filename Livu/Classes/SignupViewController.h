//
//  SignupViewController.h
//  Livu
//
//  Created by Vu Tran on 6/19/12.
//  Copyright (c) 2012 Steve McFarlin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"
#import "LivuViewController.h"

@interface SignupViewController : UIViewController <NetworkUtilitiesDelegate, UITextFieldDelegate>
{
    IBOutlet UITextField * username;
    IBOutlet UITextField * password;
    IBOutlet UIView * container;
    IBOutlet UIScrollView * scrollview;
    IBOutlet UILabel * topCopy;
    IBOutlet UITextField * email;
    IBOutlet UIButton * loginButton;
    IBOutlet UINavigationItem * upperRight;
    IBOutlet UIBarButtonItem * upperRightButton;
    IBOutlet UIButton * dontHaveAccount;
}
-(void)sendPost:(NSString*)host params:(NSMutableDictionary*)params;
-(IBAction)doneButtonTouched:(id)sender;
-(IBAction)signButtonTouched:(id)sender;
-(IBAction)cancelButton:(id)sender;

@property(nonatomic, retain) LivuViewController * root;
@end
