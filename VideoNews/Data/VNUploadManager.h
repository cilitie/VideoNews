//
//  VNUploadManager.h
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-29.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (add)

- (NSString *)md5;

@end

@interface VNUploadManager : NSObject

#pragma mark - Upload
//上传相关
+(void)uploadImage:(NSData *)imageData Uid:(NSString *)uid Delegate:(id *)delegate completion:(void(^)(bool succeed,NSError *error))completion;

@end
