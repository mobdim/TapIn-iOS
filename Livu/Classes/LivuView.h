//
//  LivuView.h
//  Livu
//
//  Created by Steve McFarlin (steve@stevemcfarlin.com) 8/9/10.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LivuViewDelegate
@optional
- (void)tapToFocus:(CGPoint)point;
- (void)tapToExpose:(CGPoint)point;
- (void)resetFocusAndExpose;
- (void)cycleGravity;
@end


@interface LivuView : UIView {
	id <LivuViewDelegate> delegate;
}

@property (nonatomic, retain) IBOutlet id <LivuViewDelegate> delegate;

@end
