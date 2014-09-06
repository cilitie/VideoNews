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
    
    [hud hide:YES afterDelay:1.5f];
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

+ (NSString *)timeFormatToDisplay:(NSTimeInterval)timeInterval
{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
    NSTimeInterval now=[[NSDate date] timeIntervalSince1970];
    NSTimeInterval diff=now-timeInterval;
    if (diff<0) {
        diff=-diff;
    }
    if (diff<86400) {//24*60*60
        formatter.dateFormat = @"hh:mm";
        return [formatter stringFromDate:date];
    }
    else if(diff<31536000){//365*24*60*60
        formatter.dateFormat = @"MM-dd hh:mm";
        return [formatter stringFromDate:date];
    }
    else{
        formatter.dateFormat = @"YY-MM";
        return [formatter stringFromDate:date];
    }
    
    //return [VNUtility strFromTimeStampSince1970:[ doubleValue]];
    
}

+(NSString *)countFormatToDisplay:(int)number
{
    if (number>1000 && number<=10000) {
        NSString *str=[NSString stringWithFormat:@"%dk",number/1000];
        return str;
    }
    if (number>10000) {
        NSString *str=[NSString stringWithFormat:@"%dw",number/10000];
        return  str;
    }
    
    NSString *str = [NSString stringWithFormat:@"%d", number];
    return  str;   

}

+ (BOOL)validateEmail:(NSString *)email{
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
}

+ (BOOL)validatePasswd:(NSString *)passwd
{
    NSString *passwdRegex = @"[A-Z0-9a-z]{6,20}";
    NSPredicate *passwdTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", passwdRegex];
    return [passwdTest evaluateWithObject:passwd];
}

@end
