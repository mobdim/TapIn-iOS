//
//  AddCommentViewController.h
//  TapIn
//
//  Created by Vu Tran on 8/12/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"

@interface AddCommentViewController : UIViewController <UITextViewDelegate, NetworkUtilitiesDelegate>
{
    IBOutlet UITextView * commentField;
    IBOutlet UILabel * helperText;
}
@property (nonatomic, retain) NSString * streamID;
-(void)hideHelperText;
-(IBAction)doneButtonTouched:(id)sender;
-(IBAction)backButtonTouched:(id)sender;
@end
