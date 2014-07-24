//
//  VNAppDelegate.m
//  VideoNews
//
//  Created by liuyi on 14-6-25.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNAppDelegate.h"
#import "ZXRemoteNotification.h"
#import "UMSocial.h"
#import "UMSocialWechatHandler.h"
#import "UMSocialQQHandler.h"

@implementation VNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MobClick startWithAppkey:UmengAppkey reportPolicy:(ReportPolicy) REALTIME channelId:nil];
    [UMSocialData setAppKey:UmengAppkey];
    
    [UMSocialConfig setSupportSinaSSO:YES appRedirectUrl:@"http://sns.whalecloud.com/sina2/callback"];
    [UMSocialWechatHandler setWXAppId:WXAppkey url:@"http://www.baidu.com"];
    [UMSocialQQHandler setQQWithAppId:QQAppID appKey:QQAppKey url:@"http://www.baidu.com"];
    [UMSocialQQHandler setSupportQzoneSSO:YES];
    //注册通知
    [UIResponder registerRemote];
    
    NSDictionary *userInfo=[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (userInfo) {
        //跳到通知页面
    }
    
    // Override point for customization after application launch.
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [UMSocialSnsService  applicationDidBecomeActive];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return  [UMSocialSnsService handleOpenURL:url wxApiDelegate:nil];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return  [UMSocialSnsService handleOpenURL:url wxApiDelegate:nil];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)pToken {
    
    NSLog(@"regisger success:%@", pToken);
    [UIResponder addDevice:pToken];
    //注册成功，将deviceToken保存到应用服务器数据库中
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
    //在应用内收到通知时调用
    // 处理推送消息
    //UIAlertView *alert=[[UIAlertView alloc]initWithTitle:@"通知" message:@"我的信息" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:nil, nil];
    
    //[alert show];
    
    //[alert release];
    
    NSLog(@"%@", userInfo);
    
    [[UIApplication sharedApplication ] setApplicationIconBadgeNumber:0];
    
}

- (void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
    NSLog(@"Error in registration. Error: %@", error);
}

@end
