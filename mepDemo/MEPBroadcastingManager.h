//
//  MEPBroadcastingManager.h
//  MEP_App
//
//  Created by jacob on 10/16/20.
//  Copyright © 2020 Moxtra. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEPBroadcastingManager : NSObject
+ (nonnull instancetype) sharedInstance;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;
@end

NS_ASSUME_NONNULL_END
