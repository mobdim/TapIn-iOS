//
//  LivuView.h
//  Livu
//
//  Created by Steve McFarlin (steve@stevemcfarlin.com) 8/9/10.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import "LivuView.h"



@interface LivuView()
- (void)handleSingleTap:(id)tapPointValue;
- (void)handleDoubleTap:(id)tapPointValue;
- (void)handleTripleTap;
@end

@implementation LivuView


@synthesize delegate = delegate;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1) {
        UITouch *touch = [touches anyObject];
        CGPoint tapPoint = [touch locationInView:self];
        if ([touch tapCount] == 1) {
            [self performSelector:@selector(handleSingleTap:) withObject:[NSValue valueWithCGPoint:tapPoint] afterDelay:0.3];
        } else if ([touch tapCount] == 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self performSelector:@selector(handleDoubleTap:) withObject:[NSValue valueWithCGPoint:tapPoint] afterDelay:0.3];
        } else if ([touch tapCount] == 3) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self handleTripleTap];
        }
    }
}

- (void)handleSingleTap:(id)tapPointValue
{
    id _delegate = [self delegate];
    if ([_delegate respondsToSelector:@selector(tapToFocus:)]) {
        [_delegate tapToFocus:[tapPointValue CGPointValue]];
    }    
}

- (void)handleDoubleTap:(id)tapPointValue
{
    id _delegate = [self delegate];
    if ([_delegate respondsToSelector:@selector(tapToExpose:)]) {
        [_delegate tapToExpose:[tapPointValue CGPointValue]];
    }    
}

- (void)handleTripleTap
{
    /*
    id _delegate = [self delegate];
    if ([_delegate respondsToSelector:@selector(resetFocusAndExpose)]) {
        [_delegate resetFocusAndExpose];
    } 
    */   
}

@end
