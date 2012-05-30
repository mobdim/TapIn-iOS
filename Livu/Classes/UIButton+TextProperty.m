//
//  UIButton+TextProperty.m
//  VFXDataRecorder
//
//  Created by Steve McFarlin (AlignOfSight@stevemcfarlin.com) on 5/28/10.
//  Copyright 2010 Steve McFarlin All rights reserved.
//


@implementation UIButton (TextProperty)

- (NSString*)text 
{
    return [self titleForState:UIControlStateNormal];
}

- (void)setText:(NSString*) txt 
{
    [self setTitle:txt forState:UIControlStateNormal];
}

@end
