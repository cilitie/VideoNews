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
#import "VNAuthUser.h"

@interface VNHTTPRequestManager : NSObject

#pragma mark - Home

+ (void)newsListFromTime:(NSString *)time completion:(void(^)(NSArray *newsArr, NSError *error))completion;
+ (void)commentListForNews:(int)nid timestamp:(NSString *)timestamp completion:(void(^)(NSArray *commemtArr, NSError *error))completion;
+ (void)favouriteNews:(int)nid operation:(NSString *)operation userID:(NSString *)uid user_token:(NSString *)user_token completion:(void(^)(BOOL succeed, NSError *error))completion;

#pragma mark - Search

+ (void)categoryList:(void(^)(NSArray *categoryArr, NSError *error))completion;
+ (void)categoryNewsFromTime:(NSString *)time category:(int)cid completion:(void(^)(NSArray *categoryNewsArr, NSError *error))completion;
+ (void)searchResultForKey:(NSString *)keyWord timestamp:(NSString *)timestamp searchType:(NSString *)searchType completion:(void(^)(NSArray *resultNewsArr, NSError *error))completion;

#pragma mark - Login

+ (void)loginWithUser:(VNAuthUser *)user completion:(void(^)(BOOL succeed, NSError *error))completion;

#pragma mark - Utility

+ (NSString *)timestamp;

@end
