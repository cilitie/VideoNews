//
//  VNObject.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNObject.h"

static NSString *kBasicDict = @"BasicDict";

@interface VNObject () <NSCoding, NSCopying>

@end

@implementation VNObject

- (instancetype)initWithDict:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        _basicDict = [[NSMutableDictionary alloc] initWithDictionary:[dict copy]];
    }
    return self;
}

#pragma mark - NSCoding, NSCopying

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super init])
    {
        _basicDict = [coder decodeObjectForKey:kBasicDict];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_basicDict forKey:kBasicDict];
}

- (id)copyWithZone:(NSZone *)zone
{
    VNObject *copy = [[[self class] allocWithZone:zone] init];
    copy.basicDict = [self.basicDict copyWithZone:zone];
    return copy;
}

@end
