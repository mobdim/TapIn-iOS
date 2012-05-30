//
//  SMImageUtils.h
//  Livu
//
//  Created by Steve on 1/20/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

CVPixelBufferRef createPixelBufferWidth(size_t width, size_t height);
CVPixelBufferRef flipBuffer( CMSampleBufferRef source, CVPixelBufferRef destination);
//CVPixelBufferRef rotateBuffer( CMSampleBufferRef src, CVPixelBufferRef dst, NSInteger orientation);
