/*
 *  netutil.c
 *  Livu
 *
 *  Created by Steve on 12/27/10.
 *  Copyright 2010 Steve McFarlin. All rights reserved.
 *
 */
#include "netutil.h"

#include <stdlib.h>
#include <fcntl.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <arpa/inet.h>


//TODO: Test reachability

int test_connect(const char *addr, int port, int timeout) {
    struct sockaddr_in address;         /* the libc network address data structure */
    short int sock = -1;                /* file descriptor for the network socket */
    fd_set fdset;
    struct timeval tv;
    int ret = 0;
    
    struct hostent *remoteHostEnt = gethostbyname(addr);
    
    if (!remoteHostEnt) {
        return -1;
    }
    
    // Get address info from host entry
    struct in_addr *remoteInAddr = (struct in_addr *) remoteHostEnt->h_addr_list[0];
    // Convert numeric addr to ASCII string
    addr = inet_ntoa(*remoteInAddr);
    
    //NSString *s = [[NSString alloc] initWithFormat: @“Remote IP: %s\n”, sRemoteInAddr];
    
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = inet_addr(addr); /* assign the address */
    address.sin_port = htons(port);            /* translate int2port num */
    
    sock = socket(AF_INET, SOCK_STREAM, 0);
    fcntl(sock, F_SETFL, O_NONBLOCK);
    
    connect(sock, (struct sockaddr *)&address, sizeof(address));
    
    FD_ZERO(&fdset);
    FD_SET(sock, &fdset);
    tv.tv_sec = timeout;             /* 10 second timeout */
    tv.tv_usec = 0;
    
    if (select(sock + 1, NULL, &fdset, NULL, &tv) == 1)
     {
        int so_error;
        socklen_t len = sizeof so_error;
        
        ret = getsockopt(sock, SOL_SOCKET, SO_ERROR, &so_error, &len);
        
        //Return will be 0 for success -1 for error
        if (ret == 0) {
            ret = 1;
        }
     }
    else {
        ret = 0;
    }
    
    
    close(sock);
    return ret;
}