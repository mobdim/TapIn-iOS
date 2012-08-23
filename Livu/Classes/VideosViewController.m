//
//  VideosViewController.m
//  TapIn
//
//  Created by Vu Tran on 8/9/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "VideosViewController.h"
#import "Utilities.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIHTTPImageView.h"
#import "VideoMetaViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UserProfileViewController.h"
#import "SignupViewController.h"
#import "TabBarController.h"
#import "MixpanelAPI.h"
#import "MPContainerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioToolbox/AudioToolbox.h>

@interface VideosViewController ()
{
    NSArray * videos;
    NSInteger videosLoaded;
    BOOL loading;
    NSString * currentStream;
    NSArray * sortArray;
    int selectedSort;
    NSString * _query;
    BOOL videoPlaying;
    MPContainerViewController * mpContainer;
}
-(void)showMovie:(NSString*)streamID;
- (void)willExitFullscreen:(NSNotification*)notification;
-(void)loadMoreRows;
-(void)removeAllImagesFromView;
-(void)queryVideosFor:(NSString*)query;
-(void)presentMetaView;
@end

@implementation VideosViewController
@synthesize movieController;
@synthesize root;


-(IBAction)toggleSort:(id)sender{
    NSLog(@"fweklfw %i", selectedSort);
    if(selectedSort==1) selectedSort=0;
    else selectedSort++;
    
    if(selectedSort==1)
    {
        NSLog(@"here 1");
        sortButton.title = [sortArray objectAtIndex:0];
    }
    else {
        NSLog(@"here 2");
        sortButton.title = [sortArray objectAtIndex:selectedSort+1];
    }

    navbar.topItem.title = [NSString stringWithFormat:@"Showing %@", [sortArray objectAtIndex:selectedSort]];
    [self removeAllImagesFromView];
    [self queryVideosFor:[sortArray objectAtIndex:selectedSort]];
    NSLog(@"Selected Sort: %@", [sortArray objectAtIndex:selectedSort]);
}

-(void)removeAllImagesFromView
{
    for (UIHTTPImageView *view in scrollview.subviews)
        [view removeFromSuperview];
    videosLoaded = 0;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated {
    [[Utilities sharedInstance] setDelegate:self];
//    MUST CHANGE THIS
}

-(void)queryVideosFor:(NSString*)query
{
    _query = query;
    if([query isEqualToString:@"Popular"])
    {
        NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"Viewcount", @"sortby", @"500", @"count", @"videos", @"wrapper", nil];
        [[Utilities sharedInstance] sendGet:@"web/get/streambyviewcount" params:params];
        [params release];
    }
//    else if([query isEqualToString:@"New"])
//    {
//        NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"500", @"count", @"videos", @"wrapper", nil];
//        [[Utilities sharedInstance] sendGet:@"web/get/stream" params:params];
//        [params release];
//    }
    
    else if([query isEqualToString:@"Nearby"])
    {
        NSLog(@"hi");
        CLLocation * currentLocation = [[Utilities sharedInstance] location];
        
        NSTimeInterval tt = [[NSDate date] timeIntervalSince1970];
        int time = tt-1209600;
        NSLog(@"fiowejow %i", time);
        
        double a = currentLocation.coordinate.latitude;
        double b = currentLocation.coordinate.longitude;
        
        CLLocation * bottomRight = [[CLLocation alloc]initWithLatitude:a-5.122 longitude:b+5.122];
        CLLocation * upperLeft = [[CLLocation alloc]initWithLatitude:a+5.122 longitude:b-5.122];
        NSString * queryString = [NSString stringWithFormat:@"web/get/streambylocation?topleft=%f&topleft=%f&bottomright=%f&bottomright=%f&start=%i", upperLeft.coordinate.latitude, upperLeft.coordinate.longitude, bottomRight.coordinate.latitude, bottomRight.coordinate.longitude, time];
        
        [upperLeft release];
        [bottomRight release];
        [[Utilities sharedInstance]  sendGet:queryString params:NULL];
        NSLog(@"%@", [[[Utilities sharedInstance] location] description]);
    }
    
//    else if([query isEqualToString:@"Hot"])
//    {
//        NSMutableDictionary * params = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"500", @"count", @"videos", @"wrapper", nil];
//        [[Utilities sharedInstance] sendGet:@"web/get/streambyhot" params:params];
//        [params release];
//    }
}

-(IBAction)myProfileButtonTouched:(id)sender {
    UserProfileViewController * vc = [[UserProfileViewController alloc] init];
    
    if([Utilities userDefaultValueforKey:@"token"])
    {
        //    vc.user = [[Utilities sharedInstance] user];
        vc.user = @"vu0tran";
        [self presentModalViewController:vc animated:YES];
    }
    
    else {
        SignupViewController * vc = [[SignupViewController alloc]init];
        [self presentModalViewController:vc animated:YES];
        [vc release];
    }
    

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UInt32 sessionCategory = kAudioSessionCategory_PlayAndRecord;
    AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
    
    UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideAudioRoute,sizeof (audioRouteOverride),&audioRouteOverride);
    [[Utilities sharedInstance] setDelegate:self];
    _query = @"Popular";

    UIImage *img = [UIImage imageNamed:@"scrollbg.png"];
    [scrollview setBackgroundColor:[UIColor colorWithPatternImage:img]];
    [img release];
    
    sortArray = [[NSArray alloc]initWithObjects:@"Popular", @"Nearby", nil];
    selectedSort = 0;
    videosLoaded = 0;
    loading = NO;
//    Register notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willExitFullscreen:) name:MPMoviePlayerWillExitFullscreenNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willExitFullscreen:) name:MPMoviePlayerDidExitFullscreenNotification object:nil];
  
    // Do any additional setup after loading the view from its nib.
    [self performSelector:@selector(queryVideosFor:) withObject:@"Popular" afterDelay:.5];
}

-(void)loadMoreRows {
    loading = YES;
    NSLog(@"videos loading %i", videosLoaded);
    
    
    if([videos isKindOfClass:[NSDictionary class]])
    {
        int i=0;
        for (id key in videos) {
            NSString * videourl = [NSString stringWithFormat:@"http://thumbs.tapin.tv/%@/144x108/latest.jpg?noCache=mHVFlJTBu7oSYEIBXNn2TT45qlLbnS", key];
            NSLog(@"%@", videourl);
            UIHTTPImageView * img = [[UIHTTPImageView alloc]init];
            [img setImageWithURL:[NSURL URLWithString:videourl] placeholderImage:[UIImage imageNamed:@"icon.png"]];
            UITapGestureRecognizer * tapper = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showMovie:)];
            tapper.numberOfTouchesRequired = 1;
            img.userInteractionEnabled = YES;
            [tapper setAccessibilityHint:key];
            [img addGestureRecognizer:tapper];
            [img.layer setBorderColor: [[UIColor grayColor] CGColor]];
            [img.layer setBorderWidth: 1.0];
            [tapper release];
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
            i++;
        }
    }
    
    else {
    
    for(int i=videosLoaded; i<videosLoaded+18; i++)
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
        [tapper release];
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
    videosLoaded+=18;
    loading = NO;
    NSLog(@"%i", [videos count]);

}


-(void)responseDidSucceed:(NSDictionary *)data{
    NSLog(@"Got here with data");
//    VideoMetaViewController * vc = [[VideoMetaViewController alloc]init];
//    vc.streamID = @"49854d9b65fd448c8f391bf3fc5177d3";
//    [self presentModalViewController:vc animated:YES];
    if([data objectForKey:@"videos"])
    {
        videos = [[data objectForKey:@"videos"] retain];
        [self loadMoreRows];
    }
    else if([[data objectForKey:@"data"] objectForKey:@"streams"])
    {
        NSLog(@"got here");
        
        videos = [[data objectForKey:@"data"] objectForKey:@"streams"];
        NSLog(@"ok ok, %@", [videos description]);
        [self loadMoreRows];

    }
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView {
    CGPoint offset = aScrollView.contentOffset;
    CGRect bounds = aScrollView.bounds;
    CGSize size = aScrollView.contentSize;
    UIEdgeInsets inset = aScrollView.contentInset;
    float y = offset.y + bounds.size.height - inset.bottom;
    float h = size.height;
    // NSLog(@"offset: %f", offset.y);   
    // NSLog(@"content.height: %f", size.height);   
    // NSLog(@"bounds.height: %f", bounds.size.height);   
    // NSLog(@"inset.top: %f", inset.top);   
    // NSLog(@"inset.bottom: %f", inset.bottom);   
    // NSLog(@"pos: %f of %f", y, h);
    
    float reload_distance = 10;
    if(y > h + reload_distance && !loading) {
        if ( ![_query isEqualToString:@"Nearby"]) {
            if(videosLoaded+20<[videos count])
                [self loadMoreRows];
        }
    }
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

-(void)presentMetaView
{
    VideoMetaViewController * vc = [[VideoMetaViewController alloc]init];    
    
    //    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    NSLog(@"FELKFWJLFKJFLKEWJ %@", currentStream);
    vc.streamID = currentStream;
    [self presentModalViewController:vc animated:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [vc release];

}

- (void)exitedFullscreen:(NSNotification*)notification {
    NSLog(@"exitedFullscreen");
    [mpContainer dismissModalViewControllerAnimated:YES];
    self.movieController = nil;
    [self performSelector:@selector(presentMetaView) withObject:nil afterDelay:.5];
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

- (void)showMovie:(UISwipeGestureRecognizer*)recognizer {
    videoPlaying = TRUE;
    [[MixpanelAPI sharedAPI] track:@"Video watch" properties:[NSDictionary dictionaryWithObjectsAndKeys:_query, @"Previous view", nil]];
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
    [movieController play];
    
}

-(IBAction)backButtonTouched:(id)sender{
    [self dismissModalViewControllerAnimated:YES];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
//    return interfaceOrientation;
    if(videoPlaying) return YES;
    else return UIInterfaceOrientationIsPortrait(interfaceOrientation);
//    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

@end
