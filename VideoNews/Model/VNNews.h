//
//  VNNews.h
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNObject.h"

@class VNUser;
@class VNMedia;

@interface VNNews : VNObject

@property (assign, nonatomic, readonly) int nid;
//@property (assign, nonatomic, readonly) int like_count;
@property (assign, nonatomic, readonly) int comment_count;
@property (strong, nonatomic, readonly) NSString *date;
@property (strong, nonatomic, readonly) NSString *title;
@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *url;
@property (assign, nonatomic, readonly) int share_count;
@property (strong, nonatomic, readonly) NSString *tags;
@property (strong, nonatomic, readonly) NSString *description;
@property (assign, nonatomic) int like_count;
@property (strong, nonatomic) VNUser *author;
@property (strong, nonatomic) NSArray *mediaArr;
@property (strong, nonatomic) VNMedia *imgMdeia;
@property (strong, nonatomic) VNMedia *videoMedia;
@property (strong, nonatomic, readonly) NSString *timestamp;
@property (strong, nonatomic, readonly) NSString *classid;

@end
