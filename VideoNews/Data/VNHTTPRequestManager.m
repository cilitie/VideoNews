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
    [[AFHTTPRequestOperationManager manager] GET:URLStr parameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@", responseObject);
        VNNews *news = nil;
        NSMutableArray *newsArr = [NSMutableArray array];
        if (responseObject && [responseObject isKindOfClass:[NSArray class]]) {
            for (NSDictionary *newsDic in responseObject) {
                news = [[VNNews alloc] initWithDict:newsDic];
                
                NSDictionary *userDic = [newsDic objectForKey:@"author"];
                news.author = [[VNUser alloc] initWithDict:userDic];
                
                NSArray *mediaArr = [newsDic objectForKey:@"media"];
                NSMutableArray *mediaMutableArr = [NSMutableArray array];
                for (NSDictionary *mediaDic in mediaArr) {
                    [mediaMutableArr addObject:[[VNMedia alloc] initWithDict:mediaDic]];
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

@end
