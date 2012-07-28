//
//  TwitterVC.m
//  TapIn
//
//  Created by Vu Tran on 6/28/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "TwitterVC.h"
#import "SHKTwitter.h"
@interface TwitterVC ()

@end

@implementation TwitterVC
@synthesize root, tweet;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(IBAction)tweetButton:(id)sender
{
    SHKTwitter * twitter = [[SHKTwitter alloc]init];
    [twitter sendTweet:tweet];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    textview.text = tweet;
    // Do any additional setup after loading the view from its nib.
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
