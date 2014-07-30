//
//  VNMedia.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNMedia.h"

static NSString *kMid = @"mid";
static NSString *kType = @"type";
static NSString *kURL = @"url";
static NSString *kHeight = @"height";
static NSString *kWidth = @"width";
static NSString *kDescription = @"description";
static NSString *KUid=@"uid";

@implementation VNMedia

- (int)mid {
    return [makeSureNotNull([self.basicDict objectForKey:kMid]) intValue];
}

- (NSString *)type {
    return makeSureNotNull([self.basicDict objectForKey:kType]);
}

- (NSString *)url {
    return makeSureNotNull([self.basicDict objectForKey:kURL]);
}

- (int)height {
    return [makeSureNotNull([self.basicDict objectForKey:kHeight]) intValue];
}

- (int)width {
    return [makeSureNotNull([self.basicDict objectForKey:kWidth]) intValue];
}

- (NSString *)description {
    return makeSureNotNull([self.basicDict objectForKey:kDescription]);
}

- (NSString *)uid {
    return makeSureNotNull([self.basicDict objectForKey:KUid]);
}

@end
