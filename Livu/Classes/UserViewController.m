//
//  UserViewController.m
//  Livu
//
//  Created by Vu Tran on 6/20/12.
//  Copyright (c) 2012 Steve McFarlin. All rights reserved.
//

#import "UserViewController.h"
#import "Utilities.h"
#import "SignupViewController.h"

@implementation UserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)backButtonTouched:(id)sender
{
    [UIView animateWithDuration:.4
                     animations:^{
                         self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+480, self.view.frame.size.width, self.view.frame.size.height);
                     } 
                     completion:^(BOOL finished){
                         [self.view removeFromSuperview];
//                         [self release];
                     }];}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)webViewDidFinishLoad:(UIWebView *)webView {
//    [webView stringByEvaluatingJavaScriptFromString:@"window.location.href = '#profile/vu0tran';"];
    NSString *myUrl = webView.request.URL.absoluteString ;
    [webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"window.location.href = '#profile/%@'", [Utilities userDefaultValueforKey:@"user"]]];
    NSLog(@"%@", myUrl);

}

-(void)viewWillAppear:(BOOL)animated
{


//    [webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://tapin.tv/mobile.html#profile/%@", [Utilities userDefaultValueforKey:@"user"]]]]];
}

-(void)viewDidAppear:(BOOL)animated
{
    [[Utilities sharedInstance]setDelegate:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if([Utilities userDefaultValueforKey:@"user"]){
        navbar.topItem.title = [Utilities userDefaultValueforKey:@"user"];;
    }
    else {
        navbar.topItem.title = @"User";
    }
    [webview loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://tapin.tv/mobile.html#profile/%@", [Utilities userDefaultValueforKey:@"user"]]]]];
    NSLog(@"%@", [NSString stringWithFormat:@"http://tapin.tv/mobile.html#profile/%@", [Utilities userDefaultValueforKey:@"user"]]);

    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        return YES ; 
    }
    return NO ;
}

@end
