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

@end
