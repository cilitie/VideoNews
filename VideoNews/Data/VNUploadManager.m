//
//  VNUploadManager.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-29.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNUploadManager.h"
#import "AFNetworking.h"
#import "VNHTTPRequestManager.h"

#import "QiniuSimpleUploader.h"
#import "QiniuConfig.h"

//static Reachability *reach = nil;

@implementation VNUploadManager

#pragma mark - Upload

+ (instancetype)sharedInstance{
    static VNUploadManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
        //        assert(_DefaultSpaceName);
        //        _sharedInstance.spaceName = _DefaultSpaceName;
    });
    return _sharedInstance;
}


-(void)uploadImage:(NSData *)imageData Uid:(NSString *)uid completion:(void(^)(bool succeed,NSError *error))completion
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *key=[NSString stringWithFormat:@"thumbnail-%@-%@.jpeg",uid,[self timestamp]];
    
    NSDictionary *parameters =@{@"key":key,@"uid":uid,@"token":[self LoginToken], @"timestamp": [self timestamp]};
    NSString *URLStr = [VNHost stringByAppendingString:@"qiniuImageToken.php"];
    [manager POST:URLStr parameters:parameters
          success:^(AFHTTPRequestOperation *operation,id responseObject) {
              NSLog(@"Success: %@", responseObject);
              //获得签名信息
              if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]&&[responseObject objectForKey:@"status"]) {
                  NSString *token=[responseObject objectForKey:@"Qtoken"];
                  QiniuSimpleUploader *sUploader=[QiniuSimpleUploader uploaderWithToken:token];
                  sUploader.delegate= self;
                  QiniuPutExtra *extra=[[QiniuPutExtra alloc]init];
                  extra.params= @{@"x:uid":uid};
                  kQiniuUpHosts[0]=@"http://upload.qiniu.com/";
                  [sUploader uploadFileData:imageData key:key extra:extra];
              }
              if (completion) {
                  completion(YES, nil);
              }
          } failure:^(AFHTTPRequestOperation *operation,NSError *error) {
              //NSLog(@"%@",operation.request.URL.absoluteString);
              //NSLog(@"%@",operation);
              NSLog(@"Error: %@", error);
              if (completion) {
                  completion(NO, error);
              }
              
          }];
}
-(void)uploadVideo:(NSData *)videoData Uid:(NSString *)uid Title:(NSString *)title Tags:(NSString *)tags ThumbnailTime:(CGFloat )thumbnailTime completion:(void(^)(bool succeed,NSError *error))completion
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *key=[NSString stringWithFormat:@"video-%@-%@.mp4",uid,[self timestamp]];
    
    //NSDictionary *parameters =@{@"key":key,@"uid":uid,@"title":title,@"tags":tags,@"thumbnailTime": [NSNumber numberWithFloat:thumbnailTime],@"token":[self LoginToken], @"timestamp": [self timestamp]};
    NSDictionary *parameters =@{@"key":key,@"thumbnailTime": [NSNumber numberWithFloat:thumbnailTime],@"token":[self LoginToken], @"timestamp": [self timestamp]};
    NSString *URLStr = [VNHost stringByAppendingString:@"qiniuVideoToken.php"];
    [manager POST:URLStr parameters:parameters
          success:^(AFHTTPRequestOperation *operation,id responseObject) {
              NSLog(@"Success: %@", responseObject);
              //获得签名信息
              if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]&&[responseObject objectForKey:@"status"]) {
                  NSString *token=[responseObject objectForKey:@"Qtoken"];
                  QiniuSimpleUploader *sUploader=[QiniuSimpleUploader uploaderWithToken:token];
                  sUploader.delegate= self;
                  QiniuPutExtra *extra=[[QiniuPutExtra alloc]init];
                  extra.params= @{@"x:uid":uid,@"x:title":title,@"x:tags":tags};
                  extra.crc32=1;
                  kQiniuUpHosts[0]=@"http://upload.qiniu.com/";
                  kQiniuUpHosts[1]=@"http://upload.qiniu.com/";
                  [sUploader uploadFileData:videoData key:key extra:extra];
              }
              if (completion) {
                  completion(YES, nil);
              }
          } failure:^(AFHTTPRequestOperation *operation,NSError *error) {
              //NSLog(@"%@",operation.request.URL.absoluteString);
              //NSLog(@"%@",operation);
              NSLog(@"Error: %@", error);
              if (completion) {
                  completion(NO, error);
              }
              
          }];

}

-(void)uploadVideoThumbnail:(NSData *)imageData Uid:(NSString *)uid completion:(void(^)(bool succeed,NSError *error))completion
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *key=[NSString stringWithFormat:@"video-%@-%@-thumbnail.jpg",uid,[self timestamp]];
    
    NSDictionary *parameters =@{@"key":key,@"token":[self LoginToken], @"timestamp": [self timestamp]};
    NSString *URLStr = [VNHost stringByAppendingString:@"qiniuVideoThumbnailToken.php"];
    [manager POST:URLStr parameters:parameters
          success:^(AFHTTPRequestOperation *operation,id responseObject) {
              NSLog(@"Success: %@", responseObject);
              //获得签名信息
              if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]&&[responseObject objectForKey:@"status"]) {
                  NSString *token=[responseObject objectForKey:@"Qtoken"];
                  QiniuSimpleUploader *sUploader=[QiniuSimpleUploader uploaderWithToken:token];
                  sUploader.delegate= self;
                  QiniuPutExtra *extra=[[QiniuPutExtra alloc]init];
                  extra.params= @{@"x:uid":uid};
                  kQiniuUpHosts[0]=@"http://upload.qiniu.com/";
                  [sUploader uploadFileData:imageData key:key extra:extra];
              }
              if (completion) {
                  completion(YES, nil);
              }
          } failure:^(AFHTTPRequestOperation *operation,NSError *error) {
              //NSLog(@"%@",operation.request.URL.absoluteString);
              //NSLog(@"%@",operation);
              NSLog(@"Error: %@", error);
              if (completion) {
                  completion(NO, error);
              }
              
          }];
}
- (NSString *)timestamp {
    //    NSLog(@"%@", [[self CCT_Date] description]);
    //    return [NSString stringWithFormat:@"%f", [[self CCT_Date] timeIntervalSince1970]];
    //http://zmysp.sinaapp.com/timestamp.php
    if ([VNHTTPRequestManager isReachable]) {
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

- (NSString *)LoginToken {
    NSString *originTokenStr = [[NSString stringFromDate:[NSDate date]] stringByAppendingString:@"#$@%!*zmy"];
    //NSLog(@"%@", originTokenStr);
    return [originTokenStr md5];
}

- (void)uploadProgressUpdated:(NSString *)filePath percent:(float)percent
{
    [self.delegate uploadProgressUpdated:filePath percent:percent];
}

// Upload completed successfully.
- (void)uploadSucceeded:(NSString *)filePath ret:(NSDictionary *)ret
{
    [self.delegate uploadSucceeded:filePath ret:ret];
}

// Upload failed.
- (void)uploadFailed:(NSString *)filePath error:(NSError *)error
{
    [self.delegate uploadFailed:filePath error:error];
}


@end
