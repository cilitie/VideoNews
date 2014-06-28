//
//  VNCategory.m
//  VideoNews
//
//  Created by liuyi on 14-6-28.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCategory.h"

static NSString *kCid = @"cid";
static NSString *kName = @"name";
static NSString *kImg_url = @"img_url";

@implementation VNCategory

- (int)cid {
    return [makeSureNotNull([self.basicDict objectForKey:kCid]) intValue];
}

- (NSString *)name {
    return makeSureNotNull([self.basicDict objectForKey:kName]);
}

- (NSString *)img_url {
    return makeSureNotNull([self.basicDict objectForKey:kImg_url]);
}

@end
