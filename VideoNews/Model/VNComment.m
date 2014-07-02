//
//  VNComment.m
//  VideoNews
//
//  Created by liuyi on 14-7-2.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNComment.h"

static NSString *kCid = @"cid";
static NSString *kContent = @"content";
static NSString *kDate = @"date";
static NSString *kDing = @"ding";
static NSString *kInsert_time = @"insert_time";
static NSString *kAuthor = @"author";

@implementation VNComment

- (int)cid {
    return [makeSureNotNull([self.basicDict objectForKey:kCid]) intValue];
}

- (NSString *)content {
    return makeSureNotNull([self.basicDict objectForKey:kContent]);
}

- (NSString *)date {
    return makeSureNotNull([self.basicDict objectForKey:kDate]);
}

- (int)ding {
    return [makeSureNotNull([self.basicDict objectForKey:kDing]) intValue];
}

- (NSString *)insert_time {
    return makeSureNotNull([self.basicDict objectForKey:kInsert_time]);
}

- (VNUser *)author {
    return makeSureNotNull([self.basicDict objectForKey:kAuthor]);
}

- (void)setAuthor:(VNUser *)author {
    [self.basicDict setObject:author forKey:kAuthor];
}

@end
