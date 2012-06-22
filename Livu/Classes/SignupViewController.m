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

@interface SignupViewController()
{
    BOOL editing;
}
@end

@implementation SignupViewController

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        return YES ; 
    }
    return NO ;
}

-(IBAction)signButtonTouched:(id)sender
{
    NSMutableDictionary * postData = [[NSMutableDictionary alloc]initWithObjectsAndKeys:username.text, @"username", password.text, @"password", [Utilities userDefaultValueforKey:@"uid"], @"uid", @"yes", @"phone", [Utilities phoneID], @"phoneid", nil];
    if([Utilities userDefaultValueforKey:@"pushtoken"])
    {
        [postData setObject:[Utilities userDefaultValueforKey:@"pushtoken"] forKey:@"pushtoken"];
    }

    [[Utilities sharedInstance] sendPost:@"http://api.tapin.tv/web/login" params:postData];
    
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
                         container.frame = CGRectMake(container.frame.origin.x, container.frame.origin.y+92, container.frame.size.width, container.frame.size.height);
                     } 
                     completion:^(BOOL finished){
                     }];
    [self dismissModalViewControllerAnimated:YES];
}



-(IBAction)doneButtonTouched:(id)sender
{
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
        NSMutableDictionary * postData = [[NSMutableDictionary alloc]initWithObjectsAndKeys:username.text, @"username", password.text, @"password", [Utilities userDefaultValueforKey:@"uid"], @"uid", [Utilities phoneID], @"phoneid", nil];
        if([Utilities userDefaultValueforKey:@"pushtoken"])
        {
            [postData setObject:[Utilities userDefaultValueforKey:@"pushtoken"] forKey:@"pushtoken"];
        }
            [[Utilities sharedInstance] sendPost:@"http://api.tapin.tv/web/register" params:postData];
        }
}

-(void) responseDidSucceed:(NSDictionary*)data {
    
    if([data objectForKey:@"token"]) {
        [Utilities setUserDefaultValue:[data objectForKey:@"token"] forKey:@"token"];
        [Utilities setUserDefaultValue:[data objectForKey:@"user"] forKey:@"user"];
        [UIView animateWithDuration:.4
                         animations:^{
                             container.frame = CGRectMake(container.frame.origin.x, container.frame.origin.y+92, container.frame.size.width, container.frame.size.height);
                         } 
                         completion:^(BOOL finished){
                         }];
        [self dismissModalViewControllerAnimated:YES];
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
        [UIView animateWithDuration:.5
                         animations:^{
                             container.frame = CGRectMake(container.frame.origin.x, container.frame.origin.y-92, container.frame.size.width, container.frame.size.height);
                         } 
                         completion:^(BOOL finished){
                         }];

        editing = YES;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSLog(@"here");
    [self doneButtonTouched:self];
    editing = NO;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

@end
