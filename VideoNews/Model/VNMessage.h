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

@property (strong, nonatomic,readonly) NSString * text;

@property (strong, nonatomic,readonly) NSString * reply_text;

@property (strong,nonatomic,readonly) NSString *type;

@property (strong,nonatomic,readonly) NSString *time;

@property (assign,nonatomic,readonly)int reply_pid;

@property (assign,nonatomic,readonly)int mid;

@end
