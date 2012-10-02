//
//  UserProfileViewController.m
//  TapIn
//
//  Created by Vu Tran on 8/13/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "UserProfileViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "SignupViewController.h"
#import "SignUpPortraitViewController.h"
#import "VideoMetaViewController.h"
#import "MixpanelAPI.h"
#import "SHK.h"
#import "MPContainerViewController.h"

@interface UserProfileViewController ()
{
    NSString * currentStream;
    SignupViewController * vc;
    MPContainerViewController * mpContainer;
}
-(void)queryForVideo;
- (void)showMovie:(UISwipeGestureRecognizer*)recognizer;
-(void)showMetaView;
@end

@implementation UserProfileViewController

@synthesize user, movieController, didShowLogin;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)willEnterFullscreen:(NSNotification*)notification {
    NSLog(@"willEnterFullscreen");
}

- (void)enteredFullscreen:(NSNotification*)notification {
    NSLog(@"enteredFullscreen");
}

- (void)willExitFullscreen:(NSNotification*)notification {
    NSLog(@"willExitFullscreen");
}

- (void)exitedFullscreen:(NSNotification*)notification {
    NSLog(@"exitedFullscreen");
    [mpContainer dismissModalViewControllerAnimated:YES];
    self.movieController = nil;
    [self performSelector:@selector(showMetaView) withObject:nil afterDelay:.5];
}

- (void)playbackFinished:(NSNotification*)notification {
    NSNumber* reason = [[notification userInfo] objectForKey:MPMoviePlayerPlaybackDidFinishReasonUserInfoKey];
    switch ([reason intValue]) {
        case MPMovieFinishReasonPlaybackEnded:
            NSLog(@"playbackFinished. Reason: Playback Ended");         
            break;
        case MPMovieFinishReasonPlaybackError:
            NSLog(@"playbackFinished. Reason: Playback Error");
            break;
        case MPMovieFinishReasonUserExited:
            NSLog(@"playbackFinished. Reason: User Exited");
            break;
        default:
            break;
    }
    [self.movieController setFullscreen:NO animated:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.user = [Utilities userDefaultValueforKey:@"user"];
    NSLog(@"THIS IS WHAT IT IS WHEN IT GETS HERE...%@", self.user);
//    if (![Utilities userDefaultValueforKey:@"user"]) {
//        SignupViewController * vc = [[SignupViewController alloc]init];
//        vc.root = self;
//        vc.fromBar = YES;
//        self.view = vc.view;
//        [vc release];
//    }
}

- (void)showMovie:(UISwipeGestureRecognizer*)recognizer {
    [[MixpanelAPI sharedAPI] track:@"Video watch" properties:[NSDictionary dictionaryWithObjectsAndKeys:@"User page", @"Previous view", nil]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterFullscreen:) name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredFullscreen:) name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exitedFullscreen:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    NSURL* movieURL =  [NSURL URLWithString:[NSString stringWithFormat:@"http://content.tapin.tv/%@/stream.mp4", [recognizer accessibilityHint]]];
    currentStream = [recognizer accessibilityHint];
    self.movieController = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
    if ([movieController respondsToSelector:@selector(view)]) {
        mpContainer = [[MPContainerViewController alloc]init];
        movieController.view.frame = mpContainer.view.frame;
        mpContainer.view = movieController.view;
        //        [self.view addSubview:movieController.view];
        [self presentModalViewController:mpContainer animated:YES];
        [movieController setFullscreen:YES animated:YES];
    }
    [self.movieController play];
}

-(void)showMetaView 
{
    VideoMetaViewController * vc = [[VideoMetaViewController alloc]init];    
    
    //    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    NSLog(@"FELKFWJLFKJFLKEWJ %@", currentStream);
    vc.streamID = currentStream;
    [self presentModalViewController:vc animated:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}

-(void)queryForUserData {
    NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"user", @"wrapper", nil];
    [[Utilities sharedInstance] sendGet:[NSString stringWithFormat: @"web/get/user/%@", user] params:params delegate:self];
    [params release];
}

-(void)queryForVideo {
    NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"video", @"wrapper", @"streamend", @"sortby", nil];
    [[Utilities sharedInstance] sendGet:[NSString stringWithFormat: @"web/get/streambyuser/%@", user] params:params delegate:self];
    [params release];
}

-(void)responseDidSucceed:(NSDictionary *)data{
    if([data isKindOfClass:[NSDictionary class]])
        {
            if([data objectForKey:@"user"])
    {
    data = [data objectForKey:@"user"];
    points.text = [NSString stringWithFormat: @"%i", [[data objectForKey:@"points"] intValue]];
    followers.text = [NSString stringWithFormat:@"%i", [[data objectForKey:@"followers"] count]];
    following.text = [NSString stringWithFormat:@"%i", [[data objectForKey:@"following"] count]];
    
    if([Utilities userDefaultValueforKey:@"user"])
    {
        NSLog(@"at least user: %@", [Utilities userDefaultValueforKey:@"user"]);
        if([[data objectForKey:@"followers"] containsObject:[Utilities userDefaultValueforKey:@"user"]])
        {
            followButton.title = @"Unfollow";
        }
    }
        
    NSString * iconLink = [NSString stringWithFormat:@"http://www.gravatar.com/avatar/%@?r=pg&s=75&d=http%3A%2F%2Fwww.tapin.tv%2Fassets%2Fimg%2Ficon-noavatar-35.png", [data objectForKey:@"emailhash"]];
    
    [userIcon setImageWithURL:[NSURL URLWithString:iconLink] placeholderImage:[UIImage imageNamed:@"icon.png"]];
    }
    else if([data objectForKey:@"video"])
    {
        NSArray * videos = [data objectForKey:@"video"];
        for(int i=0; i<[videos count]; i++)
        {
            NSString * videourl = [NSString stringWithFormat:@"http://thumbs.tapin.tv/%@/144x108/latest.jpg?noCache=mHVFlJTBu7oSYEIBXNn2TT45qlLbnS", [[videos objectAtIndex:i] objectAtIndex:0]];
            NSLog(@"%@", videourl);
            UIHTTPImageView * img = [[UIHTTPImageView alloc]init];
            [img setImageWithURL:[NSURL URLWithString:videourl] placeholderImage:[UIImage imageNamed:@"icon.png"]];
            UITapGestureRecognizer * tapper = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMovie:)];
            tapper.numberOfTouchesRequired = 1;
            img.userInteractionEnabled = YES;
            [tapper setAccessibilityHint:[[videos objectAtIndex:i] objectAtIndex:0]];
            [img addGestureRecognizer:tapper];
            [img.layer setBorderColor: [[UIColor grayColor] CGColor]];
            [img.layer setBorderWidth: 1.0];
            //        
            //        if(i==0) img.frame = CGRectMake(0, 0, 144, 108);
            //        else if(i==1) img.frame = CGRectMake(144, 0, 144, 108);
            //        else if(i==2) img.frame = CGRectMake(0, 108, 144, 108);
            //        else if(i==3) img.frame = CGRectMake(144, 108, 144, 108);
            
            if(i==0) img.frame = CGRectMake(6, 5, 98, 73);
            else if(i%3==0 ) img.frame = CGRectMake(6, 78*(i/3)+5, 98, 73);
            else if(i%2==0 ) img.frame = CGRectMake(216, 78*(i/3)+5, 98, 73);
            else img.frame = CGRectMake(111, 78*(i/3)+5, 98, 73);
            
            //        else if(i%3==0 ) img.frame = CGRectMake(0, 108*(i/3), 144, 108);
            //        else if(i%2==0 ) img.frame = CGRectMake(288, 108*(i/3), 144, 108);
            //        else img.frame = CGRectMake(144, 108*(i/3), 144, 108);
            [scrollview addSubview:img];
            CGRect contentRect = CGRectZero;
            for (UIHTTPImageView *view in scrollview.subviews)
                contentRect = CGRectUnion(contentRect, view.frame);
            
            scrollview.contentSize = contentRect.size;
        }

    }
    else if([data objectForKey:@"follow"]) {
        data = [data objectForKey:@"follow"];
        NSLog(@"ok %@", data);
        followers.text = [NSString stringWithFormat:@"%i", [followers.text intValue]+1];
        followButton.title = @"Unfollow";

    }
    else if([data objectForKey:@"unfollow"]) {
        data = [data objectForKey:@"follow"];
        followers.text = [NSString stringWithFormat:@"%i", [followers.text intValue]-1];
        followButton.title = @"Follow";

        NSLog(@"ok %@", data);
    }
        }
}

-(IBAction)backButtonTouched:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

-(IBAction)followButtonTouched:(id)sender {
    UIBarButtonItem *buttonTouched = (UIBarButtonItem*)sender;
    if([buttonTouched.title isEqualToString:@"Sign Out"]){
        [[MixpanelAPI sharedAPI] track:@"Sign Out" properties:[NSDictionary dictionaryWithObjectsAndKeys:@"User page", @"Previous view", nil]];
        [SHK logoutOfAll];

        [[Utilities sharedInstance] signout];
        didShowLogin = NO;
        vc = [[SignupViewController alloc]init];
        vc.root = self;
        vc.fromBar = YES;
        [self.view addSubview:vc.view];
        [vc release];
//        [self dismissModalViewControllerAnimated:YES];
    }
    
    else if([buttonTouched.title isEqualToString:@"Sign Up"])
    {
        [[MixpanelAPI sharedAPI] track:@"Sign Up" properties:[NSDictionary dictionaryWithObjectsAndKeys:@"User page", @"Previous view", nil]];
//        SignupViewController * vc2 = [[SignupViewController alloc]init];
        SignupViewController * vc2 =[[SignupViewController alloc]init];
        vc.root = self;
        self.view = vc2.view;
        [self presentModalViewController:vc2 animated:YES];
        [vc release];
    }
    
    else if([buttonTouched.title isEqualToString:@"Unfollow"])
    {
        [[MixpanelAPI sharedAPI] track:@"Unfollow"];
        NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"unfollow", @"wrapper", user, @"username", [Utilities userDefaultValueforKey:@"token"], @"token", nil];
        [[Utilities sharedInstance] sendGet:[NSString stringWithFormat: @"web/unfollow", user] params:params delegate:self];
        [params release];
    }

    else {
        [[MixpanelAPI sharedAPI] track:@"Follow"];
        NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"follow", @"wrapper", user, @"username", [Utilities userDefaultValueforKey:@"token"], @"token", nil];
        [[Utilities sharedInstance] sendGet:[NSString stringWithFormat: @"web/follow", user] params:params delegate:self];
        [params release];
    }
}

-(void)viewDidDisappear:(BOOL)animated{
    if(didShowLogin)
    {
//        [vc.view removeFromSuperview];

    }
}
- (void)viewDidAppear:(BOOL)animated
{
    NSLog(@"wfjekljf %@", self.user);
    
    if(!self.user)
    {
        didShowLogin = YES;
        vc = [[SignupViewController alloc]init];
        vc.root = self;
        vc.fromBar = YES;
        [self.view addSubview:vc.view];
        [vc release];
    }
    else if(self.user){
        NSLog(@"ok load page");

    
    if(![Utilities userDefaultValueforKey:@"token"])
    {
        followButton.title = @"Sign Up";
    }
        [self loadPage];
    }


  
    // Do any additional setup after loading the view from its nib.
}

-(void)loadPage {
    self.user = [Utilities userDefaultValueforKey:@"user"];
    if(self.user)
    {
    self.tabBarItem.title = @"Videos";
    navBar.topItem.title = self.user;
    [[Utilities sharedInstance] setDelegate:self];
    userVideos.text = [NSString stringWithFormat: @"%@ Videos", user];
    [self queryForUserData];
    [self queryForVideo];
    
    UIImage *img = [UIImage imageNamed:@"scrollbg.png"];
    [scrollview setBackgroundColor:[UIColor colorWithPatternImage:img]];
    [img release];
    }
    
    if([self.user isEqualToString:[[Utilities sharedInstance] user]])
    {
//        scrollview.frame = CGRectMake(0, 165, 320, 291);
//        userIcon.center = CGPointMake(userIcon.frame.origin.x+30, userIcon.frame.origin.y+24);    
//        userVideos.hidden = YES;
//        upperView.frame = CGRectMake(0, 50, 320, 112);
        followButton.title = @"Sign Out";
        
    }
    else {
        
    }
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (BOOL)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


-(void)viewDidLoad
{
     upperView.layer.masksToBounds = NO;
    upperView.layer.shadowOffset = CGSizeMake(0, 4);
    upperView.layer.shadowRadius = 2;
    upperView.layer.shadowOpacity = 0.3;
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
