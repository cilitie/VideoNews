//
//  VNObject.h
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <Foundation/Foundation.h>

static inline id makeSureNotNull(id original) {
    return [original isKindOfClass:[NSNull class]] ? nil : original;
}

@interface VNObject : NSObject

@property (strong, nonatomic) NSMutableDictionary *basicDict;

- (instancetype)initWithDict:(NSDictionary *)dict;

@end
