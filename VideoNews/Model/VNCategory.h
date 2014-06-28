//
//  VNCategory.h
//  VideoNews
//
//  Created by liuyi on 14-6-28.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNObject.h"

@interface VNCategory : VNObject

@property (assign, nonatomic, readonly) int cid;
@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *img_url;

@end
