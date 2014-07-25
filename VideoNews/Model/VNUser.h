//
//  VNUser.h
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNObject.h"

@interface VNUser : VNObject

@property (assign, nonatomic, readonly) NSString *uid;
@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSString *avatar;
@property (strong, nonatomic, readonly) NSString *fans_count;
@property (strong, nonatomic, readonly) NSString *video_count;
@property (strong, nonatomic, readonly) NSString *like_count;
@property (strong, nonatomic, readonly) NSString *idol_count;
@property (strong, nonatomic, readonly) NSString *timestamp;
@property (strong, nonatomic, readonly) NSString *userDescription;
//for comment author
@property (strong, nonatomic, readonly) NSString *location;
@property (strong, nonatomic, readonly) NSString *sex;
@property (strong, nonatomic, readonly) NSString *main_uid;
//for idol
@property (assign, nonatomic) BOOL isMineIdol;
//for user profile
@property (strong, nonatomic, readonly) NSString *constellation;
@property (strong, nonatomic, readonly) NSString *birthday;

@end
