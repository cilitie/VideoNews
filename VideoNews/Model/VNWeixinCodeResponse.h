//
//  VNWeixinCodeResponse.h
//  VideoNews
//
//  Created by liuyi on 14-7-8.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNObject.h"

@interface VNWeixinCodeResponse : VNObject

@property (strong, nonatomic, readonly) NSString * access_token;
@property (assign, nonatomic, readonly) int expires_in;
@property (strong, nonatomic, readonly) NSString * refresh_token;
@property (strong, nonatomic, readonly) NSString * openid;
@property (strong, nonatomic, readonly) NSString * scope;

@end
