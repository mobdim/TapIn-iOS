//
//  VideoListViewController.h
//  TapIn
//
//  Created by Vu Tran on 8/13/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"

@interface VideoFeedViewController : UIViewController <NetworkUtilitiesDelegate>
{
    IBOutlet UIScrollView * scrollView;
}
@end
