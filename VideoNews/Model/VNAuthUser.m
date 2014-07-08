//
//  VNAuthUser.m
//  VideoNews
//
//  Created by liuyi on 14-7-8.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNAuthUser.h"

static NSString *kOpenid = @"openid";
static NSString *kNickname = @"nickname";
static NSString *kAvatar = @"avatar";
static NSString *kGender = @"gender";

@implementation VNAuthUser

- (NSString *)openid {
    return makeSureNotNull([self.basicDict objectForKey:kOpenid]);
}

- (void)setOpenid:(NSString *)openid {
    [self.basicDict setObject:openid forKey:kOpenid];
}

- (NSString *)nickname {
    return makeSureNotNull([self.basicDict objectForKey:kNickname]);
}

- (void)setNickname:(NSString *)nickname {
    [self.basicDict setObject:nickname forKey:kNickname];
}

- (NSString *)avatar {
    return makeSureNotNull([self.basicDict objectForKey:kAvatar]);
}

- (void)setAvatar:(NSString *)avatar {
    [self.basicDict setObject:avatar forKey:kAvatar];
}

- (NSString *)gender {
    return makeSureNotNull([self.basicDict objectForKey:kGender]);
}

- (void)setGender:(NSString *)gender {
    [self.basicDict setObject:gender forKey:kGender];
}

@end
