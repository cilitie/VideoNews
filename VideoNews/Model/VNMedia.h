//
//  VNMedia.h
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNObject.h"

@interface VNMedia : VNObject

@property (assign, nonatomic, readonly) int mid;
@property (strong, nonatomic, readonly) NSString *type;
@property (strong, nonatomic, readonly) NSString *url;
@property (assign, nonatomic, readonly) int height;
@property (assign, nonatomic, readonly) int width;
@property (strong, nonatomic, readonly) NSString *description;

@end
