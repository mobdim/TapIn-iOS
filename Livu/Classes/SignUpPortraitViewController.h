//
//  SignUpPortraitViewController.h
//  TapIn
//
//  Created by Vu Tran on 8/13/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Facebook.h"

@interface SignUpPortraitViewController : UIViewController <FBRequestDelegate, FBSessionDelegate>
{
    IBOutlet UIButton * fbButton;
}
-(IBAction)loginWithFacebook:(id)sender;

@end
