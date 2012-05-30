//
//  UIView+ResignFirstResponder.h
//  VFXDataRecorder
//
//  Created by Steve McFarlin (AlignOfSight@stevemcfarlin.com) on 3/28/10.
//  Copyright 2010 Steve McFarlin All rights reserved.
//



/**
    This catigory adds a method to UIView that
    finds and resigns the firstResponder.
*/
@interface UIView (TextUtil)

/**
    Find and resign the first responder.

	Note: This is a recursive method.
	
	\return BOOL YES is 
*/
- (BOOL)findAndResignFirstResonder;

/**
	Find and return the first responder
	
	Note: This is a recursive method.
	
	\return id The field with first responder state
 */
- (id)findAndReturnFirstResponder;


/**
	Set the texfields of a UIView to clear or not clear when
	editing.
*/
- (void) clearsOnBeginEditing:(BOOL) val;

/**
	Clears all the text from ever UITextArea that is a sub
	view of the object this is called on.
*/	
- (void)clearAllTextAreas;

@end


