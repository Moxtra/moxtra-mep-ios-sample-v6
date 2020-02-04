//
//  NSURLSession+Additions.m
//  Master
//
//  Created by gitesh on 15/11/17.
//  Copyright © 2017 Moxtra. All rights reserved.
//

#import "NSURLSession+POST.h"

@implementation NSURLSession (MX_Post)

+(void)mx_postWithURL:(NSString *)url headers:(NSDictionary *)headers requestBody:(nonnull NSDictionary *)requestBody delegate:(id<NSURLSessionDelegate>)delegate success:(void (^)(NSUInteger, NSDictionary * _Nullable))success failure:(void (^)(NSError * _Nonnull error))failure{
    NSURLSession *session = [NSURLSession sessionWithConfiguration: [NSURLSessionConfiguration defaultSessionConfiguration] delegate:delegate delegateQueue:[NSOperationQueue mainQueue]];
    NSURL *URL = [NSURL URLWithString:url];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    request.HTTPMethod = @"POST";
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestBody options:NSJSONWritingPrettyPrinted error:nil];
    if (headers != nil) {
        for (NSString *headerKey in headers.allKeys) {
            [request addValue:[headers objectForKey:headerKey] forHTTPHeaderField:headerKey];
        }
    }
    request.HTTPBody = requestData;;
    NSDate *startdate = [NSDate date];
    [[session dataTaskWithRequest:request  completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSDate *enddate = [NSDate date];
        NSLog(@"\n\n\n\n\n*************time taken for network call for url->%@*************** %f\n\n*******************", url,[enddate timeIntervalSinceDate:startdate]);
        [self mx_handleResponseWithURL:url data:data response:response error:error success:success failure:failure];
    }] resume];
}


+(void)mx_handleResponseWithURL:(nonnull NSString *)url data:(NSData *_Nullable)data response:(NSURLResponse *_Nullable)response error:(NSError * _Nullable)error success:(void (^)(NSUInteger httpCode, NSDictionary *))success failure:(void (^)(NSError * _Nonnull))failure{
    if(error == nil){
        if (data != nil){
            NSError *parseError;
            NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSUInteger statusCode =  httpResponse.statusCode;
            if (parseError == nil){
                NSLog(@"URL->%@, Success->%@",url,json);
                if (success)
                {
                    success(statusCode, json);
                    
                }
            }else{
                NSLog(@"URL->%@, Response parse error->%@",url,parseError.localizedDescription);
                NSLog(@"\nResponse -> %@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                if (failure)
                {
                    failure(error);
                }
            }
        }
    }else{
        NSLog(@"URL->%@, URL Domain error->%@",url,error.localizedDescription);
        if (failure)
        {
            failure(error);
        }
    }
}

@end
