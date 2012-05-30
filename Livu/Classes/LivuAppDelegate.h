//
//  LivuAppDelegate.h
//  Livu
//
//  Created by Steve on 12/26/10.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LivuViewController;

@interface LivuAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    LivuViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet LivuViewController *viewController;

@end

