//
//  VNMessage.h
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-10.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNObject.h"

@interface VNMessage : VNObject

@property (strong, nonatomic) VNUser *sender;

@property (strong, nonatomic) VNNews *news;

@property (assign, nonatomic,readonly) int pid;

@property (strong,nonatomic,readonly) NSString *type;

@property (strong,nonatomic,readonly) NSString *time;

@end
