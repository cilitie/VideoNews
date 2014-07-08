//
//  VNWeixinCodeResponse.m
//  VideoNews
//
//  Created by liuyi on 14-7-8.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNWeixinCodeResponse.h"

static NSString *kAccess_token = @"access_token";
static NSString *kExpires_in = @"expires_in";
static NSString *kRefresh_token = @"refresh_token";
static NSString *kOpenid = @"openid";
static NSString *kScope = @"scope";

@implementation VNWeixinCodeResponse

- (NSString *)access_token {
    return makeSureNotNull([self.basicDict objectForKey:kAccess_token]);
}

- (int)expires_in {
    return [makeSureNotNull([self.basicDict objectForKey:kExpires_in]) intValue];
}

- (NSString *)refresh_token {
    return makeSureNotNull([self.basicDict objectForKey:kRefresh_token]);
}

- (NSString *)openid {
    return makeSureNotNull([self.basicDict objectForKey:kOpenid]);
}

- (NSString *)scope {
    return makeSureNotNull([self.basicDict objectForKey:kScope]);
}

@end
