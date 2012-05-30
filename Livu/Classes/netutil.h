/*
 *  netutil.h
 *  Livu
 *
 *  Created by Steve on 12/27/10.
 *  Copyright 2010 Steve McFarlin. All rights reserved.
 *
 */
#ifndef NETUTIL_H
#define NETUTIL_H

/*!
 @abstract
    Function to test a connection to the server on the given port
 
 @discussion
    This function does no input checking. 
 
 @param addr The IP or URL address to the server.
 @param port The port to test on
 @return int 1 for success, 0 for timeout, -1 for error.
*/
int test_connect(const char *addr, int port, int timeout);

#endif
