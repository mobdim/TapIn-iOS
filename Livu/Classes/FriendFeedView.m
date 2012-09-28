//
//  FriendFeedView.m
//  TapIn
//
//  Created by Vu Tran on 8/24/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "FriendFeedView.h"

@implementation FriendFeedView
@synthesize username;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self = [[[NSBundle mainBundle] loadNibNamed:@"FriendFeedView" owner:self options:nil] objectAtIndex:0];
    if (self) {
        self.frame = frame;
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
