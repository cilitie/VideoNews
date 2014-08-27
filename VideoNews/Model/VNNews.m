//
//  VNNews.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNNews.h"
#import "VNUser.h"

static NSString *kNid = @"nid";
static NSString *kLike_count = @"like_count";
static NSString *kComment_count = @"comment_count";
static NSString *kDate = @"date";
static NSString *kTitle = @"title";
static NSString *kName = @"name";
static NSString *kURL = @"url";
static NSString *kShare_count = @"share_count";
static NSString *kTags = @"tags";
static NSString *kDescription = @"description";
static NSString *kAuthor = @"author";
static NSString *kMedia = @"media";
static NSString *kImgMedia = @"imgMedia";
static NSString *kVedioMedia = @"vedioMedia";
static NSString *kTimestamp = @"timestamp";
static NSString *kClassid = @"classid";

@implementation VNNews

- (int)nid {
    return [makeSureNotNull([self.basicDict objectForKey:kNid]) intValue];
}

- (int)like_count {
    return [makeSureNotNull([self.basicDict objectForKey:kLike_count]) intValue];
}

- (void)setLike_count:(int)like_count {
    [self.basicDict setObject:[NSNumber numberWithInt:like_count] forKey:kLike_count];
}

- (int)comment_count {
    return [makeSureNotNull([self.basicDict objectForKey:kComment_count]) intValue];
}

- (NSString *)date {
    return makeSureNotNull([self.basicDict objectForKey:kDate]);
}

- (NSString *)title {
    return makeSureNotNull([self.basicDict objectForKey:kTitle]);
}

- (NSString *)name {
    return makeSureNotNull([self.basicDict objectForKey:kName]);
}

- (NSString *)url {
    return makeSureNotNull([self.basicDict objectForKey:kURL]);
}

- (int)share_count {
    return [makeSureNotNull([self.basicDict objectForKey:kShare_count]) intValue];
}

- (NSString *)tags {
    return makeSureNotNull([self.basicDict objectForKey:kTags]);
}

- (NSString *)description {
    return makeSureNotNull([self.basicDict objectForKey:kDescription]);
}

- (VNUser *)author {
    return makeSureNotNull([self.basicDict objectForKey:kAuthor]);
}

- (void)setAuthor:(VNUser *)author {
    [self.basicDict setObject:author forKey:kAuthor];
}

- (NSArray *)mediaArr {
    return makeSureNotNull([self.basicDict objectForKey:kMedia]);
}

- (void)setMediaArr:(NSArray *)mediaArr {
    [self.basicDict setObject:mediaArr forKey:kMedia];
}

- (VNMedia *)imgMdeia {
    return makeSureNotNull([self.basicDict objectForKey:kImgMedia]);
}

- (void)setImgMdeia:(VNMedia *)imgMdeia {
    [self.basicDict setObject:imgMdeia forKey:kImgMedia];
}

- (VNMedia *)videoMedia {
    return makeSureNotNull([self.basicDict objectForKey:kVedioMedia]);
}

- (void)setVideoMedia:(VNMedia *)videoMedia {
    [self.basicDict setObject:videoMedia forKey:kVedioMedia];
}

- (NSString *)timestamp {
    return makeSureNotNull([self.basicDict objectForKey:kTimestamp]);
}

- (NSString *)classid {
    return makeSureNotNull([self.basicDict objectForKey:kClassid]);
}

@end
