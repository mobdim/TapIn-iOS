//
//  CUIMaxSlider.h
//  CustomSlider
//
//  Created by Steve on 2/8/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SUIMaxSlider : UIControl {
@private
    float_t minimumValue;
    float_t maximumValue;
    float_t value;
    CGPoint trackPoint;
    
}
@property (nonatomic, assign) float_t minimumValue, maximumValue;
@property (nonatomic, assign) float_t value;
@end
