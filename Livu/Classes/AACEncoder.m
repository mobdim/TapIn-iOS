//
//  AACEncoder.m
//
//  Created by Steve McFarlin on 4/20/11.
//  Copyright 2011 Steve McFarlin. All rights reserved.
//

#import "AACEncoder.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>
#import  <CoreMedia/CoreMedia.h>
#include <mach/mach.h>
#include <mach/mach_time.h>

#define kNumberRecordBuffers 3

#pragma mark user data struct
// Listing 4.3
typedef struct MyRecorder {
    AudioFileID recordFile;
    UInt64 recordPacket;
    Boolean running;
    AudioQueueRef queue;
    BOOL mute;
}MyRecorder;

static AACEncoder   *encoder = nil;
static MyRecorder   recorder = {0};
static BOOL         audioTrimmed = NO;
static uint         packetCount = 0;
mach_timebase_info_data_t info;

#pragma mark utility functions

static void CheckError(OSStatus error, const char *operation) {
    if (error == noErr) return;
    
    char errorString[20];
    //check fourcc
    *(UInt32*)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) &&
        isprint(errorString[3]) && isprint(errorString[4]))
    {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    }
    else {
        sprintf(errorString, "%d", (int)error);
    }
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
}


static int MyComputeRecordBufferSize(const AudioStreamBasicDescription *format,
                                     AudioQueueRef queue, float seconds) {
    
    int packets, frames, bytes;
    frames = (int)ceil(seconds * format->mSampleRate);
    //NSLog(@"Frames: %d", frames);
    if (format->mBytesPerFrame > 0) // 1
        bytes = frames * format->mBytesPerFrame;
    else
    {
        UInt32 maxPacketSize;
        if (format->mBytesPerPacket > 0) { // 2
            // Constant packet size
            maxPacketSize = format->mBytesPerPacket;
        }    
        else
        {
            // Get the largest single packet size possible
            UInt32 propertySize = sizeof(maxPacketSize); // 3
            CheckError(AudioQueueGetProperty(queue,
                                             kAudioConverterPropertyMaximumOutputPacketSize,
                                             &maxPacketSize, &propertySize),
                       "Couldn't get queue's maximum output packet size");
        }
        if (format->mFramesPerPacket > 0) {
            packets = frames / format->mFramesPerPacket; // 4
        }
        else {
            packets = frames; // 5
        }
        if (packets == 0)
            packets = 1;
        bytes = packets * maxPacketSize; // 6
        //NSLog(@"bytes: %d", bytes);
    }
    return bytes;
}

static Byte* CreateEncoderCookie(AudioQueueRef queue, UInt32 *outSize) {
    OSStatus error;
    UInt32 propertySize = 0;
    Byte *magicCookie = 0;
    error = AudioQueueGetPropertySize(queue, kAudioConverterCompressionMagicCookie, &propertySize);
    
    if (error == noErr && propertySize > 0)
    {
        *outSize = propertySize;
        magicCookie = (Byte *)malloc(propertySize);
        CheckError(AudioQueueGetProperty(queue,
                                         kAudioQueueProperty_MagicCookie,
                                         magicCookie, &propertySize),
                   "Get audio queue's magic cookie");
    }
    return magicCookie;
}

#pragma mark record callback function

static void MyAQInputCallback(void *inUserData, 
                              AudioQueueRef inQueue,
                              AudioQueueBufferRef inBuffer,
                              const AudioTimeStamp *inStartTime,
                              UInt32 inNumPackets,
                              const AudioStreamPacketDescription *inPacketDesc) {
    
    MyRecorder *recorder = (MyRecorder *)inUserData;
    
    if (inNumPackets > 0 && !recorder->mute)
    {
        //fprintf(stdout, "packet: count:%lu - size:%lu - number:%lu - time:%llu - time:%f\n", inNumPackets, inPacketDesc->mDataByteSize, packetCount, inStartTime->mHostTime, inStartTime->mSampleTime);
        
        //fprintf(stdout, "Audio Time - host:%llu - sample:%f - scalar:%f - world:%llu\n", inStartTime->mHostTime, inStartTime->mSampleTime, inStartTime->mRateScalar, inStartTime->mWordClockTime);
        
        
        uint64_t time_stamp = inStartTime->mHostTime;
        /* Convert to nanoseconds */
        time_stamp *= info.numer;
        time_stamp /= info.denom;
        //Wait for 0.0 buffer
        if(inStartTime->mSampleTime == 0.0) {
            audioTrimmed = YES;
        }
        
        if(audioTrimmed) {
            recorder->recordPacket += inNumPackets;
            [encoder.delegate AACEncoder:encoder completedFrameData:inBuffer->mAudioData withSize:inBuffer->mAudioDataByteSize andTime:time_stamp];
        }
    }
    
    if (recorder->running)
        CheckError(AudioQueueEnqueueBuffer(inQueue, inBuffer, 0, NULL), "AudioQueueEnqueueBuffer failed");
//    else 
//        NSLog(@"RECORDER NOT RUNNING");
}



int init()
{
    
    audioTrimmed = NO;
    packetCount = 0;
    recorder.mute = NO;
    
    AudioStreamBasicDescription recordFormat = {0};
    memset(&recordFormat, 0, sizeof(recordFormat));
    
    recordFormat.mFormatID = kAudioFormatMPEG4AAC;
    recordFormat.mChannelsPerFrame = 1;
    recordFormat.mSampleRate = 44100.0;
    
    UInt32 propSize = sizeof(recordFormat);
    CheckError(AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &propSize, &recordFormat), "AudoFormatGetProperty Failed");
    
    //NOTE: We are running on the default CFRunLoop. If you are having problems try pusing this to a queue.
    //e.g. Startup this class on a queue and then use CFRunLoopGetCurrent() for \/ that parameter.
    CheckError(AudioQueueNewInput(&recordFormat, MyAQInputCallback, &recorder, NULL, NULL, 0, &recorder.queue), "AudioQueueNewInput Failed");
    //CheckError(AudioQueueNewInput(&recordFormat, MyAQInputCallback, &recorder, CFRunLoopGetCurrent(), NULL, 0, &recorder.queue), "AudioQueueNewInput Failed");
    
    
    UInt32 size = sizeof(recordFormat);
    CheckError(AudioQueueGetProperty(recorder.queue, kAudioConverterCurrentOutputStreamDescription, &recordFormat, &size), "Could not get queue's format");
    
    UInt32 val = kAudioQueueHardwareCodecPolicy_UseSoftwareOnly;
    CheckError(AudioQueueSetProperty(recorder.queue, kAudioQueueProperty_HardwareCodecPolicy, &val, sizeof(UInt32)), "Error setting audio software codec");
    
    int bufferByteSize = MyComputeRecordBufferSize(&recordFormat, recorder.queue, 0.03);
    //NSLog(@"Buffer Size: %d", bufferByteSize);
    
    int bufferIndex;
    for (bufferIndex = 0; bufferIndex < kNumberRecordBuffers; ++bufferIndex)
    {
        AudioQueueBufferRef buffer;
        CheckError(AudioQueueAllocateBuffer(recorder.queue, bufferByteSize, &buffer),
                   "AudioQueueAllocateBuffer failed");
        CheckError(AudioQueueEnqueueBuffer(recorder.queue, buffer, 0, NULL),
                   "AudioQueueEnqueueBuffer failed");
    }
    
    UInt32 sz;
    //CreateEncoderCookie(recorder.queue, &sz);
    
    return 0;
}




@implementation AACEncoder
@synthesize delegate;

- (id)init {
    self = [super init];
    if (self) {
        mach_timebase_info(&info);
    }
    return self;
}

- (void) mute:(BOOL) val {
    recorder.mute = !recorder.mute;
}

- (void) start {
    
        encoder = self;
        //AudioSessionSetActive(YES);
        init();
        recorder.running = TRUE;
        AudioTimeStamp ts = {0};
        
        CheckError(AudioQueueStart(recorder.queue, &ts), "AudioQueueStart failed");
}

- (void) stop {
    if (!recorder.running) {
        return;
    }
    
    recorder.running = FALSE;
    CheckError(AudioQueueStop(recorder.queue, TRUE), "AudioQueueStop failed");
    AudioQueueDispose(recorder.queue, TRUE);
    //printf("* recording done *\n");
}


@end
