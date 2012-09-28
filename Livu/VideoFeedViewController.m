//
//  VideoListViewController.m
//  TapIn
//
//  Created by Vu Tran on 8/13/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "VideoFeedViewController.h"
#import "Utilities.h"
#import "FriendFeedView.h"

@interface VideoFeedViewController ()

@end

@implementation VideoFeedViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSMutableDictionary * params = [[NSMutableDictionary alloc]initWithObjectsAndKeys:@"friendfeed", @"wrapper", nil];
    [[Utilities sharedInstance] sendGet:[NSString stringWithFormat:@"web/get/friendfeed/%@", [Utilities userDefaultValueforKey:@"user"]] params:params delegate:self]; 
    [params release];

    // Do any additional setup after loading the view from its nib.
}

-(void)responseDidSucceed:(NSDictionary *)data
{
    
    NSMutableDictionary * friendDict = [[NSMutableDictionary alloc]init];
    if([data objectForKey:@"friendfeed"])
    {
        NSArray * streams = [data objectForKey:@"friendfeed"];
        for(NSArray * stream in streams)
        {
            NSDictionary * streamDict = [stream objectAtIndex:1];
            NSMutableArray * arr = [[NSMutableArray alloc]initWithObjects:streamDict, nil];
            if(![friendDict objectForKey:[streamDict objectForKey:@"user"]])
            {
                [friendDict setObject:arr forKey:[streamDict objectForKey:@"user"]];
            }
            else if([[friendDict objectForKey:[streamDict objectForKey:@"user"]] count]<3) {
                [[friendDict objectForKey:[streamDict objectForKey:@"user"]] addObject:arr]; 
            }
            [arr release];
        }        
    }
    
    int count = 0;
    
    for(NSString * key in friendDict)
    {
        NSLog(@"how many time? %i", count);
        FriendFeedView * fv = [[FriendFeedView alloc]initWithFrame:CGRectMake(0, count*90, 320, 78)];
        
        fv.username.text = [[[friendDict objectForKey:key] objectAtIndex:0] objectForKey:@"user"];
        [scrollView addSubview:fv];
//        [fv release];
        count++;
    }
    CGRect contentRect = CGRectZero;
    for (UIView *view in scrollView.subviews)
        contentRect = CGRectUnion(contentRect, view.frame);
    
    scrollView.contentSize = contentRect.size;
    NSLog(@"the end");

}

-(void)viewDidAppear:(BOOL)animated
{
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
