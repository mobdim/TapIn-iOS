//
//  LivuAppDelegate.m
//  Livu
//
//  Created by Steve on 12/26/10.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//
/*
 Feature / Bug Fix
 
 Version 1.2.2
 
	192x144 now streams at 30fps.
 
 
 Version 1.2.1
 
	Fixed bug in LivuBroadcastProfile where it was using broadcast type and not option to select the size.
 
 Version 1.2.0
 
	RTP Library integration
	Auto Restart
	Digest Auth
 
 
 */



#import "LivuAppDelegate.h"
#import "LivuViewController.h"
#import "AssetLoader.h"
#import "SMFileUtil.h"
#import "Utilities.h"
#include <stdio.h>
#include <sys/sysctl.h>
#include <sys/time.h>


@implementation LivuAppDelegate

@synthesize window;
@synthesize viewController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Override point for customization after application launch

    
    [UIApplication sharedApplication].idleTimerDisabled = YES; 
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackOpaque;
    [AssetLoader copyAssetsToDocumentsDirectory];

    // Add the view controller's view to the window and display.
    [self.window addSubview:viewController.view];
    [self.window makeKeyAndVisible];
        
    // Let the device know we want to receive push notifications
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	NSString * dt = [NSString stringWithFormat:@"%@", deviceToken];
    dt = [dt stringByReplacingOccurrencesOfString:@" " withString:@""]; 
    dt = [dt stringByReplacingOccurrencesOfString:@"<" withString:@""]; 
    dt = [dt stringByReplacingOccurrencesOfString:@">" withString:@""]; 

    NSLog(@"My token is: %@", dt);
    [Utilities setUserDefaultValue:dt forKey:@"pushtoken"];
    
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
     //NSLog(@"Will Resign Active") ;
     //TODO: Send message to pause caputure
     [self.viewController willResignActive] ;
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
     //NSLog(@"Did enter background") ;
     [self.viewController willEnterBackground] ;
    //TODO: Stop broadcast
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
     //TODO: startup caputre if we need to. This is called after the main view is loaded and presented
     
     [self.viewController didBecomeActive] ;
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
