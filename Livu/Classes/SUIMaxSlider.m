//
//  SUIMaxSlider.m
//  CustomSlider
//
//  Created by Steve on 2/8/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import "SUIMaxSlider.h"
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/QuartzCore.h>
//#import "Common.h"

#define kSliderPadding 5

@implementation SUIMaxSlider

@synthesize minimumValue, maximumValue;
@dynamic value;

#pragma mark -
#pragma mark Interface Initialization

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        trackPoint.x = self.bounds.size.width;
        self.backgroundColor = [UIColor colorWithRed:135.0/255.0 green:173.0/255.0 blue:255.0/255.0 alpha:0.0];
    }
    return self;
}

- (id) initWithFrame: (CGRect) aFrame {
    self = [super initWithFrame:aFrame];
	if (self) {
		// This control uses a fixed 200x200 sized frame
		self.frame = aFrame;
        self.bounds = aFrame;
		self.center = CGPointMake(CGRectGetMidX(aFrame), CGRectGetMidY(aFrame));
        trackPoint.x = aFrame.size.width;
    }
	
	return self;
}

- (id) init {
	return [self initWithFrame:CGRectZero];
}

#pragma mark -
#pragma mark Dynamic Properties.
#pragma mark -

- (float_t) value {
    return value;
}

- (void) setValue:(float_t) v {
    //TODO: map this range value back into the domain.
    value = fmin(v, maximumValue);
    value = fmax(value, minimumValue);
    float_t delta = maximumValue - minimumValue;
    float_t scalar = ((self.bounds.size.width - 2 * kSliderPadding) / delta) ;
    
    float_t x = (value - minimumValue) * scalar;
    x += 5.0;
    trackPoint.x = x;
    [self setNeedsDisplay];
} 


#pragma mark -
#pragma mark Interface Drawing
#pragma mark -

- (void) drawRect:(CGRect) rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGColorRef lightBlue = [UIColor colorWithRed:135.0/255.0 green:173.0/255.0 blue:255.0/255.0 alpha:1.0].CGColor;
    CGColorRef lightBlueAlpha = [UIColor colorWithRed:135.0/255.0 green:173.0/255.0 blue:255.0/255.0 alpha:0.7].CGColor;
    CGColorRef lightGrayAlpha = [UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:0.7].CGColor;
    CGColorRef lightGray = [UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:1.0].CGColor;
    //CGColorRef darkGrayColor = [UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:70.0/255.0 alpha:1.0].CGColor;
    //CGColorRef redColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.6].CGColor;
    
    CGRect boundsRect = self.bounds;
    
    CGRect sliderRect = CGRectMake(0, 0, boundsRect.size.width, boundsRect.size.height / 2);
    
    //NSLog(@"Width: %f - Height: %f", boundsRect.size.width, boundsRect.size.height);
    
    /*
    CGContextSetFillColorWithColor(context, lightGrayColor);
    CGContextFillRect(context, sliderRect);
    
    halfHeight.origin.y = sliderRect.size.height;
    CGContextSetFillColorWithColor(context, darkGrayColor);
    CGContextFillRect(context, sliderRect);
    */

    CGFloat tx = fmin(sliderRect.size.width - kSliderPadding, trackPoint.x);
    tx = fmax(kSliderPadding, tx);
    
    sliderRect.origin.y = boundsRect.origin.y;
    sliderRect.size.width = tx ;
    if (self.enabled) {
        CGContextSetFillColorWithColor(context, lightBlueAlpha);
    }
    else {
        CGContextSetFillColorWithColor(context, lightGrayAlpha);
    }
    
    CGContextFillRect(context, sliderRect);
    
    sliderRect.origin.y = sliderRect.size.height;
    if(self.enabled) {
        CGContextSetFillColorWithColor(context, lightBlue);
    }
    else {
        CGContextSetFillColorWithColor(context, lightGray);
    }
    CGContextFillRect(context, sliderRect);
    
    
    CGFloat mid = boundsRect.size.height / 2 ;
    
    CGPoint a = CGPointMake(tx - kSliderPadding, mid);
    CGPoint b = CGPointMake(tx, mid - kSliderPadding);
    CGPoint c = CGPointMake(tx + kSliderPadding, mid);
    CGPoint d = CGPointMake(tx, mid + kSliderPadding);
    
    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 1.0);
    CGContextSetLineWidth(context, 2.0);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, a.x, a.y);
    CGContextAddLineToPoint(context, b.x, b.y);
    CGContextAddLineToPoint(context, c.x, c.y);
    CGContextAddLineToPoint(context, d.x, d.y);
    CGContextAddLineToPoint(context, a.x, a.y);
    
    CGContextFillPath(context);
}


#pragma mark -
#pragma mark Touch Tracking
#pragma mark -

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint p = [touch locationInView:self];
	//bound track point
    trackPoint.x = fmax(p.x, kSliderPadding) ;
    trackPoint.x = fmin(trackPoint.x, self.bounds.size.width  - kSliderPadding);
    [self setNeedsDisplay];
    
    //translate value to vector space
    float_t x = trackPoint.x - kSliderPadding;
    
    float_t delta = maximumValue - minimumValue;
    float_t scalar = (x / (self.bounds.size.width - 2 * kSliderPadding)) ;
    value = minimumValue + (delta * scalar);
    // Send value changed alert
	[self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint p = [touch locationInView:self];
    
    trackPoint.x = fmax(p.x, kSliderPadding) ;
    trackPoint.x = fmin(trackPoint.x, self.bounds.size.width - kSliderPadding);
    [self setNeedsDisplay];
    
	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	
	CGPoint p = [touch locationInView:self];
   //bound track point
    trackPoint.x = fmax(p.x, kSliderPadding) ;
    trackPoint.x = fmin(trackPoint.x, self.bounds.size.width  - kSliderPadding);
    [self setNeedsDisplay];
    
    //translate value to vector space
    float_t x = trackPoint.x - kSliderPadding;
    
    float_t delta = maximumValue - minimumValue;
    float_t scalar = (x / (self.bounds.size.width - 2 * kSliderPadding)) ;
    value = minimumValue + (delta * scalar);
    // Send value changed alert
	[self sendActionsForControlEvents:UIControlEventValueChanged];
    return YES;
}    

@end
