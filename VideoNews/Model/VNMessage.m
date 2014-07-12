//
//  VNMessage.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-10.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNMessage.h"

static NSString *kCid = @"pid";
static NSString *kType = @"type";
static NSString *kNews = @"news";
static NSString *kSender = @"sender";
static NSString *KTime=@"time";
static NSString *KText=@"text";
static NSString *KReplyText=@"reply_text";


@implementation VNMessage

- (VNUser *)sender {
    return makeSureNotNull([self.basicDict objectForKey:kSender]);
}

- (void)setSender:(VNUser *)sender{
    [self.basicDict setObject:sender forKey:kSender];
}

- (VNUser *)news {
    return makeSureNotNull([self.basicDict objectForKey:kNews]);
}

- (void)setNews:(VNNews *)news{
    [self.basicDict setObject:news forKey:kNews];
}

- (int)pid {
    return [makeSureNotNull([self.basicDict objectForKey:kCid]) intValue];
}

- (NSString *)type {
    return makeSureNotNull([self.basicDict objectForKey:kType]);
}

- (NSString *)time {
    return makeSureNotNull([self.basicDict objectForKey:KTime]);
}

- (NSString *)text {
    return makeSureNotNull([self.basicDict objectForKey:KText]);
}

- (NSString *)reply_text {
    return makeSureNotNull([self.basicDict objectForKey:KReplyText]);
}


@end
