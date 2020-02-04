//
//  NSURLSession+Post.h
//  Master
//
//  Copyright © 2017 Moxtra. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXTERN NSErrorDomain _Nonnull const HTTPErrorDomain;



@interface NSURLSession (MX_Post)<NSURLSessionDelegate>
+(void)mx_postWithURL:(nonnull NSString *)url headers:(nullable NSDictionary *)headers requestBody:(nonnull NSDictionary *)requestBody delegate:(id<NSURLSessionDelegate> _Nullable)delegate success:(void (^_Nonnull)(NSUInteger httpCode, NSDictionary * _Nullable json))success failure:(void (^_Nonnull)(NSError * _Nonnull error))failure;
@end
