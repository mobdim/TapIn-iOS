//
//  AVCamRecorder+Reachability.m
//  AVCam
//
//  Created by Amos Elmaliah on 4/11/11.
//  Copyright 2011 UIMUI. All rights reserved.
//

#import "LivuViewController+Reachability.h"
#import "LivuViewController.h"

#import "LivuBroadcastConfig.h"
#import "LivuBroadcastProfile.h"

#include <ifaddrs.h> 
#include <arpa/inet.h>

static Reachability* inetReach;
static NetworkStatus remoteHostStatus;

@implementation LivuViewController (AVCamRecorder_Reachability)

#define kAlertNewWifiConnectoin         @"kAlertNewWifiConnectoin"
#define kAlertWifiConnectionLost        @"kAlertWifiConnectionLost"

#define kAlertTitle                     @"kAlertTitle"
#define kAlertMessage                   @"kAlertMessage"

-(void)do_alert_thing:(NSString*)alertKey
{
    NSDictionary* dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"Network Change", kAlertTitle,
                           @"The WiFi connection was lost. Please restart to use your cellular connection", kAlertMessage,
                           nil], 
                          kAlertWifiConnectionLost,
                          [NSDictionary dictionaryWithObjectsAndKeys:
                           @"Network Change", kAlertTitle,
                           @"A wifi conenction is available. Restart Livu to use this network.", kAlertMessage,
                           nil], 
                          kAlertNewWifiConnectoin,
                          nil];
    
    NSDictionary* alertDict = [dict objectForKey:alertKey];
    
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:[alertDict objectForKey:kAlertTitle]
                                                         message:[alertDict objectForKey:kAlertMessage]
                                                        delegate:nil 
                                               cancelButtonTitle:@"OK" 
                                               otherButtonTitles:nil];
    
    [errorAlert show];
    [errorAlert release]; 
}

-(void)setupReachability
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(handleNetworkChange:) 
                                                 name:kReachabilityChangedNotification 
                                               object:nil];
    
    inetReach = [[Reachability reachabilityForInternetConnection] retain] ;
    [inetReach connectionRequired] ;
    [inetReach startNotifer] ;
    
    remoteHostStatus = [inetReach currentReachabilityStatus];
    
//    if(remoteHostStatus == NotReachable) {NSLog(@"Network Status: no");}
//    else if (remoteHostStatus == ReachableViaWiFi) {NSLog(@"Network Status: wifi"); }
//    else if (remoteHostStatus == ReachableViaWWAN) {NSLog(@"Network Status: cell"); }

    [self handleNetworkChange:nil];
    
}

- (NSString *)getIPAddress { 
	NSString *address = @"error"; 
	struct ifaddrs *interfaces = NULL; 
	struct ifaddrs *temp_addr = NULL; 
	int success = 0; // retrieve the current interfaces - returns 0 on success 
	success = getifaddrs(&interfaces); 
	if (success == 0) { 
		// Loop through linked list of interfaces 
		temp_addr = interfaces; 
		while(temp_addr != NULL) { 
			if(temp_addr->ifa_addr->sa_family == AF_INET) { 
				// Check if interface is en0 which is the wifi connection on the iPhone 
				NSLog(@"%s - %s", temp_addr->ifa_name, inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr));
				if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) { 
					// Get NSString from C String 
					address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; 
				} 
			} 
			temp_addr = temp_addr->ifa_next; 
		} 
	} // Free memory 
	freeifaddrs(interfaces); 
	return address; 
}


- (void) handleNetworkChange:(NSNotification *)notice
{
    NetworkStatus newStatus = [inetReach currentReachabilityStatus];
    switch (newStatus) 
    {
        case NotReachable:
            [self uiMessage:NSLocalizedString(@"No Network", @"Indicates there is no network connection")];
            break;
        case ReachableViaWiFi:
             [self uiMessage:NSLocalizedString(@"Wifi Connected", @"Indicates wifi is being used")];
            break;
        case ReachableViaWWAN:
			[self uiMessage:NSLocalizedString(@"Cell Connected", @"Indicates cellular is being used")];
			//[self getIPAddress];
            break;
        default:
            break;
    }

    remoteHostStatus = newStatus ;
}


/*
- (BOOL) reachabilityTest 
{
    
    int net_ret = 0;
    NSString *addr;
    NSUInteger port;
    
    if (remoteHostStatus == NotReachable) {
        //[self delegateMessage:@"Livu requires a network connection" withType:ALERT];
        return NO ;
    }
    
    
    addr = [LivuBroadcastConfig activeProfile].address;
    NSAssert1(addr.length, @"reachability test: setup address: %@", addr);
    
    Reachability *hostreach = [Reachability reachabilityWithHostName:addr];
    if ([hostreach currentReachabilityStatus] == NotReachable) {
        NSLog(@"Not Reachable");
    }
    
    
    port = [LivuBroadcastConfig activeProfile].port;
    NSAssert(port, @"reachability test: setup port");
    
    //[self delegateMessage:@"Resolving and checking host" withType:INFO];
    
    //int test_connect(const char *addr, int port);
    //TODO: I really don't like this. We can't really tell what happened.
    net_ret = test_connect([addr cStringUsingEncoding:NSASCIIStringEncoding], port, 10);
    if (net_ret > 0) {
        return YES ;
    }
    if(net_ret == 0) {
        //[self delegateMessage:@"Connecting timed out" withType:ERROR];
    }
    else {
        //[self delegateMessage:@"Connection Error: Check URL" withType:ERROR];
    }    
    
    return NO;
}
*/
 
-(NetworkStatus)remoteHostStatus
{
    return remoteHostStatus;
}

@end

