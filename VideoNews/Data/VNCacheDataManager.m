//
//  VNCacheDataManager.m
//  VideoNews
//
//  Created by liuyi on 14-7-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCacheDataManager.h"

@implementation VNCacheDataManager

+ (NSString *)pathForURL:(NSString *)URL {
    NSString *URLCacheDir = [[VNCacheDataManager cacheDirectory] stringByAppendingPathComponent:@"URLCache"];
    BOOL isDir = YES;
    NSError *error;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:URLCacheDir isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:URLCacheDir withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return [URLCacheDir stringByAppendingPathComponent:[URL md5]];
}

+ (void)addCacheData:(NSArray *)addArr fromURL:(NSString *)URL completion:(void (^)(BOOL succeeded))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSMutableData *data = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:addArr forKey:[URL md5]];
        [archiver finishEncoding];
        BOOL succeeded = [data writeToFile:[self pathForURL:URL] atomically:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block (succeeded);
            }
        });
    });
}

+ (void)cacheDataFromURL:(NSString *)URL completion:(void (^)(NSArray *queryArr))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSData *data = [[NSMutableData alloc] initWithContentsOfFile:[self pathForURL:URL]];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSArray *resultQueryArr = [unarchiver decodeObjectForKey:[URL md5]];
        [unarchiver finishDecoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block (resultQueryArr);
            }
        });
    });
}

#pragma mark - SearchHistory

+ (NSString *)historyDataPath
{
    return [[self cacheDirectory] stringByAppendingPathComponent:@"SearchHistoryWord"];
}

+ (NSArray *)historyDataSync
{
    NSData *data = [[NSMutableData alloc] initWithContentsOfFile:[self historyDataPath]];
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSArray *resultQueryArr = [unarchiver decodeObjectForKey:kArchivingHistoryWord];
    [unarchiver finishDecoding];
    
    return resultQueryArr;
}

+ (void)addHistoryData:(NSString *)historyStr completion:(void (^)(BOOL succeeded))block
{
    NSArray *queryHistoryArr = [self historyDataSync];
    NSMutableArray *tempHistoryAry = nil;
    if (queryHistoryArr) {
        tempHistoryAry = [NSMutableArray arrayWithArray:queryHistoryArr];
    }
    else {
        tempHistoryAry = [NSMutableArray arrayWithCapacity:0];
    }
    
    dispatch_queue_t saveQueue = dispatch_queue_create("addHistoryWord", DISPATCH_QUEUE_SERIAL);
    
    dispatch_sync(saveQueue, ^{
        //检测是否为已存历史词
        if (tempHistoryAry && tempHistoryAry.count) {
            for (NSString *temphistoryWord in tempHistoryAry) {
                if ([temphistoryWord isEqualToString:historyStr]) {
                    [tempHistoryAry removeObject:temphistoryWord];
                    break;
                }
            }
        }
        [tempHistoryAry insertObject:historyStr atIndex:0];
        
        NSMutableData *data = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:tempHistoryAry forKey:kArchivingHistoryWord];
        [archiver finishEncoding];
        BOOL succeeded = [data writeToFile:[self historyDataPath] atomically:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:VNHistoryDidAddNotification object:nil];
            if (block) {
                block (succeeded);
            }
        });
    });
}

+ (void)historyDataWithCompletion:(void (^)(NSArray *queryHistoryArr))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *data = [[NSMutableData alloc] initWithContentsOfFile:[self historyDataPath]];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSArray *resultQueryArr = [unarchiver decodeObjectForKey:kArchivingHistoryWord];
        [unarchiver finishDecoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block (resultQueryArr);
            }
        });
    });
}

+ (void)clearHistoryDataWithCompletion:(void (^)(BOOL succeeded))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL succeeded = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self historyDataPath]]) {
            succeeded = [[NSFileManager defaultManager] removeItemAtPath:[self historyDataPath] error:nil];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:VNHistoryDidClearNotification object:nil];
            if (block) {
                block (succeeded);
            }
        });
    });
}

#pragma mark - CacheSize

+ (long long) fileSizeAtPath:(NSString*)filePath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:filePath]){
        return [[manager attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    return 0;
}

+ (NSString *)folderSizeAtPath:(NSString*)folderPath{
    NSFileManager* manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:folderPath]) return @"0 KB";
    NSEnumerator *childFilesEnumerator = [[manager subpathsAtPath:folderPath] objectEnumerator];
    NSString* fileName;
    long long folderSize = 0;
    while ((fileName = [childFilesEnumerator nextObject]) != nil){
        NSString* fileAbsolutePath = [folderPath stringByAppendingPathComponent:fileName];
        folderSize += [self fileSizeAtPath:fileAbsolutePath];
    }
    
    float resultSize = folderSize/1024;
    if (resultSize >= 1024.0) {
        return [NSString stringWithFormat:@"%0.1f MB", (resultSize/1024)];
    }
    else {
        return [NSString stringWithFormat:@"%0.1f KB", resultSize];
    }
}

+ (void)cacheSizeWithCompletion:(void(^)(NSString *cacheSize))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *cacheSize = [self folderSizeAtPath:[self cacheDirectory]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                NSLog(@"%@", cacheSize);
                block (cacheSize);
            }
        });
    });
}

+ (void)clearCacheWithCompletion:(void(^)(BOOL succeeded))block
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        BOOL isDirectory = YES;
        BOOL succeeded = NO;
        NSString *cacheDir = [self cacheDirectory];
        if ([fileManager fileExistsAtPath:cacheDir isDirectory:&isDirectory]) {
            succeeded = [fileManager removeItemAtPath:cacheDir error:nil];
        }
        else {
            succeeded = YES;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block (succeeded);
            }
        });
    });
}

+ (NSString *)cacheDirectory
{
    NSString *cacheDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"com.chinaso.mobileSearch_cache"];
    BOOL isDir = YES;
    NSError *error;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:cacheDir isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheDir withIntermediateDirectories:YES attributes:nil error:&error];
    }
    return cacheDir;
}

@end
