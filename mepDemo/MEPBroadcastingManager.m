//
//  MEPBroadcastingManager.h
//  MEP_App
//
//  Created by jacob on 10/16/20.
//  Copyright © 2020 Moxtra. All rights reserved.
//

#import "MEPBroadcastingManager.h"
#import <MEPSDK/MEPSDK.h>

#ifndef kImageSampleKey
    #define kImageSampleKey @"sampleScreen"
    #define kSampleStatusKey   @"sampleStatus"
    #define kDSStatusInfo   @"DSStatusInfo"
    #define kImageDataKey   @"jpegBase64"
    #define kImageOrientationKey  @"deviceOrientation"
    #define  kMessageStarted  @"started"
    #define kMessageFinished @"finished"
#endif

#define kGroupName @""
#define kBroadcastExtensionBundleIdentifier @""

@interface MEPBroadcastingManager()<MEPBroadcastingDelegate>
@property (nonatomic, strong) NSOperationQueue *screenImageProcessQueue;
@property (nonatomic, strong) NSUserDefaults *userDefault;

@end

@implementation MEPBroadcastingManager
+ (id)sharedInstance {
    static MEPBroadcastingManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        
    });
    return instance;
}

-(instancetype) init{
    self = [super init];
    if(self){
        self.userDefault = [self userDef];
        if (self.userDefault)
        {
            [self.userDefault addObserver:self forKeyPath:kSampleStatusKey options:NSKeyValueObservingOptionNew context:nil];
            [self.userDefault addObserver:self forKeyPath:kImageSampleKey options:NSKeyValueObservingOptionNew context:nil];
        }
        
        NSAssert((kBroadcastExtensionBundleIdentifier.length), @"Please set you broadcast extension bundle identifier!");
        MEPBroadcasting *broadcasting = [MEPBroadcasting sharedInstance];
        broadcasting.broadcastExtensionBundleIdentifier = kBroadcastExtensionBundleIdentifier;
        broadcasting.delegate = self;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [self.userDefault removeObserver:self forKeyPath:kSampleStatusKey];
    [self.userDefault removeObserver:self forKeyPath:kImageSampleKey];
}

#pragma  mark -MEPBroadcastingDelegate
- (void)broadcastingScreenShareDidStarted:(nonnull MEPBroadcasting *)boradcasting
{
    [self sendCommandToBroadcastExtension:kMessageStarted];
}

- (void)broadcastingScreenShareDidStopped:(nonnull MEPBroadcasting *)boradcasting
{
    [self sendCommandToBroadcastExtension:kMessageFinished];
}

#pragma  mark -private
- (NSUserDefaults *)userDef
{
    NSAssert((kGroupName.length), @"Please set you group name!");
    NSUserDefaults *appGroupDefaults = [[NSUserDefaults alloc] initWithSuiteName:kGroupName];
    NSString *reason = [NSString stringWithFormat:@"Pls check your app group(%@) is enabled or not", kGroupName];
    NSAssert(appGroupDefaults != nil, reason);
    return appGroupDefaults;
}

+ (UIImage *)rotate:(UIImage*)src withRadians:(CGFloat)radians;
{
    UIImage *(^drawImage)(void) = ^UIImage *{
        // calculate the size of the rotated view's containing box for our drawing space
        UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,src.size.width, src.size.height)];
        CGAffineTransform t = CGAffineTransformMakeRotation(radians);
        rotatedViewBox.transform = t;
        CGSize rotatedSize = rotatedViewBox.frame.size;
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize);
        CGContextRef bitmap = UIGraphicsGetCurrentContext();
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
        
        //   // Rotate the image context
        CGContextRotateCTM(bitmap, radians);
        
        // Now, draw the rotated/scaled image into the context
        CGContextScaleCTM(bitmap, 1.0, -1.0);
        CGContextDrawImage(bitmap, CGRectMake(-src.size.width / 2, -src.size.height / 2, src.size.width, src.size.height), [src CGImage]);
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    };
    return drawImage();
}

- (void)sampleDidChanged
{
    if (self.screenImageProcessQueue == nil)
    {
        self.screenImageProcessQueue = [[NSOperationQueue alloc] init];
        [self.screenImageProcessQueue setMaxConcurrentOperationCount:1];
    }
    
    
    if (![[self.userDefault objectForKey:kSampleStatusKey] isEqualToString:kMessageStarted])
        return;
    
    //cancel waiting items since new item arrived.
    [self.screenImageProcessQueue cancelAllOperations];
    [self.screenImageProcessQueue addOperationWithBlock:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSDictionary *sampleInfo = [self.userDefault objectForKey:kImageSampleKey];
            if (sampleInfo) {
                NSData *imageData = [[NSData alloc] initWithBase64EncodedString:[sampleInfo objectForKey:kImageDataKey] options:0];
                UIImage *image = [UIImage imageWithData:imageData];
                UIDeviceOrientation deviceOrientation = [[sampleInfo objectForKey:kImageOrientationKey] intValue];
                switch(deviceOrientation)
                {
                    case UIInterfaceOrientationPortrait:
                        break;
                    case UIInterfaceOrientationPortraitUpsideDown:
                        image = [MEPBroadcastingManager rotate:image withRadians:M_PI];
                        break;
                    case UIInterfaceOrientationLandscapeLeft:
                        image = [MEPBroadcastingManager rotate:image withRadians:M_PI/2];
                        break;
                    case UIInterfaceOrientationLandscapeRight:
                        image = [MEPBroadcastingManager rotate:image withRadians:-M_PI/2];
                        break;
                    default:
                        break;
                }
                
                
                [[MEPBroadcasting sharedInstance] shareImage:image];
            }
        });
    }];
}

- (void)statusDidChanged
{
    if (self.userDefault == nil)
        return;
    NSString *status = [self.userDefault objectForKey:kSampleStatusKey];
    if ([status isEqualToString:kMessageStarted]) {
        [[MEPBroadcasting sharedInstance] startSharing];
    } else if ([status isEqualToString:kMessageFinished]) {
        [[MEPBroadcasting sharedInstance] stopSharing];
    }
}

- (BOOL)sendCommandToBroadcastExtension:(NSString *)commands {
    if (self.userDefault == nil)
        return NO;
    NSMutableDictionary *dic = [NSMutableDictionary new];
    [dic setObject:commands forKey:@"status"];
    if ([commands isEqualToString:kMessageFinished])
    {
        NSString *localizedReason = [[NSBundle mainBundle] localizedStringForKey:@"Your sharing has been stopped." value:nil table:nil];
        [dic setObject:localizedReason forKey:@"reason"];
    }
    
    [self.userDefault setObject:[NSDictionary new] forKey:kDSStatusInfo];
    [self.userDefault synchronize];
    [self.userDefault setObject:dic forKey:kDSStatusInfo];
    [self.userDefault synchronize];
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kImageSampleKey])
    {
        [self sampleDidChanged];
    }
    else if ([keyPath isEqualToString:kSampleStatusKey])
    {
        [self statusDidChanged];
    }
}

@end
