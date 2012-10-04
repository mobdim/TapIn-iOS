//
//  TCPBufferMonitor.m
//  Quicklink
//
//  Created by Steve McFarlin on 8/12/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

/**
	This entire thing is such a hack.
 */

#import "TCPBufferMonitor.h"
#import "AVCEncoder.h"

#include <QuartzCore/QuartzCore.h>

#include <ctype.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <errno.h>
#include <limits.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>


#include <netdb.h>

#include <mach/mach.h>
#include <mach/mach_time.h>

#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/socketvar.h>
#include <netinet/in_pcb.h>
#include <netinet/tcp.h>
#include <netinet/tcp_var.h>
#include <sys/sysctl.h>
#include <sys/socketvar.h>

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <time.h>
#include <fcntl.h>
#include <time.h>


#define kMaxQueueSize 8
#define kMaxWindowFloor 2000;
#define kSendWindowMinimumScalar 0.10
#define kBitrateDropDelay 10
#define kBitrateIncreaseDelay 100
#define kBWLowPasFilterScalar 0.08
#define kWINLowPasFilterScalar 0.15
#define kBitrateReduction 2500
#define kMaxBitrateReduction 10000
#define kBitrateIncrease 10000
#define kUsableWindowMinRange 12000 //This should be calculated based on key frame size

static unsigned usable_win_floor = 0; 
static uint64_t snd_next_prev = 0;
static uint64_t snd_next_curr = 0;
static uint64_t timestamp_prev = 0;
static uint64_t timestamp_curr = 0;
static uint64_t bandwidth = 0;
static uint32_t usable_win = 0;
static int64_t bitrate_drop_delay = 0;
static int64_t bitrate_increase_delay = 0;
int tcpcb_data_index = 0;
dispatch_source_t timer = NULL;
dispatch_queue_t timer_queue = NULL;

static uint64_t minimum_bitrate = 102400; //config // 100kbps
static uint64_t maximum_bitrate = 2097152 * 2; //config // 2 * 2mbps
int bitrateUpdateFrequency = 2000; //config //milliseconds
int exponentialWeightDivisor = 100; //config
int exponentialWeightAlpha = 90; //config // Divide by divisor
int exponentialWeightBeta = 90; //config
int exponentialWeightGamma = 90; //config
int increaseOnZeroConstant = 20; //config

uint64_t bwWeightedAlpha = 0; //config
uint64_t bwWeightedBeta = 0; //config
uint64_t bwWeightedGamma = 0; //config

static uint64_t aggregate_time = 0;
uint64_t bwRawBits = 0;


//Stops TCP monitor
void tcp_monitor_stop() {
	if(timer != NULL) {
        //Stops timer on "dispatch queue", a special kernel thread that manages small tasks which traditionally run on seperate threads
        dispatch_suspend(timer);
        dispatch_source_cancel(timer);
		//dispatch_release(timer);
		//No more timer, we'll miss you
        timer = NULL;
    }
}


#define	TCP_RTT_SCALE  32
void tcp_monitor_start(AVCEncoder *encoder, int tcp_fd, const char *host, BOOL adjustBitrate, uint64_t maxBitrate) {
 
	//    NSLog(@"The Socket File Discriptor is: %d", tcp_fd);
    static char dstr[32];
	//maximum_bitrate = maxBitrate;
    
    /* resolve the domain name into a list of addresses */
    struct hostent *he;
    struct in_addr **addr_list;
    
    if ((he = gethostbyname(host)) == NULL) {  // get the host info
        return ;
    }
    
    //print information about this host:
    //printf("Official name is: %s\n", he->h_name);
    //printf("    IP addresses: ");
    addr_list = (struct in_addr **)he->h_addr_list;
    
    if(addr_list[0] == NULL) {
        return ;
    }
    
    strcpy(dstr, inet_ntoa(*addr_list[0]));
    
    int val = 1;
    if(setsockopt(tcp_fd, IPPROTO_TCP, TCP_NODELAY, &val, sizeof(val)) < 0) {   
    }
    
    struct linger {
        int   l_onoff;
        int   l_linger;
    };
    
    struct linger lng;
    lng.l_onoff = 1;
    lng.l_linger = 0;
    
    if( setsockopt(tcp_fd, SOL_SOCKET, SO_LINGER, &lng, sizeof lng) ) {
        NSLog(@"Failed to set SO_LINGER");
    }
    
    
    timer_queue = dispatch_queue_create("tcpmonitor.queue", 0);
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,0, 0, timer_queue);
    dispatch_release(timer_queue);
    
    if (timer)   
    {
        __block uint64_t counter = 0;
        timestamp_prev = timestamp_curr = 0;
        snd_next_curr = snd_next_prev = 0;
        bandwidth = 0;
        usable_win_floor = usable_win = 0;
        bitrate_drop_delay = 0;
        bitrate_increase_delay = 0;
        
        //NSLog(@"Timer starting");
        dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), 250ull * NSEC_PER_MSEC, 0);
        dispatch_source_set_event_handler(timer, ^{
            
            size_t len = 0;
            if (sysctlbyname("net.inet.tcp.pcblist", 0, &len, 0, 0)<0)
                printf("ERROR: sysctlbyname");
            else {
                char buf[len];
                if (sysctlbyname("net.inet.tcp.pcblist", &buf, &len, 0, 0)<0)
                    printf("ERRROR sysctlbyname");
                else {
                    static mach_timebase_info_data_t    sTimebaseInfo;
                    if(sTimebaseInfo.denom == 0)
                        (void) mach_timebase_info(&sTimebaseInfo); 
                    
                    timestamp_curr = mach_absolute_time();
                    timestamp_curr *= sTimebaseInfo.numer;
                    timestamp_curr /= (sTimebaseInfo.denom * 1000000.0);
                    
                    BOOL found = NO;
                    struct xinpgen *xig, *oxig;
                    oxig = xig = (struct xinpgen*)&buf;
                    
                    struct tcpcb *tcpcb = NULL;
                    struct inpcb *inpcb = NULL;
                    
                    
                    //Search for IP entry. We need to find a way to connect
                    //an entry to a specific UNIX file descriptor.
                    for (xig = (struct xinpgen*)(((char*)xig)+xig->xig_len) ;
                         xig->xig_len > sizeof(struct xinpgen);
                         xig = (struct xinpgen*)(((char*)xig)+xig->xig_len))
                    {
                        tcpcb = & ((struct xtcpcb*)xig)->xt_tp;
                        inpcb = & ((struct xtcpcb*)xig)->xt_inp;
                        //struct xsocket *xs = & ((struct xtcpcb*)xig)->xt_socket;
                        
                        char *pstr = inet_ntoa(inpcb->inp_dependfaddr.inp46_foreign.ia46_addr4);
                        
                        if( !strcmp(pstr, dstr) && tcpcb_data_index < 16000 * 3) {
                            //NSLog(@"IP's in Table: %s", pstr);
                            found = YES;
                            break;
                        }
                    }
                    
                    if(found) {
                        
                        if(!timestamp_prev) timestamp_prev = timestamp_curr;
                        snd_next_curr = tcpcb->snd_una ;
                        
                        uint64_t bwRawBytes = 0;
                        
                        if(snd_next_prev == 0) {
                            snd_next_prev = snd_next_curr;
                            timestamp_prev = timestamp_curr - 1;
                        }
                        
                        uint64_t deltaTime = (timestamp_curr - timestamp_prev);
                        aggregate_time += deltaTime;
                        
                        if(snd_next_curr > snd_next_prev)
                        {
                            bwRawBytes = (snd_next_curr - snd_next_prev) / deltaTime;
                        }
                        else
                        {
                            bwRawBytes = (snd_next_prev - snd_next_curr) / deltaTime;
                        }
                        
                        if (bwRawBytes == 0)
                        {
                            bwWeightedAlpha += (maximum_bitrate - bwWeightedGamma)/increaseOnZeroConstant;
                        }
                        else
                        {
                            bwRawBits = bwRawBytes * 8 * 1000;
                        }
                        
                        bwWeightedAlpha = ((bwRawBits * (exponentialWeightDivisor - exponentialWeightAlpha)) + (bwWeightedAlpha * exponentialWeightAlpha))/exponentialWeightDivisor;
                        bwWeightedBeta = ((bwWeightedAlpha * (exponentialWeightDivisor - exponentialWeightBeta)) + (bwWeightedBeta * exponentialWeightBeta))/exponentialWeightDivisor;
                        bwWeightedGamma = ((bwWeightedBeta * (exponentialWeightDivisor - exponentialWeightGamma)) + (bwWeightedGamma * exponentialWeightGamma))/exponentialWeightDivisor;
                        
                        
                        if(adjustBitrate && (aggregate_time >= bitrateUpdateFrequency)) {
                            if (bwWeightedGamma <=  minimum_bitrate)
                            {
                                encoder.averagebps = minimum_bitrate;
                            }
                            else if (bwWeightedGamma >= maximum_bitrate)
                            {
                                encoder.averagebps = maximum_bitrate;
                            }
                            else
                            {
								encoder.averagebps = bwWeightedGamma;
							}
                            encoder.averagebps = bwWeightedGamma;
							aggregate_time = 0;
                        }
                        
                                                 
                        snd_next_prev = snd_next_curr;
                        timestamp_prev = timestamp_curr;
                        
                        NSLog(@"%llu %llu %llu %llu %llu %u", timestamp_curr, bwRawBits, bwWeightedAlpha, bwWeightedBeta, bwWeightedGamma, encoder.averagebps);
                        
                    }
                    
                }
                
            }
        });
        dispatch_resume(timer);
        
        
    }
}
