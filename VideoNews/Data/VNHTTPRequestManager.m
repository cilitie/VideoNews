//
//  VNHTTPRequestManager.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNHTTPRequestManager.h"
#import "AFNetworking.h"

@implementation VNHTTPRequestManager

+ (void)newsListFromTime:(NSString *)time completion:(void(^)(NSArray *newsArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/viewnews.php?pagesize=10&timestamp=1403749840.499465
    NSString *URLStr = [VNHost stringByAppendingString:@"viewnews.php"];
    NSDictionary *param = @{@"pagesize": @10, @"timestamp": time};
    
    //FIXME: for test
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"HomeNews" ofType:@"json"];
    NSData *jdata = [[NSData alloc] initWithContentsOfFile:path];
    NSError *error = nil;
    NSArray *responseObject = [NSJSONSerialization JSONObjectWithData:jdata options:kNilOptions error:&error];
    VNNews *news = nil;
    VNMedia *media = nil;
    NSMutableArray *newsArr = [NSMutableArray array];
    for (NSDictionary *newsDic in responseObject) {
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
    if (completion) {
        NSLog(@"%@", newsArr);
        completion(newsArr, nil);
        return;
    }
    
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        VNNews *news = nil;
        VNMedia *media = nil;
        NSMutableArray *newsArr = [NSMutableArray array];
        if (responseObject && [responseObject isKindOfClass:[NSArray class]]) {
            for (NSDictionary *newsDic in responseObject) {
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
        if (completion) {
            completion(newsArr, nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (completion) {
            completion(nil, error);
        }
    }];
}

+ (void)categoryList:(void(^)(NSArray *categoryArr, NSError *error))completion {
    //http://zmysp.sinaapp.com/class.php
    NSString *URLStr = [VNHost stringByAppendingString:@"class.php"];
    
    //FIXME: for test
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Category" ofType:@"json"];
    NSData *jdata = [[NSData alloc] initWithContentsOfFile:path];
    NSError *error = nil;
    NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:jdata options:kNilOptions error:&error];
    NSArray *responseArr = [responseObject objectForKey:@"classes"];
    
    VNCategory *category = nil;
    NSMutableArray *categoryArr = [NSMutableArray array];
    for (NSDictionary *categoryDic in responseArr) {
        category = [[VNCategory alloc] initWithDict:categoryDic];
        [categoryArr addObject:category];
     }
    if (completion) {
        completion(categoryArr, nil);
        return;
    }

    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        VNCategory *category = nil;
        NSMutableArray *categoryArr = [NSMutableArray array];
        
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSArray *responseArr = [responseObject objectForKey:@"classes"];
            for (NSDictionary *categoryDic in responseArr) {
                category = [[VNCategory alloc] initWithDict:categoryDic];
                [categoryArr addObject:category];
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

@end
