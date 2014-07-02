//
//  VNComment.h
//  VideoNews
//
//  Created by liuyi on 14-7-2.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNObject.h"

@interface VNComment : VNObject

@property (assign, nonatomic, readonly) int cid;
@property (strong, nonatomic, readonly) NSString *content;
@property (strong, nonatomic, readonly) NSString *date;
@property (assign, nonatomic, readonly) int ding;
@property (strong, nonatomic, readonly) NSString *insert_time;
@property (strong, nonatomic) VNUser *author;

@end
