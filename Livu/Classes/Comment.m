//
//  Comment.m
//  TapIn
//
//  Created by Vu Tran on 8/12/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "Comment.h"
#import <QuartzCore/QuartzCore.h>
#import "UserProfileViewController.h"

@interface Comment()
{
    
}
- (void)iconTapped;
@end

@implementation Comment
@synthesize data, root;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self = [[[NSBundle mainBundle] loadNibNamed:@"Comment" owner:self options:nil] objectAtIndex:0];
        // Initialization code
    }
    return self;
}

- (void)iconTapped {
    NSLog(@"got here: %@", [data objectForKey:@"user"]);
    UserProfileViewController * vc = [[UserProfileViewController alloc]init];
    vc.user = [data objectForKey:@"user"];
    [root presentModalViewController:vc animated:YES];
    [vc release];
}

-(IBAction)userButtonTouched:(id)sender
{
    UserProfileViewController * vc = [[UserProfileViewController alloc]init];
    vc.user = [data objectForKey:@"user"];
    [root presentModalViewController:vc animated:YES];
    [vc release];
}

- (id)initWithFrame:(CGRect)frame data:(NSDictionary*)_data {
    self = [super initWithFrame:frame];
    if (self) {
        self = [[[NSBundle mainBundle] loadNibNamed:@"Comment" owner:self options:nil] objectAtIndex:0];
        NSLog(@"int stuff");
        NSLog(@"%@", [_data  description]);
        self.data = _data;
        [user setTitle:[data objectForKey:@"user"] forState:UIControlStateNormal];
//        user.titleLabel.adjustsFontSizeToFitWidth = TRUE;
        text.text = [_data objectForKey:@"text"];
        self.frame = frame;
        [text resizeHeightToFitText];
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(iconTapped)];
        tap.numberOfTapsRequired = 1;
        [icon addGestureRecognizer:tap];
        icon.layer.cornerRadius = 5;
        icon.userInteractionEnabled = YES;
        [tap release];
        
        [icon.layer setBorderColor: [[UIColor grayColor] CGColor]];
        [icon.layer setBorderWidth: 1.0];
        [user setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];

        NSString * iconLink = [NSString stringWithFormat:@"http://www.gravatar.com/avatar/%@?r=pg&s=75&d=http%3A%2F%2Fwww.tapin.tv%2Fassets%2Fimg%2Ficon-noavatar-35.png", [data objectForKey:@"emailhash"]];

        [icon setImageWithURL:[NSURL URLWithString:iconLink] placeholderImage:[UIImage imageNamed:@"icon.png"]];        

        text.center = CGPointMake(125, text.frame.origin.y+text.frame.size.height/2+5);
        commentContainer.frame = CGRectMake(commentContainer.frame.origin.x, commentContainer.frame.origin.y, commentContainer.frame.size.width, text.frame.size.height+10);
        commentContainer.layer.cornerRadius = 3;
        user.center = CGPointMake(user.center.x+8, text.frame.size.height+14);
        commentContainer.frame = CGRectMake(commentContainer.frame.origin.x, commentContainer.frame.origin.y, commentContainer.frame.size.width, user.center.y+14);
        
        
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
