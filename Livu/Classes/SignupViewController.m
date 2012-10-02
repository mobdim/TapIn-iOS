//
//  SignupViewController.m
//  Livu
//
//  Created by Vu Tran on 6/19/12.
//  Copyright (c) 2012 Steve McFarlin. All rights reserved.
//

#import "SignupViewController.h"
#import "ASIFormDataRequest.h"
#import "SBJson.h"
#import "Utilities.h"
#import "LivuViewController.h"
#import "UserProfileViewController.h"
#import "MixpanelAPI.h"

@interface SignupViewController()
{
    BOOL editing;
}
-(void)registerInfo;
-(void)shouldDismiss;
-(void)actualDoneButtonTouched;
@end

@implementation SignupViewController
@synthesize root, fromBar;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
////    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
////    }
//    if(toInterfaceOrientation == UIInterfaceOrientationPortrait)
//    {
//        NSLog(@"herpaderpderp");
//        scrollview.scrollEnabled = NO;
//        topCopy.hidden = YES;
//        email.frame = CGRectMake(email.frame.origin.x-25, email.frame.origin.y+8, email.frame.size.width+40, email.frame.size.height);
//        username.frame = CGRectMake(username.frame.origin.x-25, username.frame.origin.y+8, username.frame.size.width+40, username.frame.size.height);
//        password.frame = CGRectMake(password.frame.origin.x-25, password.frame.origin.y+8, password.frame.size.width+40, password.frame.size.height);
//        loginButton.frame = CGRectMake(loginButton.frame.origin.x-25, loginButton.frame.origin.y+8, loginButton.frame.size.width+40, loginButton.frame.size.height);
//        dontHaveAccount.frame = CGRectMake(loginButton.frame.origin.x-25, dontHaveAccount.frame.origin.y+8, loginButton.frame.size.width+40, loginButton.frame.size.height);
//        self.view.frame = CGRectMake(0, 0, 320, 400);
//        scrollview.frame = CGRectMake(0, 0, 320, 400);
//        scrollview.contentSize = CGSizeMake(320, 400);
//        bg.frame = CGRectMake(0, 0, 320, 440);
//    }
//    else{
//            }
//    
//    
    return NO ; 
}

-(IBAction)signButtonTouched:(id)sender
{
    if(email.hidden == YES)
    {
    NSMutableDictionary * postData = [[NSMutableDictionary alloc]initWithObjectsAndKeys:username.text, @"username", password.text, @"password", [Utilities userDefaultValueforKey:@"uid"], @"uid", @"yes", @"phone", [Utilities phoneID], @"phoneid", nil];
    if([Utilities userDefaultValueforKey:@"pushtoken"])
    {
        [postData setObject:[Utilities userDefaultValueforKey:@"pushtoken"] forKey:@"pushtoken"];
    }
    
    [[Utilities sharedInstance] sendPost:@"http://debug.api.tapin.tv/web/login" params:postData];
    }
    else {
        if([username.text length]<3)
        {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Uh oh!" message:@"Username should be more than 3 characters" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
            [alert release];
        }
        
        else if([password.text length]<3)
        {
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Uh oh!" message:@"Password should be more than 3 characters" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
            [alert release];
        }
        
        else
        { 
            NSMutableDictionary * postData = [[NSMutableDictionary alloc]initWithObjectsAndKeys:username.text, @"username", password.text, @"password", email.text, @"email", [Utilities userDefaultValueforKey:@"uid"], @"uid", [Utilities phoneID], @"phoneid", nil];
            if([Utilities userDefaultValueforKey:@"pushtoken"])
            {
                [postData setObject:[Utilities userDefaultValueforKey:@"pushtoken"] forKey:@"pushtoken"];
            }
            [[Utilities sharedInstance] sendPost:@"http://debug.api.tapin.tv/web/register" params:postData];
        }

    }
    
}

-(void)actualDoneButtonTouched {
    NSLog(@"FWKFLWM");
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)shouldDismiss
{
    if(!fromBar) 
    {
        NSLog(@"WILD THROW MONEY");
        [self dismissModalViewControllerAnimated:YES];
    }
    else {
        [self.view removeFromSuperview];
        [(UserProfileViewController*)self.root loadPage];
    }
}

-(IBAction)cancelButton:(id)sender
{
    if(!fromBar)
    {
        [self shouldDismiss];

    }    
    else 
    {
        NSLog(@"here");
        [(UIViewController*)[self.view.superview nextResponder] dismissModalViewControllerAnimated:YES];
    }
//    [UIView animateWithDuration:.4
//                     animations:^{
//                         self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+480, self.view.frame.size.width, self.view.frame.size.height);
//                     } 
//                     completion:^(BOOL finished){
//                         [self.view removeFromSuperview];
//                         [self release];
//                     }];
}




-(IBAction)doneButtonTouched:(id)sender
{    
    if(email.hidden == YES)
    {
    [UIView animateWithDuration:.5
                     animations:^{
                         password.frame = CGRectMake(password.frame.origin.x, password.frame.origin.y-36, password.frame.size.width, password.frame.size.height);
                         username.frame = CGRectMake(username.frame.origin.x, username.frame.origin.y-36, username.frame.size.width, username.frame.size.height);
                         email.hidden = NO;
                         topCopy.alpha = 0;
                         loginButton.titleLabel.text = @"    Register";
                         upperRight.title = @"Register";
                         upperRightButton.title = @"Register";
                         dontHaveAccount.titleLabel.adjustsFontSizeToFitWidth = TRUE;

                         [dontHaveAccount setTitle:@"Back to login." forState:UIControlStateNormal];
                         loginButton.titleLabel.adjustsFontSizeToFitWidth = TRUE;

                     } 
                     completion:^(BOOL finished){
                     }];

    }
    else {
        [UIView animateWithDuration:.5
                         animations:^{
                             password.frame = CGRectMake(password.frame.origin.x, password.frame.origin.y+36, password.frame.size.width, password.frame.size.height);
                             username.frame = CGRectMake(username.frame.origin.x, username.frame.origin.y+36, username.frame.size.width, username.frame.size.height);
                             email.hidden = YES;
                             topCopy.alpha = 0;
                             loginButton.titleLabel.text = @"      Login";
                             upperRight.title = @"Login";
                             upperRightButton.title = @"Login";
                             dontHaveAccount.titleLabel.adjustsFontSizeToFitWidth = TRUE;
                             [dontHaveAccount setTitle:@"Create an account." forState:UIControlStateNormal];
                             dontHaveAccount.titleLabel.text = @"Don't have an account? Sign up now!";
                             dontHaveAccount.titleLabel.adjustsFontSizeToFitWidth = TRUE;

                         } 
                         completion:^(BOOL finished){
                         }];
    }
}

-(void)registerInfo {
   
}

-(void) responseDidSucceed:(NSDictionary*)data {
    NSLog(@"%@", [data description]);
    if([data isKindOfClass:[NSDictionary class]])
    {
    if([data objectForKey:@"token"]) {
        NSLog(@"THEY TOOK ER JOBS!");
        [Utilities setUserDefaultValue:[data objectForKey:@"token"] forKey:@"token"];
        [Utilities setUserDefaultValue:[data objectForKey:@"user"] forKey:@"user"];
        MixpanelAPI * mixpanel = [MixpanelAPI sharedAPI];
        [mixpanel identifyUser:[Utilities userDefaultValueforKey:@"user"]];

        if(fromBar){
            [(UserProfileViewController*)self.root setUser:[data objectForKey:@"user"]];
            [(UserProfileViewController*)self.root setDidShowLogin:NO];
        }

        [UIView animateWithDuration:.4
                         animations:^{
                             container.frame = CGRectMake(container.frame.origin.x, container.frame.origin.y+92, container.frame.size.width, container.frame.size.height);
                         } 
                         completion:^(BOOL finished){
                         }];
            [self shouldDismiss];
//        [self cancelButton:nil];
//        [root startUserTimer];
//        self.view = root.view;
        [[Utilities sharedInstance] setDelegate:root];
    }
    else if([data objectForKey:@"error"])
    {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Uh oh!" message:[data objectForKey:@"error"] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        NSLog(@"%@", [data objectForKey:@"error"]);
    }
    }
    
}

- (void)requestFinished:(ASIHTTPRequest *)request {
  }

- (void) requestFailed:(ASIHTTPRequest *) request {
    NSLog(@"%@", [request description]);
}

#pragma mark - View lifecycle

-(void)viewWillAppear:(BOOL)animated
{
    [[Utilities sharedInstance] setDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [username setDelegate:self];
    [username setReturnKeyType:UIReturnKeyDone];
    [username addTarget:self
                 action:@selector(actualDoneButtonTouched)
       forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [password setDelegate:self];
    [password setReturnKeyType:UIReturnKeyDone];
    [password addTarget:self
                 action:@selector(actualDoneButtonTouched)
       forControlEvents:UIControlEventEditingDidEndOnExit];

    NSLog(@"YOU GOUGHTA KNOW");
    [[Utilities sharedInstance] setDelegate:self];
    if(fromBar)
    {
        NSLog(@"here");
        cancelButton.customView.hidden = YES;
    }
    
    scrollview.contentSize = container.frame.size;
//    UIGestureRecognizer * gesture = [[UIGestureRecognizer alloc]initWithTarget:self action:@selector(textFieldShouldReturn:)];
//    [self.view setUserInteractionEnabled:YES];
//    [self.view addGestureRecognizer:gesture];
//    [gesture release];

       
    // Do any additional setup after loading the view from its nib.
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if(editing == NO)
    {
//        if(0)
//        {
//        [UIView animateWithDuration:.5
//                         animations:^{
//                             scrollview.frame = CGRectMake(scrollview.frame.origin.x, scrollview.frame.origin.y+60, scrollview.frame.size.width, scrollview.frame.size.height+100);
//                         } 
//                         completion:^(BOOL finished){
//                         }];
//
//        editing = YES;
//        }
//        else
//        {
//            [UIView animateWithDuration:.5
//                             animations:^{
//                                 scrollview.frame = CGRectMake(scrollview.frame.origin.x, scrollview.frame.origin.y-20, scrollview.frame.size.width, scrollview.frame.size.height-110);
//                             } 
//                             completion:^(BOOL finished){
//                             }];
//            
//            editing = YES;
//        }
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self signButtonTouched:nil];
    
//    NSLog(@"here");
//    [self doneButtonTouched:self];
//    [textField resignFirstResponder];
//    [UIView animateWithDuration:.5
//                     animations:^{
//                         scrollview.frame = CGRectMake(scrollview.frame.origin.x, scrollview.frame.origin.y+70, scrollview.frame.size.width, scrollview.frame.size.height+70);
//                     } 
//                     completion:^(BOOL finished){
//                     }];
//    editing = NO;
    
}

-(void)viewDidAppear:(BOOL)animated
{
    editing = NO;


}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end
