//
//  VNCacheDataManager.h
//  VideoNews
//
//  Created by liuyi on 14-7-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VNCacheDataManager : NSObject

#pragma mark - listCache

+ (void)addCacheData:(NSArray *)addArr fromURL:(NSString *)URL completion:(void (^)(BOOL succeeded))block;
+ (void)cacheDataFromURL:(NSString *)URL completion:(void (^)(NSArray *queryArr))block;

#pragma mark - SearchHistory

+ (void)addHistoryData:(NSString *)historyStr completion:(void (^)(BOOL succeeded))block;
+ (void)historyDataWithCompletion:(void (^)(NSArray *queryHistoryArr))block;
+ (void)clearHistoryDataWithCompletion:(void (^)(BOOL succeeded))block;

#pragma mark - CacheSize

+ (void)cacheSizeWithCompletion:(void(^)(NSString *cacheSize))block;
+ (void)clearCacheWithCompletion:(void(^)(BOOL succeeded))block;
+ (NSString *)cacheDirectory;

@end
