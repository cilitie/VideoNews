//
//  VNUtility.h
//  VideoNews
//
//  Created by liuyi on 14-7-8.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>

@interface VNUtility : NSObject

+ (void)showHUDText:(NSString *)text forView:(UIView *)view;
+ (NSString *)strFromTimeStampSince1970:(NSTimeInterval)timeInterval;
+ (NSString *)getNSCachePath:(NSString *)filenameorpath;
+ (NSString *)timeFormatToDisplay:(NSTimeInterval)timeInterval;
+ (NSString *)countFormatToDisplay:(int)number;

@end
