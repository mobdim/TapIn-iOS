//
//  AssetLoader.m
//  VFXDataRecorder
//
//  Created by Steve McFarlin (AlignOfSight@stevemcfarlin.com) on 3/29/10.
//  Copyright 2010 Steve McFarlin All rights reserved.
//

#import "AssetLoader.h"
#import "SMFileUtil.h"
#import "defines.h"


@implementation AssetLoader

+ (void) overwriteAssets {
    
    NSString *name = [kBroadcastOptions substringToIndex:[ kBroadcastOptions rangeOfString:@"."].location ];
    NSString *ext = [kBroadcastOptions substringFromIndex:[ kBroadcastOptions rangeOfString:@"."].location + 1 ];
    NSString *srcpath = [[NSBundle mainBundle] pathForResource:name ofType:ext];  
    NSString *destpath = [[SMFileUtil applicationDocumentsDirectory] stringByAppendingPathComponent:kBroadcastOptions];
    
    [SMFileUtil deleteFile:destpath];
    [SMFileUtil copyFileFrom:srcpath toDest:destpath];
    
    name = [kLivuBroadcastConfig substringToIndex:[ kLivuBroadcastConfig rangeOfString:@"."].location ];
    ext = [kLivuBroadcastConfig substringFromIndex:[ kLivuBroadcastConfig rangeOfString:@"."].location + 1 ];
    srcpath = [[NSBundle mainBundle] pathForResource:name ofType:ext];  
    destpath = [[SMFileUtil applicationDocumentsDirectory] stringByAppendingPathComponent:kLivuBroadcastConfig];
    
    [SMFileUtil deleteFile:destpath];
    [SMFileUtil copyFileFrom:srcpath toDest:destpath];
    
}

//TODO: This is total shit. Check for the file first.
+ (void) copyAssetsToDocumentsDirectory {

    NSString *name = [kBroadcastOptions substringToIndex:[ kBroadcastOptions rangeOfString:@"."].location ];
    NSString *ext = [kBroadcastOptions substringFromIndex:[ kBroadcastOptions rangeOfString:@"."].location + 1 ];
    NSString *srcpath = [[NSBundle mainBundle] pathForResource:name ofType:ext];  
    NSString *destpath = [[SMFileUtil applicationDocumentsDirectory] stringByAppendingPathComponent:kBroadcastOptions];
    
    [SMFileUtil deleteFile:destpath];
    [SMFileUtil copyFileFrom:srcpath toDest:destpath];
    
    name = [kLivuBroadcastConfig substringToIndex:[ kLivuBroadcastConfig rangeOfString:@"."].location ];
    ext = [kLivuBroadcastConfig substringFromIndex:[ kLivuBroadcastConfig rangeOfString:@"."].location + 1 ];
    srcpath = [[NSBundle mainBundle] pathForResource:name ofType:ext];  
    destpath = [[SMFileUtil applicationDocumentsDirectory] stringByAppendingPathComponent:kLivuBroadcastConfig];
    
    [SMFileUtil copyFileFrom:srcpath toDest:destpath];
    
    /*
    if(! [[NSFileManager defaultManager] fileExistsAtPath:destpath]) {
        [SMFileUtil copyFileFrom:srcpath toDest:destpath];
    }
    else {
        
        NSMutableDictionary *srcdict = [[NSMutableDictionary alloc] initWithContentsOfFile:srcpath];
        NSMutableDictionary *destdict = [[NSMutableDictionary alloc] initWithContentsOfFile:destpath];
        
        NSArray *keys = [destdict allKeys];
        
        for (NSString *key in keys) {
            
            NSDictionary *dest_sub_dict = [destdict valueForKey:key];
            NSMutableDictionary *src_sub_dict = [srcdict valueForKey:key];
            
            //Todo get the top level dictionary from both src and dest. Then copy dest to src.
            for (key in [dest_sub_dict allKeys]) {
                NSObject *obj = [dest_sub_dict valueForKey:key];
                [src_sub_dict setObject:obj forKey:key];
            }
        }
        
        [SMFileUtil deleteFile:destpath];
        [srcdict writeToFile:destpath atomically:YES];
        [srcdict release];
        [destdict release];
    }
    */
    /*
    name = [kBroadcastOptions substringToIndex:[ kBroadcastOptions rangeOfString:@"."].location ];
    ext = [kBroadcastOptions substringFromIndex:[ kBroadcastOptions rangeOfString:@"."].location + 1 ];
    srcpath = [[NSBundle mainBundle] pathForResource:name ofType:ext];  
    destpath = [[SMFileUtil applicationDocumentsDirectory] stringByAppendingPathComponent:kBroadcastOptions];
    
    [SMFileUtil copyFileFrom:srcpath toDest:destpath];
     */
}




@end
