//
//  AddCommentViewController.m
//  TapIn
//
//  Created by Vu Tran on 8/12/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "AddCommentViewController.h"
#import "Utilities.h"
#import "SignupViewController.h"
#import "MixpanelAPI.h"

@interface AddCommentViewController ()

@end

@implementation AddCommentViewController
@synthesize streamID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(IBAction)doneButtonTouched:(id)sender{
    if(![Utilities userDefaultValueforKey:@"token"])
    {
        SignupViewController *vc =[[SignupViewController alloc]init];
        [self presentModalViewController:vc animated:YES];
        [vc release];
        [[MixpanelAPI sharedAPI] track:@"Add Comment"];

    }
    
    if([commentField.text length]>1)
    {
    NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:streamID, @"streamid", [Utilities userDefaultValueforKey:@"token"], @"token", @"comment", @"wrapper", commentField.text, @"text", nil];
        NSLog(@"got here?");
    [[Utilities sharedInstance] sendPost:[NSString stringWithFormat:@"http://api.tapin.tv/web/update/comment/%@", [[Utilities sharedInstance] generateUuidString]] params:params]; 
    [params release];
    }
}

-(IBAction)backButtonTouched:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}

-(void)responseDidSucceed:(NSDictionary *)data
{
    [self dismissModalViewControllerAnimated:YES];
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSLog(@"hi");
    [self hideHelperText];
    return YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    [[Utilities sharedInstance] setDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [commentField becomeFirstResponder];
    [commentField setDelegate:self];
    [[Utilities sharedInstance] setDelegate:self];

    // Do any additional setup after loading the view from its nib.
}

-(void)hideHelperText{
    helperText.hidden = YES;
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
