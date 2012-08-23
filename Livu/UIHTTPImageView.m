//
//  UIHTTPImageView.m
//  TapIn
//
//  Created by Vu Tran on 8/9/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "UIHTTPImageView.h"

@implementation UIHTTPImageView        

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder {
    [request setDelegate:nil];
    [request cancel];
    [request release];
    
    request = [[ASIHTTPRequest requestWithURL:url] retain];
    [request setCacheStoragePolicy:ASICachePermanentlyCacheStoragePolicy];
    
    if (placeholder)
        self.image = placeholder;
    
    [request setDelegate:self];
    [request startAsynchronous];
}

- (void)dealloc {
    [request setDelegate:nil];
    [request cancel];
    [request release];
    [super dealloc];
}

- (void)requestFailed:(ASIHTTPRequest *)req
{
    NSLog(@"failed");
}

- (void)requestFinished:(ASIHTTPRequest *)req
{
    
    if (request.responseStatusCode != 200)
        return;
    
    self.image = [UIImage imageWithData:request.responseData];
}

@end