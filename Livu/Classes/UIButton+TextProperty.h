//
//  UIButton+TextProperty.h
//  VFXDataRecorder
//
//  Created by Steve McFarlin (AlignOfSight@stevemcfarlin.com) on 4/2/10.
//  Copyright 2010 Steve McFarlin All rights reserved.
//

/**
    This catigory adds the 'text' property to UIButton. This is to avoid unnessasary branches in code 
    to set the and get the text of a button control.
*/
@interface UIButton (TextProperty)

@property (nonatomic, retain) NSString* text;

- (NSString*)text;
- (void)setText:(NSString*) txt;

@end
