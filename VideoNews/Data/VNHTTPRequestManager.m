//
//  VNHTTPRequestManager.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#pragma mark - NSString Extension
#import <CommonCrypto/CommonDigest.h>

@interface NSString (addition)

- (NSString *)md5;
+ (NSString *)stringFromDate:(NSDate *)date;

@end

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

static int pagesize = 10;

@implementation VNHTTPRequestManager

#pragma mark - Home

+ (void)newsListFromTime:(NSString *)time completion:(void(^)(NSArray *newsArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/viewnews.php?pagesize=10&timestamp=1404197350.213768&token=71cbc84008a7464a5df8b1da2e16aaae
    NSString *URLStr = [VNHost stringByAppendingString:@"viewnews.php"];
//  NSDictionary *param = @{@"token": [self tokenFromTimestamp:time], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp": time};
    NSDictionary *param = @{@"token": [self token], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp": [self timestamp],@"pagetime":time};
    
    //FIXME: for test
    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"HomeNews" ofType:@"json"];
//    NSData *jdata = [[NSData alloc] initWithContentsOfFile:path];
//    NSError *error = nil;
//    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:jdata options:kNilOptions error:&error];
//    VNNews *news = nil;
//    VNMedia *media = nil;
//    NSMutableArray *newsArr = [NSMutableArray array];
//    for (NSDictionary *newsDic in [responseObject objectForKey:@"list"]) {
//        news = [[VNNews alloc] initWithDict:newsDic];
//        
//        NSDictionary *userDic = [newsDic objectForKey:@"author"];
//        news.author = [[VNUser alloc] initWithDict:userDic];
//        
//        NSArray *mediaArr = [newsDic objectForKey:@"media"];
//        NSMutableArray *mediaMutableArr = [NSMutableArray array];
//        for (NSDictionary *mediaDic in mediaArr) {
//            media = [[VNMedia alloc] initWithDict:mediaDic];
//            [mediaMutableArr addObject:media];
//        }
//        news.mediaArr = mediaMutableArr;
//        
//        [newsArr addObject:news];
//    }
//    if (completion) {
//        NSLog(@"%@", newsArr);
//        completion(newsArr, nil);
//        return;
//    }
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", responseObject);
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
        
        if (completion) {
            completion(newsArr, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (void)commentListForNews:(int)nid timestamp:(NSString *)timestamp completion:(void(^)(NSArray *commemtArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/chat.php?nid=1&timestamp=1402826693&token=jshangabsjksjjagnn
    NSString *URLStr = [VNHost stringByAppendingString:@"chat.php"];
//    NSDictionary *param = @{@"nid": [NSNumber numberWithInt:nid], @"pagesize": [NSNumber numberWithInt:pagesize], @"token": [self tokenFromTimestamp:timestamp], @"timestamp": timestamp};
    NSDictionary *param = @{@"nid": [NSNumber numberWithInt:nid], @"pagesize": [NSNumber numberWithInt:pagesize], @"token": [self token], @"timestamp": [self timestamp],@"pagetime":timestamp};
    
    //FIXME: test
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", responseObject);
        VNComment *comment = nil;
        NSMutableArray *commentArr = [NSMutableArray array];
        
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            //FIXME: Server Error, Fix Later
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
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
            completion(commentArr, nil);
            return;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (void)favouriteNews:(int)nid operation:(NSString *)operation userID:(NSString *)uid user_token:(NSString *)user_token completion:(void(^)(BOOL succeed, NSError *error))completion {
    //http://zmysp.sinaapp.com/op.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&cmd=add&id=1&user_token=f1517c15fd0da75cc1889e9537392a9c
    NSString *URLStr = [VNHost stringByAppendingString:@"op.php"];
    NSDictionary *param = @{@"id": [NSNumber numberWithInt:nid], @"uid": uid, @"cmd": operation, @"user_token": user_token, @"token": [self token], @"timestamp": [self timestamp]};
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", responseObject);
        BOOL operationSuccess = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                operationSuccess = [[responseObject objectForKey:@"success"] boolValue];
            }
        }
        if (completion) {
            completion(operationSuccess, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
}

+ (void)commentNews:(int)nid content:(NSString *)content completion:(void(^)(BOOL succeed, NSError *error))completion {
    //http://zmysp.sinaapp.com/comment.php?uid=1&text=thisisatest&token=f961f003dd383bc39eb53c5b7e5fd046&nid=1&type=pub&timestamp=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"comment.php"];
    NSString *uid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    if (!uid) {
        uid = @"1";
    }
    NSDictionary *param = @{@"uid": uid, @"nid": [NSString stringWithFormat:@"%d", nid], @"text": content, @"type": @"pub", @"token": [self token], @"timestamp": [self timestamp]};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", responseObject);
        BOOL commentSuccess = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                commentSuccess = [[responseObject objectForKey:@"success"] boolValue];
            }
        }
        if (completion) {
            completion(commentSuccess, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
}

+ (void)replyComment:(int)cid replyUser:(NSString *)reply_uid replyNews:(int)nid content:(NSString *)content completion:(void(^)(BOOL succeed, NSError *error))completion {
    //http://zmysp.sinaapp.com/comment.php?uid=1&text=thisisatest&token=f961f003dd383bc39eb53c5b7e5fd046&nid=1&type=pub&timestamp=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"comment.php"];
    NSString *uid = nil;
    NSString *user_token = nil;
    uid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    if (!uid) {
        uid = @"1";
        user_token = @"";
    }
    
    NSDictionary *param = @{@"uid": uid, @"nid": [NSString stringWithFormat:@"%d", nid], @"pid": [NSString stringWithFormat:@"%d", cid], @"reply_uid": reply_uid, @"text": content, @"type": @"reply", @"token": [self token], @"timestamp": [self timestamp], @"user_token": user_token};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", responseObject);
        BOOL replySuccess = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                replySuccess = [[responseObject objectForKey:@"success"] boolValue];
            }
        }
        if (completion) {
            completion(replySuccess, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
}

+ (void)deleteComment:(int)cid news:(int)nid userID:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(BOOL succeed, NSError *error))completion {
    //http://zmysp.sinaapp.com/comment.php?uid=1&text=thisisatest&token=f961f003dd383bc39eb53c5b7e5fd046&nid=1&type=pub&timestamp=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"comment.php"];
    NSDictionary *param = @{@"uid": uid, @"nid": [NSString stringWithFormat:@"%d", nid], @"pid": [NSString stringWithFormat:@"%d", cid], @"type": @"del", @"token": [self token], @"timestamp": [self timestamp], @"user_token": user_token};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", responseObject);
        BOOL deleteSuccess = NO;
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                deleteSuccess = [[responseObject objectForKey:@"success"] boolValue];
            }
        }
        if (completion) {
            completion(deleteSuccess, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(NO, error);
        }
    }];
}

//举报相关
+ (void)report:(NSString *)objectID type:(NSString *)type userID:(NSString *)uid userToken:(NSString *)user_token completion:(void(^)(BOOL succeed, NSError *error))completion {
    //http://zmysp.sinaapp.com/report.php?id=1&timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1287669920034&user_token=8d81463b854466d4d2e2ba9d4d54428c&type=reportNews
    NSString *URLStr = [VNHost stringByAppendingString:@"report.php"];
    NSDictionary *param = @{@"uid": uid, @"id": objectID, @"type": type, @"token": [self token], @"timestamp": [self timestamp], @"user_token": user_token};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
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

#pragma mark - Search

+ (void)categoryList:(void(^)(NSArray *categoryArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/class.php?timestamp=1402826693&token=9183773661255
    NSString *URLStr = [VNHost stringByAppendingString:@"class.php"];
    //FIXME: 接口有错误
    NSDictionary *param = @{@"token": [self token], @"timestamp": [self timestamp]};
    //FIXME: for test
    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"Category" ofType:@"json"];
//    NSData *jdata = [[NSData alloc] initWithContentsOfFile:path];
//    NSError *error = nil;
//    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:jdata options:kNilOptions error:&error];
//    NSArray *responseArr = [responseObject objectForKey:@"classes"];
//    
//    VNCategory *category = nil;
//    NSMutableArray *categoryArr = [NSMutableArray array];
//    for (NSDictionary *categoryDic in responseArr) {
//        category = [[VNCategory alloc] initWithDict:categoryDic];
//        [categoryArr addObject:category];
//    }
//    if (completion) {
//        completion(categoryArr, nil);
//        return;
//    }
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        VNCategory *category = nil;
        NSMutableArray *categoryArr = [NSMutableArray array];
        
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                NSArray *responseArr = responseObject[@"list"][@"classes"];
                //            NSLog(@"%@", responseArr);
                for (NSDictionary *categoryDic in responseArr) {
                    category = [[VNCategory alloc] initWithDict:categoryDic];
                    [categoryArr addObject:category];
                }
            }
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

+ (void)categoryNewsFromTime:(NSString *)time category:(int)cid completion:(void(^)(NSArray *categoryNewsArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/viewnews.php?timestamp=1402826693&pagesize=2&cid=1&token=9183773661255
    NSString *URLStr = [VNHost stringByAppendingString:@"viewnews.php"];
//    NSDictionary *param = @{@"token": [self tokenFromTimestamp:time], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp": time, @"cid": [NSNumber numberWithInt:cid]};
    NSDictionary *param = @{@"token": [self token], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp": [self timestamp], @"pagetime": time, @"cid": [NSNumber numberWithInt:cid]};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", responseObject);
        VNNews *news = nil;
        VNMedia *media = nil;
        NSMutableArray *newsArr = [NSMutableArray array];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
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
        
        if (completion) {
            completion(newsArr, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (void)searchResultForKey:(NSString *)keyWord timestamp:(NSString *)timestamp searchType:(NSString *)searchType completion:(void(^)(NSArray *resultNewsArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/so.php?key=lucy&token=f961f003dd383bc39eb53c5b7e5fd046&timestamp=1404232200&category=news
    NSString *URLStr = [VNHost stringByAppendingString:@"so.php"];
//    NSDictionary *param = @{@"token": [self tokenFromTimestamp:timestamp], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp": timestamp, @"key": keyWord, @"category": searchType};
    NSString *TimeStamp = [VNHTTPRequestManager timestamp];
    NSDictionary *param = @{@"token": [self token], @"pagesize": [NSNumber numberWithInt:pagesize], @"timestamp":TimeStamp,@"pagetime": timestamp, @"key": keyWord, @"category": searchType};
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        NSLog(@"%@", responseObject);
        VNNews *news = nil;
        VNMedia *media = nil;
        NSMutableArray *newsArr = [NSMutableArray array];
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
                for (NSDictionary *newsDic in responseObject[@"list"][@"search"]) {
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
        
        if (completion) {
            completion(newsArr, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}
#pragma mark - Notification
+ (void)messageListForUser:(NSString *)uid timestamp:(NSString *)timestamp completion:(void(^)(NSArray *commemtArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/message.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&user_token=f1517c15fd0da75cc1889e9537392a9c&pagesize=10&pagetime=1404232200
    NSString *URLStr = [VNHost stringByAppendingString:@"chat.php"];
    //    NSDictionary *param = @{@"nid": [NSNumber numberWithInt:nid], @"pagesize": [NSNumber numberWithInt:pagesize], @"token": [self tokenFromTimestamp:timestamp], @"timestamp": timestamp};
    NSDictionary *param = @{@"nid": uid, @"pagesize": [NSNumber numberWithInt:pagesize], @"token": [self token], @"timestamp": [self timestamp],@"pagetime":timestamp};
    
    //FIXME: test
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        //        NSLog(@"%@", responseObject);
        VNComment *comment = nil;
        NSMutableArray *commentArr = [NSMutableArray array];
        
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            //FIXME: Server Error, Fix Later
            BOOL responseStatus = [[responseObject objectForKey:@"status"] boolValue];
            if (responseStatus) {
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
            completion(commentArr, nil);
            return;
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

#pragma mark - Login

+ (void)loginWithUser:(VNAuthUser *)user completion:(void(^)(BOOL succeed, NSError *error))completion {
    //http://zmysp.sinaapp.com/login.php?timestamp=1404232200&token=f961f003dd383bc39eb53c5b7e5fd046&uid=1300000001&name=abigapple&sex=male&device=d239132434c76fb47f0d185332fb1052ac640b07d8267a3c6e8f5f3e4311592
    NSString *URLStr = [VNHost stringByAppendingString:@"login.php"];
    NSString *pushToken = [[NSUserDefaults standardUserDefaults] objectForKey:VNPushToken];
    NSDictionary *param = @{@"token": [self token], @"timestamp": [self timestamp], @"uid": user.openid, @"name": user.nickname, @"device": pushToken ? pushToken : @""};
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

#pragma mark - SEL

+ (NSString *)timestamp {
//    NSLog(@"%@", [[self CCT_Date] description]);
//    return [NSString stringWithFormat:@"%f", [[self CCT_Date] timeIntervalSince1970]];
    //http://zmysp.sinaapp.com/timestamp.php
    NSString *URLStr = [VNHost stringByAppendingString:@"timestamp.php"];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:URLStr]];
    [request setHTTPMethod:@"GET"];
    NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
    NSError *error = nil;
    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:returnData options:kNilOptions error:&error];
    return [NSString stringWithFormat:@"%d", [[responseObject objectForKey:@"timestamp"] intValue]];
}

+ (NSString *)token {
    NSString *originTokenStr = [[NSString stringFromDate:[NSDate date]] stringByAppendingString:@"#$@%!*zmy"];
    NSLog(@"%@", originTokenStr);
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

@end
