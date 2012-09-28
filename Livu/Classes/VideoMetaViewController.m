//
//  VideoMetaViewController.m
//  TapIn
//
//  Created by Vu Tran on 8/11/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "VideoMetaViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Utilities.h"
#import "Comment.h"
#import <QuartzCore/QuartzCore.h>
#import "AddCommentViewController.h"
#import "UserProfileViewController.h"
#import "SignupViewController.h"
#import "SHK.h"
#import "MixpanelAPI.h"
#import "MPContainerViewController.h"

@interface UIView (ViewHierarchyLogging)

- (CGRect)totalBoundingBox;
-(float)getCommentHeight;

@end

// UIView+HierarchyLogging.m
@implementation UIView (ViewHierarchyLogging)
- (CGRect)totalBoundingBox
{
    CGRect contentRect = CGRectZero;
    for (UIView *subview in self.subviews)
    {
        if(![subview isKindOfClass:[UIImageView class]]) contentRect = CGRectUnion(contentRect, subview.frame);
        [subview totalBoundingBox];
    }
    return contentRect;
}
@end

@interface VideoMetaViewController ()
{
    MPMoviePlayerController * movieController;
    NSArray * comments;
    NSInteger beforeVote;
    MPContainerViewController * mpContainer;
}
-(void)showMovie;
-(void)queryForComments;
-(void)loadComments;
@end

@implementation VideoMetaViewController
@synthesize streamID;

-(IBAction)doneButtonTouched:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}

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
    movieController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    [movieController setFullscreen:NO animated:YES];
}

- (void)showMovie {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterFullscreen:) name:MPMoviePlayerWillEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enteredFullscreen:) name:MPMoviePlayerDidEnterFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(exitedFullscreen:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:MPMoviePlayerPlaybackDidFinishNotification object:nil];
    
    NSURL* movieURL =  [NSURL URLWithString:[NSString stringWithFormat:@"http://content.tapin.tv/%@/stream.mp4", streamID]];
    movieController = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
    if ([movieController respondsToSelector:@selector(view)]) {
         mpContainer = [[MPContainerViewController alloc]init];
        movieController.view.frame = mpContainer.view.frame;
        mpContainer.view = movieController.view;
//        [self.view addSubview:movieController.view];
        [self presentModalViewController:mpContainer animated:YES];
        [movieController setFullscreen:YES animated:YES];
    }
    [movieController play];
}

-(void)queryForComments {
    NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"comments", @"wrapper", @"timestamp", @"sortby", nil];
    [[Utilities sharedInstance] sendGet:[NSString stringWithFormat: @"web/get/commentbystreamid/%@", streamID] params:params delegate:self];
    [[Utilities sharedInstance] sendGet:[NSString stringWithFormat: @"web/get/Timestreambystreamid/%@", streamID] params:[[NSMutableDictionary alloc] initWithObjectsAndKeys:@"timestream", @"wrapper", nil] delegate:self];
    
    [params release];
}

-(IBAction)commentButtonTouched:(id)sender
{
    AddCommentViewController * vc = [[AddCommentViewController alloc]init];
    vc.streamID = self.streamID;
    [self presentModalViewController:vc animated:YES];
}

-(void)loadComments {
    NSLog(@"%i", [comments count]);
    
    if([comments count] ==0){
        NSLog(@"meep?");
    }
    else {
        NSLog(@"meep?meep");
        noComment.hidden = YES;
        addButton.hidden = YES;
    for(int i=0; i<[comments count]; i++)
    {
//        CGRect contentRect = [scrollView totalBoundingBox];
//        scrollView.contentSize = contentRect.size;
//        NSLog(@"This is the height %f",  [self getCommentHeight]);
        Comment * comment = [[Comment alloc]initWithFrame:CGRectMake(0, [self getCommentHeight], 250, 35) data:[[comments objectAtIndex:i] objectAtIndex:1]];
        comment.root = self;
//        NSLog(@"this here %@", [[[comments objectAtIndex:i] objectAtIndex:1] description]);
        [scrollView addSubview:comment];
        scrollView.contentSize = CGSizeMake(320, [self getCommentHeight]);
      
    }   
        CGPoint bottomOffset = CGPointMake(0, scrollView.contentSize.height - scrollView.bounds.size.height);
        [scrollView setContentOffset:bottomOffset animated:NO];

    }
}

-(float)getCommentHeight
{
    float height = 0;
    for(UIView * comment in scrollView.subviews)
    {
        if([comment isKindOfClass:[Comment class]])
        {
            for(UIView *more in comment.subviews)
            {
                if([more isKindOfClass:[UIView class]]){
//                    NSLog(@"This is the height: %f", more.frame.size.height);
                    if(more.frame.size.height<60.0f){
                        height+=22;
                    }
                    else {
                        height+=more.frame.size.height-28;
                    }
                }
            }
        }
           
    }
    return height;
}

-(void)responseDidSucceed:(NSDictionary *)data {
    
    NSLog(@"%@", [data description]);
    if([data objectForKey:@"timestream"])
    {
        NSArray * arr = [[data objectForKey:@"timestream"] objectAtIndex:0];
        NSDictionary * sub = [arr objectAtIndex:1];
        NSArray * coord = [sub objectForKey:@"coord"];
        
        int lat = [[coord objectAtIndex:0] intValue];
        int lon = [[coord objectAtIndex:1] intValue];

        CLLocation * location = [[CLLocation alloc]initWithLatitude:lat longitude:lon];
        CLGeocoder * geoCoder = [[CLGeocoder alloc] init];
        [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            for (CLPlacemark * placemark in placemarks) {
                if([placemark.addressDictionary objectForKey:@"State"])
                {
                    metaLabel.text = [NSString stringWithFormat:@"Near %@, %@", [placemark.addressDictionary objectForKey:@"City"], [placemark.addressDictionary objectForKey:@"State"]];
                }
                else {
                    metaLabel.text = [NSString stringWithFormat:@"Near %@", [placemark.addressDictionary objectForKey:@"City"]];

                }
                    NSLog(@"Placemark is : %@", [placemark.addressDictionary description]);     
            }    
        }];     
    }
    
    else if([data objectForKey:@"vote"])
    {
        data = [data objectForKey:@"vote"];
        if([data isKindOfClass:[NSDictionary class]])
        {
            beforeVote = [[data objectForKey:@"vote"] intValue];
        switch (beforeVote) {
            case -1:
                [voteController setSelectedSegmentIndex:1];
                break;
                
            case 1:
                [voteController setSelectedSegmentIndex:0];
                break;
        }
        }
    }
    
    else if([data objectForKey:@"upvote"])
    {
        if(beforeVote==-1) pointsText.text = [NSString stringWithFormat:@"%i", [pointsText.text intValue]+1];
        pointsText.text = [NSString stringWithFormat:@"%i", [pointsText.text intValue]+1];
        pointsText.alpha = 0;
        [UIView animateWithDuration:.5
                         animations:^{
                             pointsText.textColor = [UIColor greenColor];
                             pointsText.alpha = 1;

                         } 
                         completion:^(BOOL finished){
                         }];
        
        beforeVote = 1;
    }
    
    else if([data objectForKey:@"downvote"])
    {
        pointsText.alpha = 0;
        [UIView animateWithDuration:.5
                         animations:^{
                             pointsText.textColor = [UIColor redColor];
                             pointsText.alpha = 1;
                         } 
                         completion:^(BOOL finished){
                         }];
        
        if(beforeVote==1) pointsText.text = [NSString stringWithFormat:@"%i", [pointsText.text intValue]-1];
        pointsText.text = [NSString stringWithFormat:@"%i", [pointsText.text intValue]-1];
        beforeVote = -1;
    }

    else if([data objectForKey:@"comments"])
    {
        comments = [data objectForKey:@"comments"];
        comments = [[comments reverseObjectEnumerator] allObjects];
        [self loadComments];  

    }
    
    else if([data objectForKey:@"stream"])
    {
        data = [data objectForKey:@"stream"];
        NSLog(@"%@", [data description]);
        pointsText.text = [NSString stringWithFormat:@"%i", [[data objectForKey:@"points"] intValue]];
        viewCountText.text = [NSString stringWithFormat:@"%i", [[data objectForKey:@"viewcount"] intValue]];
        if([[data objectForKey:@"user"] isEqualToString:@""])
        {
            [userButton setTitle:@"anonymous" forState:UIControlStateNormal];
            userButton.userInteractionEnabled = NO;
        }
        else [userButton setTitle:[data objectForKey:@"user"] forState:UIControlStateNormal];
        userButton.titleLabel.adjustsFontSizeToFitWidth = TRUE;
    }
}

-(IBAction)userButtonTouched:(id)sender {
    UIButton * buttonTouched = (UIButton*)sender;
    UserProfileViewController * vc = [[UserProfileViewController alloc]init];
    vc.user = buttonTouched.currentTitle;
    [self presentModalViewController:vc animated:YES];
    [vc release];
}

-(IBAction)segmentedControlTouched:(UISegmentedControl*)sender
{
    if([Utilities userDefaultValueforKey:@"user"])
    {
        if([sender selectedSegmentIndex]==0)
        {
            [[MixpanelAPI sharedAPI] track:@"upvote"];
            NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"upvote", @"wrapper", [Utilities userDefaultValueforKey:@"token"], @"token", nil];
        
            [[Utilities sharedInstance] sendGet:[NSString stringWithFormat:@"web/upvote/stream/%@", self.streamID] params:params delegate:self]; 
            [params release];

        }
        else 
        {
            [[MixpanelAPI sharedAPI] track:@"downvote"];
            NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"downvote", @"wrapper", [Utilities userDefaultValueforKey:@"token"], @"token", nil];
        
            [[Utilities sharedInstance] sendGet:[NSString stringWithFormat:@"web/downvote/stream/%@", self.streamID] params:params delegate:self]; 
            [params release];

        }
    }
    else
        {
            SignupViewController * vc = [[SignupViewController alloc]init];
            [self presentModalViewController:vc animated:YES];
            [vc release];
            [sender setSelectedSegmentIndex:UISegmentedControlNoSegment];
        }
}

-(IBAction)shareButtonTouched:(id)sender
{
    // Create the item to share (in this example, a url)
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://s.tapin.tv/%@", streamID]];
    SHKItem *item = [SHKItem URL:url title:@"Check out this video." contentType:SHKURLContentTypeWebpage];
    
    // Get the ShareKit action sheet
    SHKActionSheet *actionSheet = [SHKActionSheet actionSheetForItem:item];
    
    // ShareKit detects top view controller (the one intended to present ShareKit UI) automatically,
    // but sometimes it may not find one. To be safe, set it explicitly
    [SHK setRootViewController:self];

    [actionSheet showFromToolbar:toolbar];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [userButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];

    beforeVote = 0;
    NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"stream", @"wrapper", nil];

    [[Utilities sharedInstance] sendGet:[NSString stringWithFormat:@"web/get/stream/%@", self.streamID] params:params delegate:self]; 
    [params release];
    
    
    if([Utilities userDefaultValueforKey:@"user"]){
        NSMutableDictionary * params2 = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"vote", @"wrapper", nil];
        
        [[Utilities sharedInstance] sendGet:[NSString stringWithFormat:@"web/get/vote/%@:%@", self.streamID, [Utilities userDefaultValueforKey:@"user"]] params:params2 delegate:self]; 
        [params2 release];
    }

    
    
    upperView.layer.masksToBounds = NO;
    upperView.layer.shadowOffset = CGSizeMake(0, 4);
    upperView.layer.shadowRadius = 2;
    upperView.layer.shadowOpacity = 0.3;

    UIImage *image = [UIImage imageNamed:@"scrollbg.png"];
    [scrollView setBackgroundColor:[UIColor colorWithPatternImage:image]];
    [image release];

//    UINavigationController * navController=[[UINavigationController alloc] init];
//    [navController pushViewController:self animated:NO];
//    [[[UIApplication sharedApplication] keyWindow] addSubview:navController.view];
//    navController.navigationItem.title = "meh";

    NSString * videourl = [NSString stringWithFormat:@"http://thumbs.tapin.tv/%@/144x108/latest.jpg?noCache=mHVFlJTBu7oSYEIBXNn2TT45qlLbnS", streamID];
    UIHTTPImageView * img = [[UIHTTPImageView alloc]initWithFrame:CGRectMake(3, 3, 109, 80)];
    [img setImageWithURL:[NSURL URLWithString:videourl] placeholderImage:[UIImage imageNamed:@"icon.png"]];
    [upperView addSubview:img];    
    UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMovie)];
    tap.numberOfTapsRequired = 1;
    img.userInteractionEnabled = YES;
    [img addGestureRecognizer:tap];  
    // Do any additional setup after loading the view from its nib.
}

-(void)viewDidAppear:(BOOL)animated
{
    for(UIView * view in scrollView.subviews)
    {
        if([view isKindOfClass:[Comment class]]){
            [view removeFromSuperview];
        }
    }
    
    [self queryForComments];
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
