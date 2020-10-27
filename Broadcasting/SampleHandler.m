//
//  SampleHandler.m
//  Broadcasting
//
//  Created by fengyibo on 2020/10/27.
//  Copyright © 2020 com.moxtra.mepdemo. All rights reserved.
//


#import <VideoToolbox/VideoToolbox.h>
#import "SampleHandler.h"
#import "AVSampleDefines.h"

#define kGroupName @""

@interface SampleHandler()
@property(assign) NSTimeInterval latestTimestamp;
@property(strong) NSTimer *lastCaptureTimer;
@property(assign) UIDeviceOrientation deviceOrientation;
@property(nonatomic, strong) NSUserDefaults *userDefault;
@property(nonatomic) BOOL broadcasting;
@end

@implementation SampleHandler

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    self.userDefault = [self userDef];
    [self.userDefault setObject:[NSDictionary new] forKey:kDSStatusInfo];
    self.broadcasting = YES;
    
    [self sendCommands:@"undefine"];
    __weak SampleHandler *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakSelf.broadcasting)
            [weakSelf sendCommands:kMessageStarted];
        
        //keep alive
        NSTimer *checkTimer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            [weakSelf checkRemoteDSStatus];
        }];
        
        [[NSRunLoop currentRunLoop] addTimer:checkTimer forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] addTimer:checkTimer forMode:NSDefaultRunLoopMode];
    });
}

- (void)dealloc
{
    [self.userDefault removeObserver:self forKeyPath:kDSStatusInfo];
}

- (void)broadcastPaused {
    self.broadcasting = NO;
    // User has requested to pause the broadcast. Samples will stop being delivered.
}

- (void)broadcastResumed {
    self.broadcasting = YES;
    // User has requested to resume the broadcast. Samples delivery will resume.
}

- (void)broadcastFinished {
    self.broadcasting = NO;
    // User has requested to finish the broadcast.
    [self sendCommands:kMessageFinished];
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // Handle video sample buffer
            [self handleVideoSample:(CMSampleBufferRef)sampleBuffer];
            break;
        case RPSampleBufferTypeAudioApp:
            // Handle audio sample buffer for app audio
            break;
        case RPSampleBufferTypeAudioMic:
            // Handle audio sample buffer for mic audio
            break;
            
        default:
            break;
    }
}

#pragma  mark -screem sample handler
- (BOOL)sendCommands:(NSString *)commands {
    if (self.userDefault == nil)
        return NO;
      
    [self.userDefault setObject:@"undefine" forKey:kSampleStatusKey];
    [self.userDefault synchronize];
    [self.userDefault setObject:commands forKey:kSampleStatusKey];
    [self.userDefault synchronize];
    return YES;
}


- (void)handleVideoSample:(CMSampleBufferRef)sampleBuffer
{
    if (sampleBuffer == nil)
        return;
    
    @synchronized (self)
    {
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        CGImageRef imageRef = NULL;
        OSStatus createdImage = VTCreateCGImageFromCVPixelBuffer(imageBuffer, NULL, &imageRef);
        self.deviceOrientation = [self getSampleBufferOrientation:sampleBuffer];
        if (createdImage == noErr)
        {
           UIImage *latest_image = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUp];
           NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970] * 1000; //double ms
           if (timestamp - _latestTimestamp > CAPTURE_SCREEN_INTERNVAL)
           {
               _latestTimestamp = timestamp;
               [self processCaptureImage:latest_image];
           }
           else {
               [self start_last_capture_timer:latest_image];
           }
        }

        if (imageRef) {
           CGImageRelease(imageRef);
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    }
   
}
#pragma mark -Sample post to remote

- (void)start_last_capture_timer:(UIImage*)image
{
    [self stop_last_capture_timer];
    
    if ([NSThread isMainThread]) {
        [self start_last_capture_timer_mainthread:image];
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self start_last_capture_timer_mainthread:image];
        });
    }
}

- (void)processCaptureImage:(UIImage*)image
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        
        int width = (int)(image.size.width*image.scale);
        int height = (int)(image.size.height*image.scale);
        NSString *base64Jpeg = [imageData base64EncodedStringWithOptions:0];
        
        NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    base64Jpeg, kImageDataKey,
                                    [NSNumber numberWithInt:width], @"width",
                                    [NSNumber numberWithInt:height], @"height",
                                    [NSNumber numberWithInteger:self.deviceOrientation], kImageOrientationKey,
                                    nil];
        if (dictionary)
            [self saveSample:dictionary];
    });
}

#pragma mark - Helper
- (void)start_last_capture_timer_mainthread:(UIImage*)image
{
    if (self.lastCaptureTimer != nil)
    {
        [self stop_last_capture_timer];
    }
    
    self.lastCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:CAPTURE_SCREEN_INTERNVAL/1000.0f
                                                            target:self
                                                          selector:@selector(lastcapture_timer:)
                                                          userInfo:image
                                                           repeats:NO];
}

- (void)lastcapture_timer:(NSTimer*)timer
{
    [self processCaptureImage:timer.userInfo];
}

- (void)stop_last_capture_timer
{
    if ([NSThread isMainThread]) {
        [self stop_last_capture_timer_mainthread];
    }
    else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self stop_last_capture_timer_mainthread];
        });
    }
}

- (void)stop_last_capture_timer_mainthread
{
    if (_lastCaptureTimer) {
        [_lastCaptureTimer invalidate];
        _lastCaptureTimer = nil;
    }
}


- (BOOL)saveSample:(NSDictionary *)sample
{
    if (self.userDefault == nil || sample == nil)
        return NO;

    
    if ([self checkRemoteDSStatus])
        [self.userDefault setObject:sample forKey:kImageSampleKey];
    else
        [self.userDefault removeObjectForKey:kImageSampleKey];
    return YES;
}

- (BOOL)checkRemoteDSStatus
{
    if ([self.userDefault objectForKey:kDSStatusInfo])
    {
        NSDictionary *dsStatus = [self.userDefault objectForKey:kDSStatusInfo];
        NSString *status = [dsStatus objectForKey:@"status"];
        NSString *reason = [dsStatus objectForKey:@"reason"];
        if ([status isEqualToString:kMessageFinished])
        {
            NSError *err = nil;
            if (reason)
                err = [NSError errorWithDomain:@"com.moxtra.moxtra"
                                                            code:1
                                                        userInfo:@{
                                                                   NSLocalizedDescriptionKey : reason,
                                                                   NSLocalizedFailureReasonErrorKey : reason
                                                                   }];
            [self finishBroadcastWithError:err];
            [self stop_last_capture_timer_mainthread];
            [self sendCommands:kMessageFinished];
            return NO;
        }
    }
    
    return YES;
}

- (NSUserDefaults *)userDef
{
    NSAssert((kGroupName.length), @"Please set you group name!");
    NSUserDefaults *appGroupDefaults = [[NSUserDefaults alloc] initWithSuiteName:kGroupName];
    return appGroupDefaults;
}

- (UIDeviceOrientation)getSampleBufferOrientation:(CMSampleBufferRef)sample
{
    NSNumber *ori =  (__bridge NSNumber*)CMGetAttachment(sample, (CFStringRef)RPVideoSampleOrientationKey, nil);
    UIDeviceOrientation deviceOrientation = UIDeviceOrientationUnknown;
    switch(ori.intValue)
    {
        case 1:
            deviceOrientation = UIDeviceOrientationPortrait;
            break;
        case 6:
            deviceOrientation = UIDeviceOrientationLandscapeLeft;
            break;
        case 8:
            deviceOrientation = UIDeviceOrientationLandscapeRight;
            break;
        case 3:
            deviceOrientation = UIDeviceOrientationPortraitUpsideDown;
            break;
        default:
            deviceOrientation = UIDeviceOrientationUnknown;
            break;
    }
    return deviceOrientation;
}
@end
