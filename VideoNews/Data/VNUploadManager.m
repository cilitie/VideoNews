//
//  VNUploadManager.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-29.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//
@implementation NSString (add)

- (NSString *)md5 {
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    
    CC_MD5(cStr, strlen(cStr), result);
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end

#import "VNUploadManager.h"
#import "AFNetworking.h"
#import "Reachability.h"

#import "QiniuSimpleUploader.h"
#import "QiniuConfig.h"

static Reachability *reach = nil;

@implementation VNUploadManager

#pragma mark - Upload

+(void)uploadImage:(NSData *)imageData Uid:(NSString *)uid Delegate:(id *)delegate completion:(void(^)(bool succeed,NSError *error))completion
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    // NSString *path=[NSString stringWithFormat:@"%@%@",bucket,filePath];
    
    NSDictionary *parameters =@{@"key":[NSString stringWithFormat:@"thumbnail-%@.png",uid],@"uid":uid,@"token":[self LoginToken], @"timestamp": [self timestamp]};
    NSString *URLStr = [VNHost stringByAppendingString:@"qiniuToken.php"];
    //NSString *URLStr=@"fashion-test.oss-cn-beijing.aliyuncs.com";
    [manager POST:URLStr parameters:parameters
          success:^(AFHTTPRequestOperation *operation,id responseObject) {
              //NSLog(@"Success: %@", responseObject);
              //获得签名信息
              if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]&&[responseObject objectForKey:@"status"]) {
                  NSString *token=[responseObject objectForKey:@"Qtoken"];
                  QiniuSimpleUploader *sUploader=[QiniuSimpleUploader uploaderWithToken:token];
                  //sUploader.delegate= (id<QiniuUploadDelegate>)delegate;
                  //[sUploader uploadFileDate:imageData key:[NSString stringWithFormat:@"thumbnail-%@.png",uid] extra:nil];
                  QiniuPutExtra *extra=[[QiniuPutExtra alloc]init];
                  extra.params= @{@"x:uid":uid};
                  kQiniuUpHosts[0]=@"http://upload.qiniu.com/";
                  [sUploader uploadFileData:imageData key:[NSString stringWithFormat:@"thumbnail-%@.png",uid] extra:extra];
              }
          } failure:^(AFHTTPRequestOperation *operation,NSError *error) {
              //NSLog(@"%@",operation.request.URL.absoluteString);
              //NSLog(@"%@",operation);
              NSLog(@"Error: %@", error);
              
              
          }];
}
+ (NSString *)timestamp {
    //    NSLog(@"%@", [[self CCT_Date] description]);
    //    return [NSString stringWithFormat:@"%f", [[self CCT_Date] timeIntervalSince1970]];
    //http://zmysp.sinaapp.com/timestamp.php
    if ([self isReachable]) {
        NSString *URLStr = [VNHost stringByAppendingString:@"timestamp.php"];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:URLStr]];
        [request setHTTPMethod:@"GET"];
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSError *error = nil;
        NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:returnData options:kNilOptions error:&error];
        return [NSString stringWithFormat:@"%d", [[responseObject objectForKey:@"timestamp"] intValue]];
    }
    else {
        return [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    }
}
+ (BOOL)isReachable;
{
    if (!reach) {
        reach = [Reachability reachabilityWithHostname:@"www.chianso.com"];
    }
    return reach.isReachable;
}
+ (NSString *)LoginToken {
    NSString *originTokenStr = [[NSString stringFromDate:[NSDate date]] stringByAppendingString:@"#$@%!*zmy"];
    //NSLog(@"%@", originTokenStr);
    return [originTokenStr md5];
}


@end
