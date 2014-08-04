//
//  VNUtility.m
//  VideoNews
//
//  Created by liuyi on 14-7-8.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNUtility.h"

@implementation VNUtility

+ (void)showHUDText:(NSString *)text forView:(UIView *)view {
    NSLog(@"text:%@", text);
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view.window animated:YES];
    hud.mode = MBProgressHUDModeText;
    hud.labelText = text;
    hud.margin = 10.0f;
    hud.removeFromSuperViewOnHide = YES;
    
    [hud hide:YES afterDelay:2.0f];
}

+ (NSString *)strFromTimeStampSince1970:(NSTimeInterval)timeInterval {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    formatter.dateFormat = @"YYYY-MM-dd";
    return [formatter stringFromDate:date];
}

/**
 *  @description: return the cache path(appending the user relative path) to user
 *
 *  @param filenameorpath : path relative to app cache path
 *
 *  @return : whole path string
 */
+ (NSString *)getNSCachePath:(NSString *)filenameorpath{
	NSArray *Paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *Directory = [Paths objectAtIndex:0];
    filenameorpath = [Directory stringByAppendingPathComponent:filenameorpath];
	Directory=nil;
	Paths=nil;
    return filenameorpath;
}

@end
