//
//  VNUser.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNUser.h"

static NSString *kUid = @"uid";
static NSString *kName = @"name";
static NSString *kAvatar = @"avatar";
static NSString *kFans_count = @"fans_count";
static NSString *kVideo_count = @"video_count";
static NSString *kLike_count = @"like_count";
static NSString *kIdol_count = @"idol_count";
static NSString *kUserDescription = @"description";
static NSString *kTimestamp = @"timestamp";

static NSString *kLocation = @"location";
static NSString *kSex = @"sex";
static NSString *kMain_uid = @"main_uid";

static NSString *kIsMineIdol = @"isMineIdol";

static NSString *kConstellation = @"constellation";
static NSString *kBirthday = @"birthday";

@implementation VNUser

- (NSString *)uid {
    //return [makeSureNotNull([self.basicDict objectForKey:kUid]) intValue];
    return makeSureNotNull([self.basicDict objectForKey:kUid]);
}

- (NSString *)name {
    return makeSureNotNull([self.basicDict objectForKey:kName]);
}

- (NSString *)avatar {
    return makeSureNotNull([self.basicDict objectForKey:kAvatar]);
}

- (NSString *)fans_count {
    return makeSureNotNull([self.basicDict objectForKey:kFans_count]);
}

-(void)setFans_count:(NSString *)fans_count{
    [self.basicDict setObject:fans_count forKey:kFans_count];
}

- (NSString *)video_count {
    return makeSureNotNull([self.basicDict objectForKey:kVideo_count]);
}

-(void)setVideo_count:(NSString *)video_count{
    [self.basicDict setObject:video_count forKey:kVideo_count];

}

- (NSString *)like_count {
    return makeSureNotNull([self.basicDict objectForKey:kLike_count]);
}

- (void)setLike_count:(NSString *)like_count{
    [self.basicDict setObject:like_count forKey:kLike_count];
}

- (NSString *)idol_count {
    return makeSureNotNull([self.basicDict objectForKey:kIdol_count]);
}

-(void)setIdol_count:(NSString *)idol_count{
    [self.basicDict setObject:idol_count forKey:kIdol_count];
}

- (NSString *)userDescription {
    return makeSureNotNull([self.basicDict objectForKey:kUserDescription]);
}

- (NSString *)timestamp {
    return makeSureNotNull([self.basicDict objectForKey:kTimestamp]);
}

- (NSString *)location {
    return makeSureNotNull([self.basicDict objectForKey:kLocation]);
}

- (NSString *)sex {
    return makeSureNotNull([self.basicDict objectForKey:kSex]);
}

- (NSString *)main_uid {
    return makeSureNotNull([self.basicDict objectForKey:kMain_uid]);
}

- (NSString *)constellation {
    return makeSureNotNull([self.basicDict objectForKey:kConstellation]);
}

- (NSString *)birthday {
    return makeSureNotNull([self.basicDict objectForKey:kBirthday]);
}

- (BOOL)isMineIdol {
    return [makeSureNotNull([self.basicDict objectForKey:kIsMineIdol]) boolValue];
}

- (void)setIsMineIdol:(BOOL)isMineIdol {
    [self.basicDict setObject:[NSNumber numberWithBool:isMineIdol] forKey:kIsMineIdol];
}

@end
