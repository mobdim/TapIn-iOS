//
//  Location.m
//  Livu
//
//  Created by Vu Tran on 5/28/12.
//  Copyright (c) 2012 Steve McFarlin. All rights reserved.
//

#import "Utilities.h"
#import "SBJson.h"
#import <CommonCrypto/CommonDigest.h>
#import "ASIFormDataRequest.h"
#import <CoreLocation/CoreLocation.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>

@interface Utilities()
{
    BOOL throttle;
}
-(NSString*)getMacAddress;
-(NSString*)getPrivateKey;
+(NSString*)sha1:(NSString*)input;
-(void)postHandShakeWithCoordinate:(CLLocation *)location;
@end

@implementation Utilities
@synthesize location, uid, streamID, delegate;

- (void)dealloc
{
    // implement -dealloc & remove abort() when refactoring for
    // non-singleton use.
    abort();
}

+(id)sharedInstance
{
    static dispatch_once_t pred;
    static Utilities *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[Utilities alloc] init];
    });
    return sharedInstance;
}

- (NSString *)getMacAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;              
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0) 
        errorFlag = @"if_nametoindex failure";
    else
    {
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0) 
            errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
                if ((msgBuffer = malloc(length)) == NULL)
                errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                    errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", 
                                  macAddress[0], macAddress[1], macAddress[2], 
                                  macAddress[3], macAddress[4], macAddress[5]];    
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}

+(NSString*) sha1:(NSString*)input
{
    const char *cstr = [input cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *data = [NSData dataWithBytes:cstr length:input.length];
    
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, data.length, digest);
    
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    
    return output;
    
}

-(void)startLocationService
{
    streamID = @"";
    throttle = NO;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self; 
    locationManager.distanceFilter = 10.0f;
    [locationManager startUpdatingLocation];
}

-(void)stopLocationService 
{
    [locationManager stopUpdatingHeading];
}

#pragma mark - delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation 
{
    if(!throttle)
    {
        [self postHandShakeWithCoordinate:newLocation];
        throttle = YES;
    }
    location = newLocation;
}

-(void)postHandShakeWithCoordinate:(CLLocation *)_location
{
    NSDictionary * streamDict = [[NSDictionary alloc]initWithObjectsAndKeys:
                                 @"1.strm.tapin.tv", @"host",
                                 streamID, @"id", nil];
    
    NSLog(@"lat: %f, lon: %f", _location.coordinate.latitude, _location.coordinate.longitude);
    
    NSArray * coordinate = [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%f",_location.coordinate.latitude], [NSString stringWithFormat:@"%f",_location.coordinate.longitude], [NSString stringWithFormat:@"%f", _location.altitude], nil];  
    
    NSArray * accuracy = [[NSArray alloc] initWithObjects:[NSString stringWithFormat:@"%f",_location.horizontalAccuracy], [NSString stringWithFormat:@"%f",_location.verticalAccuracy], nil];  
    
    NSDictionary * geo = [[NSDictionary alloc] initWithObjectsAndKeys: coordinate, @"coord", accuracy, @"accuracy", nil];
    
    NSMutableDictionary * dataDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                                      [Utilities sha1:[self getMacAddress]], @"pub",
                                      [Utilities sha1:[self getMacAddress]], @"prot",
                                      geo, @"geo",
                                      streamDict, @"stream", nil];
    
    NSDictionary * bigDict = [[NSDictionary alloc]initWithObjectsAndKeys:dataDict, @"data", nil];
    NSString * jsonData = [bigDict JSONRepresentation];
    
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:[NSURL URLWithString:@"http://stage.api.tapin.tv/mobile/updatelocation"]];
    [request setRequestMethod:@"POST"];
    [request setData:[jsonData dataUsingEncoding:NSUTF8StringEncoding] forKey:@"data"];
    [request setDelegate:self];
    [request startAsynchronous];    
    
    //    NSLog(@"%@", [bigDict JSONRepresentation]);
    [bigDict release];
    [geo release];
    [coordinate release];
    [accuracy release];
    [streamDict release];
    [dataDict release];
//    [request release];
}

- (void)requestFinished:(ASIHTTPRequest *)request {
    if(request.responseStatusCode == 200)
    {
        NSLog(@"Response %d ==> %@", request.responseStatusCode, [request responseString]);
        NSDictionary * response = (NSDictionary*)[[request responseString] JSONValue];
        streamID = [response objectForKey:@"streamid"];
        if ([(NSObject *)delegate respondsToSelector:@selector(didCompleteHandeshake:)])
        {
            [delegate didCompleteHandeshake:streamID];
        }

    }
    else
    {
        throttle = NO;
    }
}

- (void) requestFailed:(ASIHTTPRequest *) request {
    if ([(NSObject *)delegate respondsToSelector:@selector(handshakeDidFailWithError:)])
    {
        [self.delegate handshakeDidFailWithErrors:request.error ];
    }
//    NSLog(@"failed: %@", request.error);
    throttle = NO;
}
-(NSString*)getPrivateKey
{
    return [NSString stringWithFormat:@"%@banana", [self getMacAddress]];
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
    throttle = NO;
}

@end
