//
//  Location.h
//  Livu
//
//  Created by Vu Tran on 5/28/12.
//  Copyright (c) 2012 Steve McFarlin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Utilities : NSObject <CLLocationManagerDelegate>
{
    CLLocationManager * locationManager;
    CLLocation *location;
    NSString * uid;
}
-(void)startLocationService;
-(void)stopLocationService;
+(id)sharedInstance;

@property (nonatomic, retain) CLLocation *location;
@property (nonatomic, retain) NSString *uid;
@end
