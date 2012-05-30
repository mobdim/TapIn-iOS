//
//  SMImageUtils.c
//  Livu
//
//  Created by Steve on 1/20/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#include "SMImageUtils.h"
#import "defines.h"

#pragma mark -
#pragma mark Image Utilities
#pragma mark -

CVPixelBufferRef createPixelBufferWidth(size_t width, size_t height) {
    
    CVPixelBufferRef buff = NULL;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, width,
                                          height, kCVPixelFormatType_32BGRA, (CFDictionaryRef) options, 
                                          &buff);    
    
    if(status != kCVReturnSuccess || buff == NULL) {
        return NULL;
    }
    
    return buff;
}

/*
CVPixelBufferRef flipBuffer( CMSampleBufferRef source, CVPixelBufferRef destination) {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(source);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    CVPixelBufferLockBaseAddress(destination, 0);
    
    //TODO: All of this can be precalculated in initialize
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    void *src_buff = CVPixelBufferGetBaseAddress(imageBuffer);
    void *dest_buff = CVPixelBufferGetBaseAddress(destination);
    //NSParameterAssert(dest_buff != NULL);
    
    int32_t *src = (int32_t*) src_buff;
    int32_t *dest= (int32_t*) dest_buff;

    
    dest += (width * (height - 1)) ; 
//  144, 360, 480    divisible by 2, 4, 8, 24
    size_t stop = height / 8;
    for(int i = 0; i < stop; ++i) {
        memcpy(dest, src, width * 4);
        src += width; dest -= width;
        memcpy(dest, src, width * 4);
        src += width; dest -= width;
        memcpy(dest, src, width * 4);
        src += width; dest -= width;
        memcpy(dest, src, width * 4);
        src += width; dest -= width;
        memcpy(dest, src, width * 4);
        src += width; dest -= width;
        memcpy(dest, src, width * 4);
        src += width; dest -= width;
        memcpy(dest, src, width * 4);
        src += width; dest -= width;
        memcpy(dest, src, width * 4);
        src += width; dest -= width;
    }

//    memcpy(dest_buff, src_buff, height * width * 4);

    CVPixelBufferUnlockBaseAddress(destination, 0);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return destination;
}
*/
CVPixelBufferRef rotateBuffer( CMSampleBufferRef source, CVPixelBufferRef destination, NSInteger orientation) {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(source);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    CVPixelBufferLockBaseAddress(destination, 0);
    
    //TODO: All of this can be precalculated in initialize
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    size_t new_width = CVPixelBufferGetWidth(imageBuffer);
    size_t new_height = CVPixelBufferGetHeight(imageBuffer);
    
    void *src_buff = CVPixelBufferGetBaseAddress(imageBuffer);
    
    void *dest_buff = CVPixelBufferGetBaseAddress(destination);
    //NSParameterAssert(dest_buff != NULL);
    
    int *src = (int*) src_buff;
    int *dest= (int*) dest_buff;
    size_t count = (bytesPerRow * height) / 4;
    
    //TODO: This can be handled by calculating a function pointer or selector
    switch (orientation) {
        case kVideoOrientationPortrait:
            new_width = height;
            new_height = width;
            for (int i = 1; i <= new_height; i++) {
                for (int j = new_width - 1; j > -1; j--) {
                    *dest++ = *(src + (j * width) + i);
                }
            }
            
            break;
        case kVideoOrientationPortraitUpsideDown:
            
            for (int i = 1; i <= new_height; i++) {
                for (int j = 1; j <= new_width; j++) {
                    *dest++ = *(src + (j * width) - i);
                }
            }
            
            break;
        case kVideoOrientationLandscapeRight:
            
            dest += (new_width * new_height) - 1; 
            while (count--) {
                *dest-- = *src++;
            }
            
            break;
        default:
            memcpy(dest_buff, src_buff, width * height * 4);
            break;
    }
    
    CVPixelBufferUnlockBaseAddress(destination, 0);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return destination;
}
