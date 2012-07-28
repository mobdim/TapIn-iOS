//
//  UserViewController.h
//  Livu
//
//  Created by Vu Tran on 6/20/12.
//  Copyright (c) 2012 Steve McFarlin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"

@interface UserViewController : UIViewController <UITextFieldDelegate, NetworkUtilitiesDelegate, UIWebViewDelegate>
{
    IBOutlet UIWebView * webview;
    IBOutlet UIView * signupView;
    IBOutlet UINavigationBar * navbar;
}
- (IBAction)backButtonTouched:(id)sender;
@end
