//
//  VNUser.h
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNObject.h"

@interface VNUser : VNObject

@property (assign, nonatomic, readonly) int uid;
@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *avatar;
@property (assign, nonatomic, readonly) BOOL isMainUser;
@property (assign, nonatomic, readonly) BOOL isSearch;
@property (strong, nonatomic, readonly) NSArray *collectNewsArr;
@property (strong, nonatomic, readonly) NSArray *commentArr;
@property (strong, nonatomic, readonly) NSArray *newsArr;
@property (strong, nonatomic, readonly) NSArray *replyCommentArr;

@end
