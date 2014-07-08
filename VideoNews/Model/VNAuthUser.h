//
//  VNAuthUser.h
//  VideoNews
//
//  Created by liuyi on 14-7-8.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNObject.h"

@interface VNAuthUser : VNObject

@property (strong, nonatomic) NSString *openid;
@property (strong, nonatomic) NSString *nickname;
@property (strong, nonatomic) NSString *avatar;
@property (strong, nonatomic) NSString *gender;

@end
