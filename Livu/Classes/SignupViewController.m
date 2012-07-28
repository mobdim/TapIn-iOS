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
@interface SignupViewController()
{
    BOOL editing;
}
-(void)registerInfo;
@end

@implementation SignupViewController
@synthesize root;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        return YES ; 
    }
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
    
    [[Utilities sharedInstance] sendPost:@"http://api.tapin.tv/web/login" params:postData];
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
            [[Utilities sharedInstance] sendPost:@"http://api.tapin.tv/web/register" params:postData];
        }

    }
    
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

-(IBAction)cancelButton:(id)sender
{
    [UIView animateWithDuration:.4
                     animations:^{
                         self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+480, self.view.frame.size.width, self.view.frame.size.height);
                     } 
                     completion:^(BOOL finished){
                         [self.view removeFromSuperview];
                         [self release];
                     }];
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

                         dontHaveAccount.titleLabel.text = @"Back to login";
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
    if([data objectForKey:@"token"]) {
        [Utilities setUserDefaultValue:[data objectForKey:@"token"] forKey:@"token"];
        [Utilities setUserDefaultValue:[data objectForKey:@"user"] forKey:@"user"];
        [UIView animateWithDuration:.4
                         animations:^{
                             container.frame = CGRectMake(container.frame.origin.x, container.frame.origin.y+92, container.frame.size.width, container.frame.size.height);
                         } 
                         completion:^(BOOL finished){
                         }];
        [self cancelButton:nil];
        [root startUserTimer];
        [[Utilities sharedInstance] setDelegate:root];
    }
    else if([data objectForKey:@"error"])
    {
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"Uh oh!" message:[data objectForKey:@"error"] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
        [alert show];
        NSLog(@"%@", [data objectForKey:@"error"]);
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
    [[Utilities sharedInstance] setDelegate:self];
    scrollview.contentSize = container.frame.size;
//    UIGestureRecognizer * gesture = [[UIGestureRecognizer alloc]initWithTarget:self action:@selector(textFieldShouldReturn:)];
//    [self.view setUserInteractionEnabled:YES];
//    [self.view addGestureRecognizer:gesture];
//    [gesture release];

    editing = NO;
    [username setDelegate:self];
    [username setReturnKeyType:UIReturnKeyDone];
    [username addTarget:self
                       action:@selector(doneButtonTouched:)
             forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [password setDelegate:self];
    [password setReturnKeyType:UIReturnKeyDone];
    [password addTarget:self
                 action:@selector(doneButtonTouched:)
       forControlEvents:UIControlEventEditingDidEndOnExit];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if(editing == NO)
    {
        if(0)
        {
        [UIView animateWithDuration:.5
                         animations:^{
                             scrollview.frame = CGRectMake(scrollview.frame.origin.x, scrollview.frame.origin.y-70, scrollview.frame.size.width, scrollview.frame.size.height-70);
                         } 
                         completion:^(BOOL finished){
                         }];

        editing = YES;
        }
        else
        {
            [UIView animateWithDuration:.5
                             animations:^{
                                 scrollview.frame = CGRectMake(scrollview.frame.origin.x, scrollview.frame.origin.y-30, scrollview.frame.size.width, scrollview.frame.size.height-110);
                             } 
                             completion:^(BOOL finished){
                             }];
            
            editing = YES;
        }
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
//    NSLog(@"here");
//    [self doneButtonTouched:self];
    [textField resignFirstResponder];
    [UIView animateWithDuration:.5
                     animations:^{
                         scrollview.frame = CGRectMake(scrollview.frame.origin.x, scrollview.frame.origin.y+70, scrollview.frame.size.width, scrollview.frame.size.height+70);
                     } 
                     completion:^(BOOL finished){
                     }];
    editing = NO;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end
