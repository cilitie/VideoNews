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

#import <CommonCrypto/CommonDigest.h>

@interface NSString (addition)

- (NSString *)md5;
+ (NSString *)stringFromDate:(NSDate *)date;

@end

@interface VNHTTPRequestManager : NSObject

#pragma mark - Home

+(void)isNewsDeleted:(int)nid completion:(void(^)(BOOL isDeleted,NSError *error))completion;

+ (void)newsListFromTime:(NSString *)time completion:(void(^)(NSArray *newsArr, NSError *error))completion;
+ (void)commentListForNews:(int)nid timestamp:(NSString *)timestamp completion:(void(^)(NSArray *commemtArr, BOOL isNewsDeleted,NSError *error))completion;
+ (void)commentByCid:(int)cid completion:(void(^)(NSArray *comment, NSError *error))completion;
+ (void)favouriteNews:(int)nid operation:(NSString *)operation userID:(NSString *)uid user_token:(NSString *)user_token completion:(void(^)(BOOL succeed,BOOL isNewsDeleted, int like_count,int user_like_count,NSError *error))completion;
//profile点赞专用接口
+ (void)profileFavouriteNews:(int)nid operation:(NSString *)operation userID:(NSString *)uid user_token:(NSString *)user_token completion:(void(^)(BOOL succeed,BOOL isNewsDeleted, VNNews * news,int user_like_count,NSError *error))completion;
+ (void)deleteNews:(int)nid userID:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(BOOL succeed,int news_count,NSError *error))completion;
//评论相关
+ (void)commentNews:(int)nid content:(NSString *)content completion:(void(^)(BOOL succeed,BOOL isNewsDeleted, VNComment *comment,int comment_count, NSError *error))completion;
+ (void)replyComment:(int)cid replyUser:(NSString *)reply_uid replyNews:(int)nid content:(NSString *)content completion:(void(^)(BOOL succeed,BOOL isNewsDeleted,BOOL isCommentDeleted, VNComment *comment,int comment_count, NSError *error))completion;
+ (void)deleteComment:(int)cid news:(int)nid userID:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(BOOL succeed,BOOL isNewsDeleted, int comment_count,NSError *error))completion;
//举报相关
+ (void)report:(NSString *)objectID type:(NSString *)type userID:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(BOOL succeed, NSError *error))completion;
//收藏相关
+ (void)favouriteNewsListFor:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(NSArray *favouriteNewsArr, NSError *error))completion;
//补丁相关
+ (void)getOneNews:(int)nid completion:(void(^)(BOOL succeed,VNNews *news,NSError *error))completion;

#pragma mark - Search

+ (void)categoryList:(void(^)(NSArray *categoryArr, NSError *error))completion;
+ (void)categoryNewsFromTime:(NSString *)time category:(int)cid completion:(void(^)(NSArray *categoryNewsArr, NSError *error))completion;
+ (void)searchResultForKey:(NSString *)keyWord timestamp:(NSString *)timestamp searchType:(NSString *)searchType completion:(void(^)(NSArray *resultNewsArr, NSError *error))completion;

#pragma mark - Login

+ (void)loginWithUser:(VNAuthUser *)user completion:(void(^)(BOOL succeed, NSError *error))completion;

#pragma mark - Notification

+ (void)messageListForUser:(NSString *)uid userToken:(NSString *)user_token timestamp:(NSString *)timestamp completion:(void(^)(NSArray *messageArr, NSError *error))completion;
+ (void)deleteMessage:(NSString *)mid completion:(void(^)(BOOL succeed, NSError *error))completion;

#pragma mark - User
//关注相关
+ (void)idolListForUser:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(NSArray *idolArr, NSError *error))completion;
+ (void)followIdol:(NSString *)idol_uid follower:(NSString *)fan_uid userToken:(NSString *)user_token operation:(NSString *)type completion:(void(^)(BOOL succeed,int fans_count, int idol_count,NSError *error))completion;
+ (void)videoListForUser:(NSString *)uid type:(NSString *)type fromTime:(NSString *)lastTimeStamp completion:(void(^)(NSArray *videoArr,NSError *error))completion;
+ (void)favVideoListForUser:(NSString *)uid userToken:(NSString *)user_token fromTime:(NSString *)lastTimeStamp completion:(void(^)(NSArray *videoArr, NSString * moreTimestamp,NSError *error))completion;

+ (void)userInfoForUser:(NSString *)uid completion:(void(^)(VNUser *userInfo, NSError *error))completion;
+ (void)userListForUser:(NSString *)uid type:(NSString *)type pageTime:(NSString *)pageTime completion:(void(^)(NSArray *userArr, NSString *lastTimeStamp, NSError *error))completion;
+ (void)updateUserInfo:(NSDictionary *)userInfo completion:(void(^)(BOOL succeed, NSError *error))completion;
//+(void)thumbnailURLForUser:(NSString *)uid completion:(void(^)(BOOL succeed, NSString *thumbnailURL, NSError *error))completion;

#pragma mark - Upload
//上传相关
//+(void)uploadImage:(NSData *)imageData Uid:(NSString *)uid Delegate:(id *)delegate completion:(void(^)(bool succeed,NSError *error))completion;


#pragma mark - Utility

+ (NSString *)timestamp;
+ (BOOL)isReachable;
+ (BOOL)isReachableViaWiFi;


@end
