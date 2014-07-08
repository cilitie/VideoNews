//
//  ZXRemoteNotification.m
//  ZXPush
//
//  Created by 张玺 on 12-8-13.
//  Copyright (c) 2012年 张玺. All rights reserved.
//

#import "ZXRemoteNotification.h"

@implementation UIResponder (ZXRemoteNotification)

+(void)registerRemote
{
    [[UIApplication sharedApplication]
     registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                         UIRemoteNotificationTypeSound |
                                         UIRemoteNotificationTypeAlert 
                                         )];
}

+(void)addDevice:(id)token
{
    NSString* deviceToken = nil;
    if ([token isKindOfClass:[NSData class]]) {
        deviceToken = [[[[token description]
                                   stringByReplacingOccurrencesOfString: @"<" withString: @""]
                                  stringByReplacingOccurrencesOfString: @">" withString: @""]
                                 stringByReplacingOccurrencesOfString: @" " withString: @""];
        [[NSUserDefaults standardUserDefaults] setObject:deviceToken forKey:VNPushToken];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    [UIResponder addDevice:deviceToken];
}

- (void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
    NSLog(@"Error in registration. Error: %@", error);
}


- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    /*
     收到消息自定义事件
     */
    NSLog(@"%@",userInfo);
    
    if ([[userInfo objectForKey:@"aps"] objectForKey:@"alert"] != nil) {
        
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"通知"
//                                                        message:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]
//                                                       delegate:self
//                                              cancelButtonTitle:@"确定"
//                                              otherButtonTitles:nil];
//        [alert show];
        [[UIApplication sharedApplication ] setApplicationIconBadgeNumber:0];
    }
}

@end
