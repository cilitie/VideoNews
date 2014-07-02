//
//  VNHTTPRequestManager.h
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <Foundation/Foundation.h>
//model
#import "VNNews.h"
#import "VNUser.h"
#import "VNMedia.h"
#import "VNCategory.h"
#import "VNComment.h"

@interface VNHTTPRequestManager : NSObject

+ (void)newsListFromTime:(NSString *)time completion:(void(^)(NSArray *newsArr, NSError *error))completion;
+ (void)categoryList:(void(^)(NSArray *categoryArr, NSError *error))completion;
+ (void)commentListForNews:(int)nid timestamp:(NSString *)timestamp completion:(void(^)(NSArray *commemtArr, NSError *error))completion;

+ (NSString *)timestamp;

@end
