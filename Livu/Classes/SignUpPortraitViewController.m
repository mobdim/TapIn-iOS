//
//  SignUpPortraitViewController.m
//  TapIn
//
//  Created by Vu Tran on 8/13/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "SignUpPortraitViewController.h"
#import "SHKFacebook.h"
#import "Facebook.h"

@interface SignUpPortraitViewController ()

@end

@implementation SignUpPortraitViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    
    
    return self;
}

-(IBAction)loginWithFacebook:(id)sender
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://s.tapin.tv/fb/%@/"]];
    SHKItem *item = [SHKItem URL:url title:@"Check out my video @TapInTV"];
    [SHKFacebook shareItem:item];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    SHKFacebook * fb = [[SHKFacebook alloc]init];
    if ([fb isAuthorized])
    {
        NSLog(@"ok got here");
        Facebook * face = [SHKFacebook facebook];
        [face requestWithGraphPath:@"me" andDelegate:self];
        fbButton.hidden = YES;
    } 
    else {
        
    }
}

- (void)request:(FBRequest*)request didLoad:(id)result{
    NSLog(@"This is yoru data %@", result);
    
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
