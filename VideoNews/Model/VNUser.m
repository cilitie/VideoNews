//
//  VNUser.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNUser.h"

static NSString *kUid = @"uid";
static NSString *kName = @"name";
static NSString *kAvatar = @"avatar";
static NSString *kFans_count = @"fans_count";
static NSString *kTimestamp = @"timestamp";

static NSString *kLocation = @"location";
static NSString *kSex = @"sex";
static NSString *kMain_uid = @"main_uid";

@implementation VNUser

- (NSString *)uid {
    //return [makeSureNotNull([self.basicDict objectForKey:kUid]) intValue];
    return makeSureNotNull([self.basicDict objectForKey:kUid]);
}

- (NSString *)name {
    return makeSureNotNull([self.basicDict objectForKey:kName]);
}

- (NSString *)avatar {
    return makeSureNotNull([self.basicDict objectForKey:kAvatar]);
}

- (NSString *)fans_count {
    return makeSureNotNull([self.basicDict objectForKey:kFans_count]);
}

- (NSString *)timestamp {
    return makeSureNotNull([self.basicDict objectForKey:kTimestamp]);
}

- (NSString *)location {
    return makeSureNotNull([self.basicDict objectForKey:kLocation]);
}

- (NSString *)sex {
    return makeSureNotNull([self.basicDict objectForKey:kSex]);
}

- (NSString *)main_uid {
    return makeSureNotNull([self.basicDict objectForKey:kMain_uid]);
}

@end
