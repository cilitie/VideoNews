//
//  VNHTTPRequestManager.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#pragma mark - NSString Extension

@implementation NSString (addition)

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

+ (NSString *)stringFromDate:(NSDate *)date {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HH"];
    NSString *destDateString = [dateFormatter stringFromDate:date];
    
    return destDateString;
}

@end

#import "VNHTTPRequestManager.h"
#import "AFNetworking.h"
#import "Reachability.h"

static Reachability *reach = nil;
static int pagesize = 10;

@implementation VNHTTPRequestManager

#pragma mark - Home
+(void)isNewsDeleted:(int)nid completion:(void(^)(BOOL isDeleted,NSError *error))completion
{
    //http://182.92.103.134:8080/engine/isNewsDeleted.php?token=f961f003dd383bc39eb53c5b7e5fd046&timestamp=1404232200&nid=1
    NSString *URLStr = [VNHost stringByAppendingString:@"isNewsDeleted.php"];
    NSDictionary *param = @{@"token": [self token], @"timestamp": [self timestamp],@"nid":[NSNumber numberWithInt:nid]};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        BOOL isDeleted=false;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                isDeleted=[[responseObject objectForKey:@"isDeleted"] boolValue];
            }
        }
        if (completion) {
            completion(isDeleted,nil);
        }
        
    }
    failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
                        completion(false, error);
        }
    }];
}

+ (void)newsListFromTime:(NSString *)time completion:(void(^)(NSArray *newsArr, NSError *error))completion {
    //http://182.92.103.134:8080/engine/viewnews.php?pagesize=10&pagetime=1406600863&timestamp=1406600863&token=4bd5bd40d36deecab5e9f152da873b5e
    NSString *URLStr = [VNHost stringByAppendingString:@"viewnews.php"];
    NSDictionary *param = @{@"token": [self token], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp": [self timestamp],@"pagetime":time};
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![self isReachable]) {
            NSString *requestURL = [URLStr stringByAppendingString:[NSString stringWithFormat:@"?pagesize=%d", pagesize]];
            [VNCacheDataManager cacheDataFromURL:requestURL completion:^(NSArray *queryArr) {
                if (queryArr && queryArr.count && completion) {
                    completion(queryArr, nil);
                }
            }];
        }
        else {
            [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //NSLog(@"%@", responseObject);
               //NSLog(@"%@", operation);
                VNNews *news = nil;
                VNMedia *media = nil;
                NSMutableArray *newsArr = [NSMutableArray array];
                if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                    BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
                    if (responseStatus) {
                        for (NSDictionary *newsDic in [responseObject objectForKey:@"list"]) {
                            news = [[VNNews alloc] initWithDict:newsDic];
                            
                            NSDictionary *userDic = [newsDic objectForKey:@"author"];
                            news.author = [[VNUser alloc] initWithDict:userDic];
                            
                            NSArray *mediaArr = [newsDic objectForKey:@"media"];
                            NSMutableArray *mediaMutableArr = [NSMutableArray array];
                            for (NSDictionary *mediaDic in mediaArr) {
                                media = [[VNMedia alloc] initWithDict:mediaDic];
                                [mediaMutableArr addObject:media];
                            }
                            news.mediaArr = mediaMutableArr;
                            
                            [newsArr addObject:news];
                        }
                    }
                }
                
                //本地缓存
                if (newsArr.count) {
                    NSString *requestURL = [URLStr stringByAppendingString:[NSString stringWithFormat:@"?pagesize=%d", pagesize]];
                    [VNCacheDataManager addCacheData:newsArr fromURL:requestURL completion:^(BOOL succeeded) {
                        if (succeeded) {
                            NSLog(@"newsArr cached!!!");
                        }
                    }];
                }
                
                if (completion) {
                    completion(newsArr, nil);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completion) {
                    completion(nil, error);
                }
            }];
        }
    });
}

+ (void)commentListForNews:(int)nid timestamp:(NSString *)timestamp completion:(void(^)(NSArray *commemtArr,BOOL isNewsDeleted ,NSError *error))completion {
    //http://zmysp.sinaapp.com/chat.php?nid=1&timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046
    NSString *URLStr = [VNHost stringByAppendingString:@"chat.php"];
//    NSDictionary *param = @{@"nid": [NSNumber numberWithInt:nid], @"pagesize": [NSNumber numberWithInt:pagesize], @"token": [self tokenFromTimestamp:timestamp], @"timestamp": timestamp};
    NSDictionary *param = @{@"nid": [NSNumber numberWithInt:nid], @"pagesize": [NSNumber numberWithInt:pagesize], @"token": [self token], @"timestamp": [self timestamp],@"pagetime":timestamp};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
       // NSLog(@"%@", operation);
        VNComment *comment = nil;
        NSMutableArray *commentArr = [NSMutableArray array];
        BOOL isNewsDeleted=NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            //FIXME: Server Error, Fix Later
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            isNewsDeleted=[[responseObject objectForKey:@"newsDeleted"] boolValue];
            if (responseStatus &&[responseObject[@"list"] isKindOfClass:[NSDictionary class]]) {
                
                NSArray *responseArr = responseObject[@"list"][@"comment"];
                for (NSDictionary *dic in responseArr) {
                    comment = [[VNComment alloc] initWithDict:dic];
                    NSDictionary *userDic = [dic objectForKey:@"author"];
                    comment.author = [[VNUser alloc] initWithDict:userDic];
                    [commentArr addObject:comment];
                }
            }
        }
        if (completion) {
            completion(commentArr,isNewsDeleted, nil);
            return;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
       // NSLog(@"%@",operation);
        if (completion) {
            completion(nil,NO, error);
        }
    }];
}

+ (void)commentByCid:(int)cid completion:(void(^)(NSArray *comment, NSError *error))completion {
    //http://zmysp.sinaapp.com/oneComment.php?token=f961f003dd383bc39eb53c5b7e5fd046&pid=1&timestamp=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"oneComment.php"];
    //    NSDictionary *param = @{@"nid": [NSNumber numberWithInt:nid], @"pagesize": [NSNumber numberWithInt:pagesize], @"token": [self tokenFromTimestamp:timestamp], @"timestamp": timestamp};
    NSDictionary *param = @{@"pid": [NSNumber numberWithInt:cid], @"token": [self token], @"timestamp": [self timestamp]};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //        NSLog(@"%@", responseObject);
        //NSLog(@"%@", operation);
        VNComment *comment = nil;
        NSMutableArray *commentArr = [NSMutableArray array];
       // NSLog(@"%@", responseObject[@"comment"]);
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            //FIXME: Server Error, Fix Later
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            //BOOL commentBOOL = [[responseObject objectForKey:@"comment"] boolValue];
            //若评论删除，服务器返回的comment字段为false,即为0
            if (responseStatus && [responseObject[@"comment"] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *responseDic = responseObject[@"comment"];
                //for (NSDictionary *dic in responseArr) {
                    comment = [[VNComment alloc] initWithDict:responseDic];
                    NSDictionary *userDic = [responseDic objectForKey:@"author"];
                    comment.author = [[VNUser alloc] initWithDict:userDic];
                    [commentArr addObject:comment];
               // }
            }
        }
        if (completion) {
            completion(commentArr, nil);
            return;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}


+ (void)favouriteNews:(int)nid operation:(NSString *)operation userID:(NSString *)uid user_token:(NSString *)user_token completion:(void(^)(BOOL succeed,BOOL isNewsDeleted, int like_count,int user_like_count,NSError *error))completion {
    //http://zmysp.sinaapp.com/op.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&cmd=add&id=1&user_token=f1517c15fd0da75cc1889e9537392a9c
    NSString *URLStr = [VNHost stringByAppendingString:@"op.php"];
    NSDictionary *param = @{@"id": [NSNumber numberWithInt:nid], @"uid": uid, @"cmd": operation, @"user_token": user_token, @"token": [self token], @"timestamp": [self timestamp]};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%d",nid);
        NSLog(@"%@", responseObject);
        BOOL operationSuccess = NO;
        BOOL isNewsDeleted=NO;
        int like_count=0;
        int user_like_count=0;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                operationSuccess = [[responseObject objectForKey:@"success"] boolValue];
                isNewsDeleted = [[responseObject objectForKey:@"newsDeleted"] boolValue];
                like_count=[[responseObject objectForKey:@"like_count"] intValue];
                user_like_count=[[responseObject objectForKey:@"user_like_count"] intValue];
            }
        }
        if (completion) {
            completion(operationSuccess,isNewsDeleted,like_count,user_like_count ,nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO,NO,0,0,error);
        }
    }];
}

+ (void)profileFavouriteNews:(int)nid operation:(NSString *)operation userID:(NSString *)uid user_token:(NSString *)user_token completion:(void(^)(BOOL succeed,BOOL isNewsDeleted,VNNews *news,int user_like_count,NSError *error))completion {
    //http://zmysp.sinaapp.com/op.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&cmd=add&id=1&user_token=f1517c15fd0da75cc1889e9537392a9c
    NSString *URLStr = [VNHost stringByAppendingString:@"opForProfile.php"];
    NSDictionary *param = @{@"id": [NSNumber numberWithInt:nid], @"uid": uid, @"cmd": operation, @"user_token": user_token, @"token": [self token], @"timestamp": [self timestamp]};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",operation);
        NSLog(@"%@", responseObject);
        BOOL operationSuccess = NO;
        BOOL isNewsDeleted=NO;
        VNNews * news=nil;
        VNMedia *media = nil;
        int user_like_count=0;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                operationSuccess = [[responseObject objectForKey:@"success"] boolValue];
                isNewsDeleted = [[responseObject objectForKey:@"newsDeleted"] boolValue];
                if ([responseObject[@"news"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary * newsDic=[responseObject objectForKey:@"news"];
                    news = [[VNNews alloc] initWithDict:newsDic];
                    
                    NSDictionary *userDic = [newsDic objectForKey:@"author"];
                    news.author = [[VNUser alloc] initWithDict:userDic];
                    
                    NSArray *mediaArr = [newsDic objectForKey:@"media"];
                    NSMutableArray *mediaMutableArr = [NSMutableArray array];
                    for (NSDictionary *mediaDic in mediaArr) {
                        media = [[VNMedia alloc] initWithDict:mediaDic];
                        [mediaMutableArr addObject:media];
                    }
                    news.mediaArr = mediaMutableArr;
                }
                user_like_count=[[responseObject objectForKey:@"user_like_count"] intValue];
            }
        }
        if (completion) {
            completion(operationSuccess,isNewsDeleted,news,user_like_count ,nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO,NO,nil,0,error);
        }
    }];
}


+ (void)deleteNews:(int)nid userID:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(BOOL succeed,int news_count,NSError *error))completion{
    //http://182.92.103.134:8080/engine/deleteNews.php?token=f961f003dd383bc39eb53c5b7e5fd046&timestamp=1404232200&nid=1&uid=1300000001&user_token=f1517c15fd0da75cc1889e9537392a9c
    NSString *URLStr = [VNHost stringByAppendingString:@"deleteNews.php"];
    NSDictionary *param = @{@"nid": [NSNumber numberWithInt:nid], @"uid": uid, @"user_token": user_token, @"token": [self token], @"timestamp": [self timestamp]};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"%@", operation);
        BOOL operationSuccess = NO;
        //BOOL isNewsDeleted=NO;
        int news_count=0;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                operationSuccess = [[responseObject objectForKey:@"success"] boolValue];
                news_count=[[responseObject objectForKey:@"news_count"]intValue];
                //isNewsDeleted = [[responseObject objectForKey:@"newsDeleted"] boolValue];
                //like_count=[[responseObject objectForKey:@"like_count"] intValue];
            }
        }
        if (completion) {
            completion(operationSuccess,news_count,nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO,0,error);
        }
    }];
}

#pragma mark - 评论相关

+ (void)commentNews:(int)nid content:(NSString *)content completion:(void(^)(BOOL succeed,BOOL isNewsDeleted, VNComment *comment ,int comment_count,NSError *error))completion {
    //http://zmysp.sinaapp.com/comment.php?uid=1&text=thisisatest&token=f961f003dd383bc39eb53c5b7e5fd046&nid=1&type=pub&timestamp=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"comment.php"];
    NSString *uid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    //zmy add
    NSString * user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];

    if (!uid) {
        uid = @"1";
        user_token=@"";
    }
    //zmy modify
    
    NSDictionary *param = @{@"uid": uid, @"nid": [NSString stringWithFormat:@"%d", nid], @"text": content, @"type": @"pub", @"token": [self token], @"timestamp": [self timestamp],@"user_token":user_token};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"%@", operation);
        //NSLog(@"%@",responseObject);
        VNComment *comment = nil;
        BOOL commentSuccess = NO;
        BOOL isNewsDeleted=NO;
        int comment_count=0;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            isNewsDeleted =[[responseObject objectForKey:@"newsDeleted"] boolValue];
            commentSuccess = [[responseObject objectForKey:@"success"] boolValue];
            if (responseStatus &&commentSuccess &&[[responseObject objectForKey:@"comment"] isKindOfClass:[NSDictionary class]]) {
                comment_count=[[responseObject objectForKey:@"comment_count"] intValue];
                NSDictionary *commentDic = [responseObject objectForKey:@"comment"];
                if (commentDic.count) {
                    comment = [[VNComment alloc] initWithDict:commentDic];
                    NSDictionary *userDic = [commentDic objectForKey:@"author"];
                    comment.author = [[VNUser alloc] initWithDict:userDic];
                }
            }
            
        }
        if (completion) {
            completion(commentSuccess,isNewsDeleted, comment, comment_count,nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@", operation);
        if (completion) {
            completion(NO, NO,nil,0, error);
        }
    }];
}

+ (void)replyComment:(int)cid replyUser:(NSString *)reply_uid replyNews:(int)nid content:(NSString *)content completion:(void(^)(BOOL succeed,BOOL isNewsDeleted,BOOL isCommentDeleted, VNComment *comment,int comment_count, NSError *error))completion {
    //http://zmysp.sinaapp.com/comment.php?uid=1&text=thisisatest&token=f961f003dd383bc39eb53c5b7e5fd046&nid=1&type=pub&timestamp=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"comment.php"];
    NSString *uid = nil;
    NSString *user_token = nil;
    uid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    NSLog(@"user_token:%@",user_token);
    if (!uid) {
        uid = @"1";
        user_token = @"";
    }
    
    NSDictionary *param = @{@"uid": uid, @"nid": [NSString stringWithFormat:@"%d", nid], @"pid": [NSString stringWithFormat:@"%d", cid], @"reply_uid": reply_uid, @"text": content, @"type": @"reply", @"token": [self token], @"timestamp": [self timestamp], @"user_token": user_token};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        NSLog(@"%@",operation.request.URL.absoluteString);
        VNComment *comment = nil;
        BOOL replySuccess = NO;
        BOOL isNewsDeleted=NO;
        BOOL isCommentDeleted=NO;
        int comment_count=0;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            isNewsDeleted= [[responseObject objectForKey:@"newsDeleted"] boolValue];
            isCommentDeleted=[[responseObject objectForKey:@"commentDeleted"] boolValue];
            replySuccess = [[responseObject objectForKey:@"success"] boolValue];
            if (responseStatus && replySuccess &&[[responseObject objectForKey:@"comment"] isKindOfClass:[NSDictionary class]]) {
                comment_count= [[responseObject objectForKey:@"comment_count"] intValue];
                NSDictionary *commentDic = [responseObject objectForKey:@"comment"];
                if (commentDic.count) {
                    comment = [[VNComment alloc] initWithDict:commentDic];
                    NSDictionary *userDic = [commentDic objectForKey:@"author"];
                    comment.author = [[VNUser alloc] initWithDict:userDic];
                }
            }
            
        }
        if (completion) {
            completion(replySuccess,isNewsDeleted,isCommentDeleted, comment, comment_count,nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",operation.request.URL.absoluteString);
        if (completion) {
            completion(NO,NO,NO, nil,0, error);
        }
    }];
}

+ (void)deleteComment:(int)cid news:(int)nid userID:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(BOOL succeed,BOOL isNewsDeleted, int comment_count,NSError *error))completion {
    //http://zmysp.sinaapp.com/comment.php?uid=1&text=thisisatest&token=f961f003dd383bc39eb53c5b7e5fd046&nid=1&type=pub&timestamp=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"comment.php"];
    NSDictionary *param = @{@"uid": uid, @"nid": [NSString stringWithFormat:@"%d", nid], @"pid": [NSString stringWithFormat:@"%d", cid], @"type": @"del", @"token": [self token], @"timestamp": [self timestamp], @"user_token": user_token};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"%@", responseObject);
        //NSLog(@"%@",operation);
        BOOL deleteSuccess = NO;
        BOOL isNewsDeleted =NO;
        int comment_count=0;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            isNewsDeleted = [[responseObject objectForKey:@"newsDeleted"] boolValue];
            deleteSuccess = [[responseObject objectForKey:@"success"] boolValue];
            if (responseStatus&&deleteSuccess) {
                comment_count=[[responseObject objectForKey:@"comment_count"] intValue];
            }
        }
        if (completion) {
            completion(deleteSuccess,isNewsDeleted, comment_count,nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO,NO, 0,error);
        }
    }];
}

#pragma mark - 举报相关

+ (void)report:(NSString *)objectID type:(NSString *)type userID:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(BOOL succeed, NSError *error))completion {
    //http://zmysp.sinaapp.com/report.php?id=1&timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1287669920034&user_token=8d81463b854466d4d2e2ba9d4d54428c&type=reportNews
    NSString *URLStr = [VNHost stringByAppendingString:@"report.php"];
    NSDictionary *param = @{@"uid": uid, @"id": objectID, @"type": type, @"token": [self token], @"timestamp": [self timestamp], @"user_token": user_token};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", operation.request.URL);
//        NSLog(@"%@", responseObject);
        BOOL reportSuccess = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                reportSuccess = [[responseObject objectForKey:@"success"] boolValue];
            }
        }
        if (completion) {
            completion(reportSuccess, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
}

#pragma mark - 收藏相关
+ (void)favouriteNewsListFor:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(NSArray *favouriteNewsArr, NSError *error))completion {
    //h ttp://zmysp.sinaapp.com/likesList.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&user_token=f1517c15fd0da75cc1889e9537392a9c
    if (user_token==nil ||uid==nil) {
        return;
    }
    NSString *URLStr = [VNHost stringByAppendingString:@"likesList.php"];
    NSDictionary *param = @{@"uid": uid, @"token": [self token], @"timestamp": [self timestamp], @"user_token": user_token};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        NSMutableArray *favouriteNewsArr = [NSMutableArray array];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                if ([[responseObject objectForKey:@"list"] count]) {
                    [favouriteNewsArr addObjectsFromArray:[responseObject objectForKey:@"list"]];
                }
            }
        }
        
        if (completion) {
            completion(favouriteNewsArr, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (void)getOneNews:(int)nid completion:(void(^)(BOOL succeed,VNNews *news,NSError *error))completion
{
    //http://182.92.103.134:8080/engine/oneNews.php?nid=247&timestamp=1407603214&token=56de79adc4ffeea2fa3ae916965fd59e
    NSString *URLStr = [VNHost stringByAppendingString:@"oneNews.php"];
    NSDictionary *param = @{@"nid": [NSNumber numberWithInt:nid], @"token": [self token], @"timestamp": [self timestamp]};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //        NSLog(@"%@", responseObject);
        VNNews *news = nil;
        VNMedia *media = nil;
        BOOL responseStatus=NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"news"]isKindOfClass:[NSDictionary class]]) {
                NSDictionary *newsDic= [responseObject objectForKey:@"news"];
                    news = [[VNNews alloc] initWithDict:newsDic];
                    NSDictionary *userDic = [newsDic objectForKey:@"author"];
                    news.author = [[VNUser alloc] initWithDict:userDic];
                    
                    NSArray *mediaArr = [newsDic objectForKey:@"media"];
                    NSMutableArray *mediaMutableArr = [NSMutableArray array];
                    for (NSDictionary *mediaDic in mediaArr) {
                        media = [[VNMedia alloc] initWithDict:mediaDic];
                        if ([media.type rangeOfString:@"image"].location != NSNotFound) {
                            news.imgMdeia = media;
                        }
                        else {
                            news.videoMedia = media;
                        }
                        [mediaMutableArr addObject:media];
                    }
                    news.mediaArr = mediaMutableArr;
                    
                }
        }
        if (completion) {
            completion(responseStatus,news, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO,nil, error);
        }
    }];
}

#pragma mark - Search

+ (void)categoryList:(void(^)(NSArray *categoryArr, NSError *error))completion {
    //http://182.92.103.134:8080/engine/class.php?timestamp=1406601037&token=4bd5bd40d36deecab5e9f152da873b5e
    NSString *URLStr = [VNHost stringByAppendingString:@"class.php"];
    NSDictionary *param = @{@"token": [self token], @"timestamp": [self timestamp]};
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![self isReachable]) {
            NSString *requestURL = URLStr;
            [VNCacheDataManager cacheDataFromURL:requestURL completion:^(NSArray *queryArr) {
                if (queryArr && queryArr.count && completion) {
                    completion(queryArr, nil);
                }
            }];
        }
        else {
            [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"%@", responseObject);
                VNCategory *category = nil;
                NSMutableArray *categoryArr = [NSMutableArray array];
                
                if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                    BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
                    if (responseStatus &&[[responseObject objectForKey:@"list"]isKindOfClass:[NSDictionary class]]) {
                        NSArray *responseArr = responseObject[@"list"][@"classes"];
                        //            NSLog(@"%@", responseArr);
                        for (NSDictionary *categoryDic in responseArr) {
                            category = [[VNCategory alloc] initWithDict:categoryDic];
                            [categoryArr addObject:category];
                        }
                    }
                }
                //本地缓存
                if (categoryArr.count) {
                    NSString *requestURL = URLStr;
                    [VNCacheDataManager addCacheData:categoryArr fromURL:requestURL completion:^(BOOL succeeded) {
                        if (succeeded) {
                            NSLog(@"categoryArr cached!!!");
                        }
                    }];
                }
                
                if (completion) {
                    completion(categoryArr, nil);
                    return;
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completion) {
                    completion(nil, error);
                }
            }];
        }
    });
}

+ (void)categoryNewsFromTime:(NSString *)time category:(int)cid completion:(void(^)(NSArray *categoryNewsArr, NSError *error))completion {
    //http://182.92.103.134:8080/engine/viewnews.php?cid=1&pagesize=10&pagetime=1406601074&timestamp=1406601074&token=4bd5bd40d36deecab5e9f152da873b5e
    NSString *URLStr = [VNHost stringByAppendingString:@"viewnews.php"];
    NSDictionary *param = @{@"token": [self token], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp": [self timestamp], @"pagetime": time, @"cid": [NSNumber numberWithInt:cid]};
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (![self isReachable]) {
            NSString *requestURL = [URLStr stringByAppendingString:[NSString stringWithFormat:@"?cid=%d&pagesize=%d", cid, pagesize]];
            [VNCacheDataManager cacheDataFromURL:requestURL completion:^(NSArray *queryArr) {
                if (queryArr && queryArr.count && completion) {
                    completion(queryArr, nil);
                }
            }];
        }
        else {
            [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
                //        NSLog(@"%@", responseObject);
                VNNews *news = nil;
                VNMedia *media = nil;
                NSMutableArray *newsArr = [NSMutableArray array];
                if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                    BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
                    if (responseStatus&&[[responseObject objectForKey:@"list"]isKindOfClass:[NSDictionary class]]) {
                        for (NSDictionary *newsDic in responseObject[@"list"][@"news"]) {
                            news = [[VNNews alloc] initWithDict:newsDic];
                            
                            NSDictionary *userDic = [newsDic objectForKey:@"author"];
                            news.author = [[VNUser alloc] initWithDict:userDic];
                            
                            NSArray *mediaArr = [newsDic objectForKey:@"media"];
                            NSMutableArray *mediaMutableArr = [NSMutableArray array];
                            for (NSDictionary *mediaDic in mediaArr) {
                                media = [[VNMedia alloc] initWithDict:mediaDic];
                                [mediaMutableArr addObject:media];
                            }
                            news.mediaArr = mediaMutableArr;
                            
                            [newsArr addObject:news];
                        }
                    }
                }
                
                //本地缓存
                if (newsArr.count) {
                    NSString *requestURL = [URLStr stringByAppendingString:[NSString stringWithFormat:@"?cid=%d&pagesize=%d", cid, pagesize]];
                    [VNCacheDataManager addCacheData:newsArr fromURL:requestURL completion:^(BOOL succeeded) {
                        if (succeeded) {
                            NSLog(@"newsArr cached!!!");
                        }
                    }];
                }
                
                if (completion) {
                    completion(newsArr, nil);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (completion) {
                    completion(nil, error);
                }
            }];
        }
    });
}

+ (void)searchResultForKey:(NSString *)keyWord timestamp:(NSString *)timestamp searchType:(NSString *)searchType completion:(void(^)(NSArray *resultNewsArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/so.php?key=lucy&token=f961f003dd383bc39eb53c5b7e5fd046&timestamp=1404232200&category=news
    NSString *URLStr = [VNHost stringByAppendingString:@"so.php"];
//    NSDictionary *param = @{@"token": [self tokenFromTimestamp:timestamp], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp": timestamp, @"key": keyWord, @"category": searchType};
    NSString *TimeStamp = [VNHTTPRequestManager timestamp];
    NSDictionary *param = @{@"token": [self token], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp":TimeStamp,@"pagetime": timestamp, @"key": keyWord, @"category": searchType};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        VNNews *news = nil;
        VNMedia *media = nil;
        VNUser *user = nil;
        NSMutableArray *resultArr = [NSMutableArray array];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"list"]isKindOfClass:[NSDictionary class]]) {
                for (NSDictionary *dic in responseObject[@"list"][@"search"]) {
                    if ([searchType isEqualToString:@"news"]) {
                        news = [[VNNews alloc] initWithDict:dic];
                        
                        NSDictionary *userDic = [dic objectForKey:@"author"];
                        news.author = [[VNUser alloc] initWithDict:userDic];
                        
                        NSArray *mediaArr = [dic objectForKey:@"media"];
                        NSMutableArray *mediaMutableArr = [NSMutableArray array];
                        for (NSDictionary *mediaDic in mediaArr) {
                            media = [[VNMedia alloc] initWithDict:mediaDic];
                            [mediaMutableArr addObject:media];
                        }
                        news.mediaArr = mediaMutableArr;
                        
                        [resultArr addObject:news];
                    }
                    else if ([searchType isEqualToString:@"user"]) {
                        user = [[VNUser alloc] initWithDict:dic];
                        [resultArr addObject:user];
                    }
                }
            }
        }
        
        if (completion) {
            completion(resultArr, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

#pragma mark - Notification
+ (void)messageListForUser:(NSString *)uid userToken:(NSString *)user_token timestamp:(NSString *)timestamp completion:(void(^)(NSArray *commemtArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/message.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&user_token=f1517c15fd0da75cc1889e9537392a9c&pagesize=10&pagetime=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"message.php"];
    //    NSDictionary *param = @{@"nid": [NSNumber numberWithInt:nid], @"pagesize": [NSNumber numberWithInt:pagesize], @"token": [self tokenFromTimestamp:timestamp], @"timestamp": timestamp};
    NSDictionary *param = @{@"uid": uid, @"pagesize": [NSNumber numberWithInt:pagesize], @"token": [self token], @"timestamp": [self timestamp],@"pagetime":timestamp,@"user_token":user_token};
    
    //FIXME: test
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //        NSLog(@"%@", responseObject);
        //NSLog(@"url:%@",operation.request.URL.absoluteString);
        VNMessage *message = nil;
        NSMutableArray *messageArr = [NSMutableArray array];
        
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            //FIXME: Server Error, Fix Later
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"list"]isKindOfClass:[NSArray class]]) {
                NSArray *responseArr = responseObject[@"list"];
                for (NSDictionary *dic in responseArr) {
                    message = [[VNMessage alloc] initWithDict:dic];
                    NSDictionary *userDic = [dic objectForKey:@"sender"];
                    message.sender = [[VNUser alloc] initWithDict:userDic];
                    NSDictionary *newsDic = [dic objectForKey:@"news"];
                    if (![newsDic isEqual:@""]) {
                        message.news=[[VNNews alloc]initWithDict:newsDic];
                        message.news.author=[[VNUser alloc]initWithDict:[newsDic objectForKey:@"author"]];
                        NSArray *mediaArr = [newsDic objectForKey:@"media"];
                        NSMutableArray *mediaMutableArr = [NSMutableArray array];
                        for (NSDictionary *mediaDic in mediaArr) {
                            VNMedia * media = [[VNMedia alloc] initWithDict:mediaDic];
                            [mediaMutableArr addObject:media];
                        }
                        message.news.mediaArr = mediaMutableArr;

                    }
                    [messageArr addObject:message];
                }
            }
        }
        if (completion) {
            completion(messageArr, nil);
            return;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (void)deleteMessage:(NSString *)mid completion:(void(^)(BOOL succeed, NSError *error))completion {
    //http://182.92.103.134:8080/engine/deleteMessage.php?token=f961f003dd383bc39eb53c5b7e5fd046&timestamp=1404232200&mid=1&uid=1300000001&user_token=f1517c15fd0da75cc1889e9537392a9c
    NSString *uid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    NSString *URLStr = [VNHost stringByAppendingString:@"deleteMessage.php"];
    NSDictionary *param = @{@"uid": uid, @"token": [self token], @"timestamp": [self timestamp], @"user_token": user_token, @"mid": mid};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //NSLog(@"%@", operation.request.URL);
        //NSLog(@"%@", responseObject);
        BOOL delSuccess = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                delSuccess = [[responseObject objectForKey:@"success"] boolValue];
            }
        }
        if (completion) {
            completion(delSuccess, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
}

#pragma mark - User

#pragma mark - 关注相关
+ (void)idolListForUser:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(NSArray *idolArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/idolList.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&user_token=f1517c15fd0da75cc1889e9537392a9c
    NSString *URLStr = [VNHost stringByAppendingString:@"idolList.php"];
    NSDictionary *param = @{@"uid": uid, @"token": [self token], @"timestamp": [self timestamp], @"user_token": user_token};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        NSMutableArray *idolArr = [NSMutableArray array];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"list"]isKindOfClass:[NSArray class]]) {
                NSArray *idolList = responseObject[@"list"];
                if ([idolList count]) {
                    for (NSDictionary *dict in idolList) {
                        NSString *uid = dict[@"uid"];
                        [idolArr addObject:uid];
                    }
                }
            }
        }
        
        if (completion) {
            completion(idolArr, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (void)followIdol:(NSString *)idol_uid follower:(NSString *)fan_uid userToken:(NSString *)user_token operation:(NSString *)type completion:(void(^)(BOOL succeed,int fans_count,int idol_count, NSError *error))completion {
    //http://zmysp.sinaapp.com/op_following.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&fan_uid=1300000001&cmd=add&idol_uid=201365768878787&user_token=f1517c15fd0da75cc1889e9537392a9c
    NSString *URLStr = [VNHost stringByAppendingString:@"op_following.php"];
    NSDictionary *param = @{@"idol_uid": idol_uid, @"fan_uid": fan_uid, @"token": [self token], @"timestamp": [self timestamp], @"user_token": user_token, @"cmd": type};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        BOOL followSuccess = NO;
        int fansC=0;
        int idolC=0;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            followSuccess = [[responseObject objectForKey:@"success"] boolValue];
            if (responseStatus&& followSuccess) {
                fansC=[[responseObject objectForKey:@"fans_count"] intValue];
                idolC=[[responseObject objectForKey:@"idol_count"] intValue];

            }
        }
        if (completion) {
            completion(followSuccess,fansC,idolC, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO,0, 0,error);
        }
    }];
}

#pragma mark - 个人页面相关

+ (void)videoListForUser:(NSString *)uid type:(NSString *)type fromTime:(NSString *)lastTimeStamp completion:(void(^)(NSArray *videoArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/getlistByUser.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&cmd=video&pagesize=10$pagetime=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"getlistByUser.php"];
    NSDictionary *param = @{@"uid": uid, @"cmd": type, @"token": [self token], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp": [self timestamp], @"pagetime": lastTimeStamp};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", responseObject);
        VNNews *news = nil;
        VNMedia *media = nil;
        NSMutableArray *newsArr = [NSMutableArray array];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"result"]isKindOfClass:[NSArray class]]) {
                for (NSDictionary *newsDic in [responseObject objectForKey:@"result"]) {
                    news = [[VNNews alloc] initWithDict:newsDic];
                    
                    NSDictionary *userDic = [newsDic objectForKey:@"author"];
                    news.author = [[VNUser alloc] initWithDict:userDic];
                    
                    NSArray *mediaArr = [newsDic objectForKey:@"media"];
                    NSMutableArray *mediaMutableArr = [NSMutableArray array];
                    for (NSDictionary *mediaDic in mediaArr) {
                        media = [[VNMedia alloc] initWithDict:mediaDic];
                        if ([media.type rangeOfString:@"image"].location != NSNotFound) {
                            news.imgMdeia = media;
                        }
                        else {
                            news.videoMedia = media;
                        }
                        [mediaMutableArr addObject:media];
                    }
                    news.mediaArr = mediaMutableArr;
                    
                    [newsArr addObject:news];
                }
            }
        }
        NSLog(@"%@", newsArr);
        if (completion) {
            completion(newsArr, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (void)videoListForUserWithPagesize:(NSString *)uid perPage:(int)pageSize type:(NSString *)type fromTime:(NSString *)lastTimeStamp completion:(void(^)(NSArray *videoArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/getlistByUser.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&cmd=video&pagesize=10$pagetime=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"getlistByUser.php"];
    NSDictionary *param = @{@"uid": uid, @"cmd": type, @"token": [self token], @"pagesize": [NSNumber numberWithInt:pageSize], @"timestamp": [self timestamp], @"pagetime": lastTimeStamp};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //        NSLog(@"%@", responseObject);
        VNNews *news = nil;
        VNMedia *media = nil;
        NSMutableArray *newsArr = [NSMutableArray array];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"result"]isKindOfClass:[NSArray class]]) {
                for (NSDictionary *newsDic in [responseObject objectForKey:@"result"]) {
                    news = [[VNNews alloc] initWithDict:newsDic];
                    
                    NSDictionary *userDic = [newsDic objectForKey:@"author"];
                    news.author = [[VNUser alloc] initWithDict:userDic];
                    
                    NSArray *mediaArr = [newsDic objectForKey:@"media"];
                    NSMutableArray *mediaMutableArr = [NSMutableArray array];
                    for (NSDictionary *mediaDic in mediaArr) {
                        media = [[VNMedia alloc] initWithDict:mediaDic];
                        if ([media.type rangeOfString:@"image"].location != NSNotFound) {
                            news.imgMdeia = media;
                        }
                        else {
                            news.videoMedia = media;
                        }
                        [mediaMutableArr addObject:media];
                    }
                    news.mediaArr = mediaMutableArr;
                    
                    [newsArr addObject:news];
                }
            }
        }
        NSLog(@"%@", newsArr);
        if (completion) {
            completion(newsArr, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (void)favVideoListForUser:(NSString *)uid userToken:(NSString *)user_token fromTime:(NSString *)lastTimeStamp completion:(void(^)(NSArray *videoArr, NSString * moreTimestamp,NSError *error))completion {
    NSString *URLStr = [VNHost stringByAppendingString:@"getlistByUser.php"];
    NSDictionary *param = @{@"uid": uid, @"user_token": user_token, @"cmd": @"likes", @"token": [self token], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp": [self timestamp], @"pagetime": lastTimeStamp};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        VNNews *news = nil;
        VNMedia *media = nil;
        NSMutableArray *newsArr = [NSMutableArray array];
        NSString *moreTimestamp=nil;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"result"]isKindOfClass:[NSDictionary class]]) {
                moreTimestamp=responseObject[@"result"][@"lastTimestamp"];
                for (NSDictionary *newsDic in responseObject[@"result"][@"list"]) {
                    news = [[VNNews alloc] initWithDict:newsDic];
                    //FIXME: 待确认，timestamp是否这么获取
                    //[news.basicDict setObject:responseObject[@"result"][@"lastTimestamp"] forKey:@"timestamp"];
                    
                    NSDictionary *userDic = [newsDic objectForKey:@"author"];
                    news.author = [[VNUser alloc] initWithDict:userDic];
                    
                    NSArray *mediaArr = [newsDic objectForKey:@"media"];
                    NSMutableArray *mediaMutableArr = [NSMutableArray array];
                    for (NSDictionary *mediaDic in mediaArr) {
                        media = [[VNMedia alloc] initWithDict:mediaDic];
                        if ([media.type rangeOfString:@"image"].location != NSNotFound) {
                            news.imgMdeia = media;
                        }
                        else {
                            news.videoMedia = media;
                        }
                        [mediaMutableArr addObject:media];
                    }
                    news.mediaArr = mediaMutableArr;
                    
                    [newsArr addObject:news];
                }
            }
        }
        NSLog(@"%@", newsArr);
        if (completion) {
            completion(newsArr,moreTimestamp, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, nil,error);
        }
    }];
}

+ (void)favVideoListForUser:(NSString *)uid userToken:(NSString *)user_token fromTime:(NSString *)lastTimeStamp perPage:(int)pageSize completion:(void(^)(NSArray *videoArr, NSString * moreTimestamp,NSError *error))completion {
    NSString *URLStr = [VNHost stringByAppendingString:@"getlistByUser.php"];
    NSDictionary *param = @{@"uid": uid, @"user_token": user_token, @"cmd": @"likes", @"token": [self token], @"pagesize": [NSNumber numberWithInt:pageSize], @"timestamp": [self timestamp], @"pagetime": lastTimeStamp};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        VNNews *news = nil;
        VNMedia *media = nil;
        NSMutableArray *newsArr = [NSMutableArray array];
        NSString *moreTimestamp=nil;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"result"]isKindOfClass:[NSDictionary class]]) {
                moreTimestamp=responseObject[@"result"][@"lastTimestamp"];
                for (NSDictionary *newsDic in responseObject[@"result"][@"list"]) {
                    news = [[VNNews alloc] initWithDict:newsDic];
                    //FIXME: 待确认，timestamp是否这么获取
                    //[news.basicDict setObject:responseObject[@"result"][@"lastTimestamp"] forKey:@"timestamp"];
                    
                    NSDictionary *userDic = [newsDic objectForKey:@"author"];
                    news.author = [[VNUser alloc] initWithDict:userDic];
                    
                    NSArray *mediaArr = [newsDic objectForKey:@"media"];
                    NSMutableArray *mediaMutableArr = [NSMutableArray array];
                    for (NSDictionary *mediaDic in mediaArr) {
                        media = [[VNMedia alloc] initWithDict:mediaDic];
                        if ([media.type rangeOfString:@"image"].location != NSNotFound) {
                            news.imgMdeia = media;
                        }
                        else {
                            news.videoMedia = media;
                        }
                        [mediaMutableArr addObject:media];
                    }
                    news.mediaArr = mediaMutableArr;
                    
                    [newsArr addObject:news];
                }
            }
        }
        NSLog(@"%@", newsArr);
        if (completion) {
            completion(newsArr,moreTimestamp, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, nil,error);
        }
    }];
}

+ (void)userInfoForUser:(NSString *)uid completion:(void(^)(VNUser *userInfo, NSError *error))completion {
    //http://zmysp.sinaapp.com/userInfo.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001
    NSString *URLStr = [VNHost stringByAppendingString:@"userInfo.php"];
    NSDictionary *param = @{@"uid": uid, @"token": [self token], @"timestamp": [self timestamp]};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
         NSLog(@"%@", responseObject);
        VNUser *userInfo = nil;
        
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"userInfo"]isKindOfClass:[NSDictionary class]]) {
                NSDictionary *userInfoDict = [responseObject objectForKey:@"userInfo"];
                userInfo = [[VNUser alloc] initWithDict:userInfoDict];
                userInfo.isMineIdol=NO;
            }
        }

        if (completion) {
            completion(userInfo, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (void)userListForUser:(NSString *)uid type:(NSString *)type pageTime:(NSString *)pageTime completion:(void(^)(NSArray *userArr, NSString *lastTimeStamp, NSError *error))completion {
    //http://zmysp.sinaapp.com/getlistByUser.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&cmd=idols&pagesize=10$pagetime=1404232200
    //http://zmysp.sinaapp.com/getlistByUser.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&cmd=fans&pagesize=10$pagetime=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"getlistByUser.php"];
    NSDictionary *param = @{@"uid": uid, @"token": [self token], @"timestamp": [self timestamp], @"cmd": type, @"pagesize": [NSNumber numberWithInt:pagesize], @"pagetime": pageTime};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        NSMutableArray *userArr = [NSMutableArray array];
        VNUser *user = nil;
        NSString *lastTimeStamp = nil;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [responseObject[@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"result"]isKindOfClass:[NSDictionary class]]) {
                NSArray *resultArr = responseObject[@"result"][@"list"];
                lastTimeStamp = responseObject[@"result"][@"lastTimestamp"];
                if (resultArr.count) {
                    for (NSDictionary *dict in resultArr) {
                        user = [[VNUser alloc] initWithDict:dict];
                        user.isMineIdol=NO;
                        [userArr addObject:user];
                    }
                }
            }
        }
        if (completion) {
            completion(userArr, lastTimeStamp, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, nil, error);
        }
    }];
}

+ (void)userListForUser:(NSString *)uid type:(NSString *)type pageTime:(NSString *)pageTime perPage:(int)pageSize completion:(void(^)(NSArray *userArr, NSString *lastTimeStamp, NSError *error))completion {
    //http://zmysp.sinaapp.com/getlistByUser.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&cmd=idols&pagesize=10$pagetime=1404232200
    //http://zmysp.sinaapp.com/getlistByUser.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&cmd=fans&pagesize=10$pagetime=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"getlistByUser.php"];
    NSDictionary *param = @{@"uid": uid, @"token": [self token], @"timestamp": [self timestamp], @"cmd": type, @"pagesize": [NSNumber numberWithInt:pageSize], @"pagetime": pageTime};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        NSMutableArray *userArr = [NSMutableArray array];
        VNUser *user = nil;
        NSString *lastTimeStamp = nil;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [responseObject[@"status"] boolValue];
            if (responseStatus&&[[responseObject objectForKey:@"result"]isKindOfClass:[NSDictionary class]]) {
                NSArray *resultArr = responseObject[@"result"][@"list"];
                lastTimeStamp = responseObject[@"result"][@"lastTimestamp"];
                if (resultArr.count) {
                    for (NSDictionary *dict in resultArr) {
                        user = [[VNUser alloc] initWithDict:dict];
                        user.isMineIdol=NO;
                        [userArr addObject:user];
                    }
                }
            }
        }
        if (completion) {
            completion(userArr, lastTimeStamp, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, nil, error);
        }
    }];
}


+ (void)updateUserInfo:(NSDictionary *)userInfo completion:(void(^)(BOOL succeed, NSError *error))completion {
    //http://182.92.103.134:8080/engine/uploadUserInfo.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&user_token=f1517c15fd0da75cc1889e9537392a9c&name=alen&location=beijing&sex=female&description=xxxxxx&constellation=baiyang&birthday=123434352345
    NSString *uid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    NSString *paramStr = [NSString stringWithFormat:@"uploadUserInfo.php?timestamp=%@&token=%@&uid=%@&user_token=%@&name=%@&location=%@&sex=%@&description=%@&constellation=%@&birthday=%@", [self timestamp], [self token], uid, user_token, userInfo[@"name"], userInfo[@"location"], userInfo[@"sex"], userInfo[@"description"], userInfo[@"constellation"], userInfo[@"birthday"]];
    NSString *URLStr = [[VNHost stringByAppendingString:paramStr] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        BOOL updateSuccess = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                updateSuccess = [[responseObject objectForKey:@"success"] boolValue];
            }
        }
        if (completion) {
            completion(updateSuccess, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
    
}

+(void)thumbnailURLForUser:(NSString *)uid completion:(void(^)(BOOL succeed,NSString *thumbnailURL,NSError *error))completion
{
    NSString *URLStr = [VNHost stringByAppendingString:@"userThumbnail.php"];
    NSDictionary *param = @{@"uid": uid, @"token": [self token], @"timestamp": [self timestamp]};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        NSString *thumbnailURL=@"";
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                thumbnailURL = [responseObject objectForKey:@"thumbnailURL"];
            }
        }
        if (completion) {
            completion(YES,thumbnailURL, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO,@"", error);
        }
    }];
}

#pragma mark - Login

+ (void)loginWithUser:(VNAuthUser *)user completion:(void(^)(BOOL succeed, NSError *error))completion {
    //http://zmysp.sinaapp.com/login.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&name=abigapple&sex=male&device=d239132434c76fb47f0d185332fb1052ac640b07d8267a3c6e8f5f3e4311592
    NSString *URLStr = [VNHost stringByAppendingString:@"login.php"];
    NSString *pushToken = [[NSUserDefaults standardUserDefaults] objectForKey:VNPushToken];
    NSDictionary *param = @{@"token": [self token], @"timestamp": [self timestamp], @"uid": user.openid, @"name": user.nickname, @"sex": user.gender, @"avatar": user.avatar, @"device": pushToken ? pushToken : @""};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        BOOL successLogin = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                NSString *userToken = [responseObject objectForKey:@"user_token"];
                if (userToken) {
                    [[NSUserDefaults standardUserDefaults] setObject:userToken forKey:VNUserToken];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
                successLogin = [[responseObject objectForKey:@"success"] boolValue];
                if (successLogin) {
                    [[NSUserDefaults standardUserDefaults] setObject:user.basicDict forKey:VNLoginUser];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
        }
        if (completion) {
            completion(successLogin, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
}

+ (void)loginWithEmail:(NSString *)email passwd:(NSString *)passwd completion:(void (^)(BOOL succeed, NSError *error))completion
{
    NSString *URLStr = [VNHost stringByAppendingString:@"oursLogin.php"];
    NSString *pushToken = [[NSUserDefaults standardUserDefaults] objectForKey:VNPushToken];
    NSDictionary *param = @{@"token": [self token], @"timestamp": [self timestamp], @"email": email, @"passwd": passwd, @"device": pushToken ? pushToken : @""};

    [[AFHTTPRequestOperationManager manager] POST:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        BOOL successLogin = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                successLogin = ([[responseObject objectForKey:@"success"] integerValue] == 1)? YES:NO;
                if (successLogin) {
                    NSString *userToken = [responseObject objectForKey:@"user_token"];
                    [[NSUserDefaults standardUserDefaults] setObject:userToken forKey:VNUserToken];
                    
                    VNAuthUser *authUser = [[VNAuthUser alloc] initWithDict:@{}];
                    authUser.openid = [responseObject objectForKey:@"uid"];
                    authUser.nickname = [responseObject objectForKey:@"name"];
                    if ([responseObject objectForKey:@"avatar"] == [NSNull null]) {
                        authUser.avatar = @"";
                    }else {
                        authUser.avatar = [responseObject objectForKey:@"avatar"];
                    }
                    if ([responseObject objectForKey:@"sex"] == [NSNull null]) {
                        authUser.gender = @"";
                    }else if ([[responseObject objectForKey:@"sex"] intValue] == 1) {
                        authUser.gender = @"male";
                    }
                    else if([[responseObject objectForKey:@"sex"] intValue] == 0) {
                        authUser.gender = @"female";
                    }else {
                        authUser.gender = @"male";
                    }
                    
                    [[NSUserDefaults standardUserDefaults] setObject:authUser.basicDict forKey:VNLoginUser];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
        }
        if (completion) {
            NSError *err;
            if ([[responseObject objectForKey:@"success"] integerValue] == 0){
                //not registered user
                err = [NSError errorWithDomain:VNCustomErrorDomain code:VNInvalidUserErrorCode userInfo:nil];
            }
            if ([[responseObject objectForKey:@"success"] integerValue] == 2){
                //wrong password
                err = [NSError errorWithDomain:VNCustomErrorDomain code:VNWrongPasswdErrorCode userInfo:nil];
            }
            completion(successLogin, err);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
}

+ (void)registerWithNickname:(NSString *)nickname Email:(NSString *)email passwd:(NSString *)passwd completion:(void (^)(BOOL succeed, NSError *error))completion
{
    //http://182.92.103.134:8080/engine/register.php?name=111&passwd=111&mail=695551328%40qq.com&timestamp=XXXX&token=XXXX
    NSString *URLStr = [VNHost stringByAppendingString:@"register.php"];
    NSString *pushToken = [[NSUserDefaults standardUserDefaults] objectForKey:VNPushToken];
    NSDictionary *param = @{@"name":nickname,@"token": [self token], @"timestamp": [self timestamp], @"mail": email, @"passwd": passwd, @"device": pushToken ? pushToken : @""};

    [[AFHTTPRequestOperationManager manager] POST:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        BOOL successLogin = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                successLogin = ([[responseObject objectForKey:@"success"] integerValue] == 1)? YES:NO;
                if (successLogin) {
                    
                }
            }
        }
        NSError *err;
        if ([[responseObject objectForKey:@"success"] integerValue] == 0){
            //register failed
            err = [NSError errorWithDomain:VNCustomErrorDomain code:VNRegisterFailed userInfo:nil];
        }
        
        if (completion) {
            completion(successLogin, err);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
}

+ (void)resetPasswdWithEmail:(NSString *)email completion:(void (^)(BOOL, NSError *))completion
{
    NSString *URLStr = [VNHost stringByAppendingString:@"changePasswd.php"];
    NSDictionary *param = @{@"email": email, @"token": [self token], @"timestamp": [self timestamp]};
    [[AFHTTPRequestOperationManager manager] POST:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        BOOL successLogin = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                successLogin = ([[responseObject objectForKey:@"success"] integerValue] == 1)? YES:NO;
                if (successLogin) {
                    
                }
            }
        }
        NSError *err;
        if ([[responseObject objectForKey:@"success"] integerValue] == 0){
            //register failed
            err = [NSError errorWithDomain:VNCustomErrorDomain code:VNResetPasswdFailed userInfo:nil];
        }
        
        if (completion) {
            completion(successLogin, err);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
}

#pragma mark - SEL

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

+ (NSString *)token {
   // NSString *originTokenStr = [[NSString stringFromDate:[NSDate date]] stringByAppendingString:@"#$@%!*zmy"];
    //NSLog(@"%@", originTokenStr);
    NSString *originTokenStr = [[self timestamp] stringByAppendingString:@"#$@%!*zmy"];
    return [originTokenStr md5];
}

+ (NSString *)tokenFromTimestamp:(NSString *)timestamp {
    NSDate *destDate = [NSDate dateWithTimeIntervalSince1970:[timestamp doubleValue]];
    NSString *originTokenStr = [[NSString stringFromDate:destDate] stringByAppendingString:@"#$@%!*zmy"];
    NSLog(@"%@", originTokenStr);
    return [originTokenStr md5];
}

+ (NSDate *)CCT_Date {
    NSDate* sourceDate = [NSDate date];
    NSTimeZone* sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"CCT"];
    NSTimeZone* destinationTimeZone = [NSTimeZone systemTimeZone];
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    NSDate* destinationDate = [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
    return destinationDate;
}

#pragma mark - Network Reachability

+ (BOOL)isReachable;
{
    if (!reach) {
        reach = [Reachability reachabilityWithHostname:@"www.shishangpai.com.cn"];
    }
    return reach.isReachable;
}

+ (BOOL)isReachableViaWiFi {
    if (!reach) {
        reach = [Reachability reachabilityWithHostname:@"www.shishangpai.com.cn"];
    }
    return reach.isReachableViaWiFi;
}

@end
