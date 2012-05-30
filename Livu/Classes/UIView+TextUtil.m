//
//  UIView+FindAndResignFirstResponder.m
//  VFXDataRecorder
//
//  Created by Steve McFarlin (AlignOfSight@stevemcfarlin.com) on 4/7/10.
//  Copyright 2010 Steve McFarlin All rights reserved.
//

#import "UIView+TextUtil.h"

@implementation UIView (TextUtil)

#pragma mark -
#pragma mark FindAndResignFirstResponder
#pragma mark -

- (BOOL)findAndResignFirstResonder
{
    if (self.isFirstResponder) {
        [self resignFirstResponder];
        return YES;     
    }
    for (UIView *subView in self.subviews) {
        if ([subView findAndResignFirstResonder])
            return YES;
    }
    return NO; 
}

- (void)clearAllTextAreas
{
    if ([self isKindOfClass:[UITextField class]]) {
        ((UITextField*)self).text = @"";
		return;
    }
    for (UIView *subView in self.subviews) {
        [subView clearAllTextAreas];
    }
    return; 
}

/**

*/
- (id)findAndReturnFirstResponder
{
    if (self.isFirstResponder) {
        //[self resignFirstResponder];
        return self;
    }
    for (UIView *subView in self.subviews) {
        if ([subView findAndReturnFirstResponder] != nil)
            return subView;
    }
    return nil; 
}



- (void) clearsOnBeginEditing:(BOOL) val {
	
	if ([self class] == [UITextField class]) {
		((UITextField*)self).clearsOnBeginEditing = val;
	}
	
	for (UIView *subView in self.subviews) {
		[subView clearsOnBeginEditing:val];
    }	
}
@end