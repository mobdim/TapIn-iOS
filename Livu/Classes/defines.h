/*
 *  defines.h
 *  Livu
 *
 *  Created by Steve on 12/27/10.
 *  Copyright 2010 Steve McFarlin. All rights reserved.
 *
 */

#define     kBroadcastOptions       @"BroadcastOptions.plist"
#define     kVideoOrientationOptions @"VideoOrientationSettings.plist"
#define     kLivuBroadcastConfig    @"BroadcastConfig.plist"

// I got burned when the ordering in the AVCaptureVideoOrientation enum was different
// then what is in the header. I know this was a bad idea anyway.
#define     kVideoOrientationPortrait               0 
#define     kVideoOrientationPortraitUpsideDown     1
#define     kVideoOrientationLandscapeLeft          2
#define     kVideoOrientationLandscapeRight         3

#define STATUS_BAR_HEIGHT       20
#define NAV_BAR_HEIGHT          44
#define KEYBOARD_TOP_POINT_Y    (300 - 140)
