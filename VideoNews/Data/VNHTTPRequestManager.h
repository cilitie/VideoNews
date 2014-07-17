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
#import "VNMessage.h"

@interface VNHTTPRequestManager : NSObject

#pragma mark - Home

+ (void)newsListFromTime:(NSString *)time completion:(void(^)(NSArray *newsArr, NSError *error))completion;
+ (void)commentListForNews:(int)nid timestamp:(NSString *)timestamp completion:(void(^)(NSArray *commemtArr, NSError *error))completion;
+ (void)commentByCid:(int)cid completion:(void(^)(NSArray *comment, NSError *error))completion;
+ (void)favouriteNews:(int)nid operation:(NSString *)operation userID:(NSString *)uid user_token:(NSString *)user_token completion:(void(^)(BOOL succeed, NSError *error))completion;
//评论相关
+ (void)commentNews:(int)nid content:(NSString *)content completion:(void(^)(BOOL succeed, VNComment *comment, NSError *error))completion;
+ (void)replyComment:(int)cid replyUser:(NSString *)reply_uid replyNews:(int)nid content:(NSString *)content completion:(void(^)(BOOL succeed, VNComment *comment, NSError *error))completion;
+ (void)deleteComment:(int)cid news:(int)nid userID:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(BOOL succeed, NSError *error))completion;
//举报相关
+ (void)report:(NSString *)objectID type:(NSString *)type userID:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(BOOL succeed, NSError *error))completion;
//收藏相关
+ (void)favouriteNewsListFor:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(NSArray *favouriteNewsArr, NSError *error))completion;

#pragma mark - Search

+ (void)categoryList:(void(^)(NSArray *categoryArr, NSError *error))completion;
+ (void)categoryNewsFromTime:(NSString *)time category:(int)cid completion:(void(^)(NSArray *categoryNewsArr, NSError *error))completion;
+ (void)searchResultForKey:(NSString *)keyWord timestamp:(NSString *)timestamp searchType:(NSString *)searchType completion:(void(^)(NSArray *resultNewsArr, NSError *error))completion;

#pragma mark - Login

+ (void)loginWithUser:(VNAuthUser *)user completion:(void(^)(BOOL succeed, NSError *error))completion;

#pragma mark - Notification

+ (void)messageListForUser:(NSString *)uid userToken:(NSString *)user_token timestamp:(NSString *)timestamp completion:(void(^)(NSArray *messageArr, NSError *error))completion;

#pragma mark - User
//关注相关
+ (void)idolListForUser:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(NSArray *idolArr, NSError *error))completion;
+ (void)followIdol:(NSString *)idol_uid follower:(NSString *)fan_uid userToken:(NSString *)user_token operation:(NSString *)type completion:(void(^)(BOOL succeed, NSError *error))completion;

#pragma mark - Utility

+ (NSString *)timestamp;
+ (BOOL)isReachableViaWiFi;

@end
