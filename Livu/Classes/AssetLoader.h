//
//  AssetLoader.h
//  VFXDataRecorder
//
//  Created by Steve McFarlin (AlignOfSight@stevemcfarlin.com) on 3/29/10.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
     Load assets into the the documents directory on startup
*/
@interface AssetLoader : NSObject {
    
}

/**
	Copy the assets from the XIB to the documents directory.
*/
+ (void) copyAssetsToDocumentsDirectory;
+ (void) overwriteAssets;
@end
