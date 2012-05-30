//
//  TCPBufferMonitor.h
//  Quicklink
//
//  Created by Steve McFarlin on 8/12/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVCEncoder;

void tcp_monitor_start(AVCEncoder *encoder, int tcp_fd, const char *host, BOOL adjustBitrate, uint64_t maxBitrate);
void tcp_monitor_stop();