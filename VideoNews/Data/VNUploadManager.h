//
//  VNUploadManager.h
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-29.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol VNUploadManagerDelegate <NSObject>

@optional

@required

- (void)uploadProgressUpdated:(NSString *)filePath percent:(float)percent;

// Upload completed successfully.
- (void)uploadSucceeded:(NSString *)key ret:(NSDictionary *)ret;

// Upload failed.
- (void)uploadFailed:(NSString *)key error:(NSError *)error;

@end

@interface VNUploadManager : NSObject

@property (assign,nonatomic) id<VNUploadManagerDelegate>delegate;

#pragma mark - Upload
//上传相关
+ (instancetype)sharedInstance;
-(void)uploadImage:(NSData *)imageData Uid:(NSString *)uid completion:(void(^)(bool succeed,NSError *error))completion;
-(void)uploadVideo:(NSData *)videoData Uid:(NSString *)uid Title:(NSString *)title Tags:(NSString *)tags ThumbnailTime:(CGFloat )thumbnailTime completion:(void(^)(bool succeed,NSError *error))completion;

@end
