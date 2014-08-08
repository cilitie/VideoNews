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
#import "UMSocialSinaHandler.h"
#import "VNTabBarViewController.h"
#import "VNLoginViewController.h"
#import <objc/runtime.h>

@implementation VNAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [MobClick startWithAppkey:UmengAppkey reportPolicy:(ReportPolicy) REALTIME channelId:nil];
    [UMSocialData setAppKey:UmengAppkey];
    
    [UMSocialSinaHandler openSSOWithRedirectURL:@"http://sns.whalecloud.com/sina2/callback"];
    [UMSocialWechatHandler setWXAppId:WXAppkey url:@"http://www.baidu.com"];
    [UMSocialQQHandler setQQWithAppId:QQAppID appKey:QQAppKey url:@"http://www.baidu.com"];
    [UMSocialQQHandler setSupportWebView:YES];
    //注册通知
    [UIResponder registerRemote];
    
    //若没有登陆，则加载登陆页面
    NSDictionary *loginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    if (loginInfo[@"openid"] && user_token) {
        
        [self checkVideoCapture];
    }
    else
    {
        UIStoryboard *storyBoard=[UIStoryboard storyboardWithName:@"Main" bundle:nil];
        VNLoginViewController *loginViewController = [storyBoard instantiateViewControllerWithIdentifier:@"VNLoginViewController"];
        //[_window addSubview:loginViewController.view];
        VNTabBarViewController *tabBarViewController=(VNTabBarViewController *)self.window.rootViewController;
        [tabBarViewController presentViewController:loginViewController animated:YES completion:nil];

    }

    
    if ([UIApplication sharedApplication].applicationIconBadgeNumber!=0) {
        //使用badge number判断，计数不正确
        [self setItemBadgeValue];
    }
    
    NSDictionary *userInfo=[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    //userInfo=@{@"key": @"value"};
    if (userInfo) {
        //跳到通知页面：从此处跳到通知页面会导致用户没有登录，通知页面没有数据，以后改进
        //tabBarViewController.selectedIndex=3;
        
        [self setItemBadgeValue];
        
    }
    
    //to see if there's any video clip left(after video capture last time of application launch).
    //NSDictionary *loginInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    //NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    //if (loginInfo[@"openid"] && user_token) {
    //    [self checkVideoCapture];
    //}
    
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
    if ([UIApplication sharedApplication].applicationIconBadgeNumber!=0) {
        //使用badge number判断，计数不正确
        [self setItemBadgeValue];
    }
    
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
    [self setItemBadgeValue];
    
}

- (void)application:(UIApplication *)application
didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
    NSLog(@"Error in registration. Error: %@", error);
}

-(void)setItemBadgeValue
{
    VNTabBarViewController *tabBarViewController=(VNTabBarViewController *)self.window.rootViewController;
    
    UITabBarItem *item=[tabBarViewController.tabBar.items objectAtIndex:3];
    if (item.badgeValue==nil) {
        item.badgeValue=[NSString stringWithFormat:@"%d",1];
        //item.badgeValue=@"";
    }
    else
    {
        int value=[item.badgeValue intValue];
        value=value+1;
        if (value>999) {
            item.badgeValue=@"999+";
        }
        else
        {
            //item.badgeValue=@"";
            item.badgeValue=[NSString stringWithFormat:@"%d",value];
        }
    }
    [[UIApplication sharedApplication ] setApplicationIconBadgeNumber:0];
    
}

#pragma mark - Video Related

- (void)checkVideoCapture
{
    NSString *dirPath = [[VNUtility getNSCachePath:@"VideoFiles"] stringByAppendingPathComponent:@"Clips"];
    NSString *cropFilePath = [[VNUtility getNSCachePath:@"VideoFiles/Temp"] stringByAppendingPathComponent:@"VN_Video_Cropped.mp4"];
    BOOL _isDir;
    
    BOOL existCropFile = [[NSFileManager defaultManager] fileExistsAtPath:cropFilePath];
    BOOL existClipFile = [[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&_isDir];
    
    NSArray *clipsArr;
    
    if (existClipFile) {
        clipsArr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
    }
    
    if (existCropFile || (clipsArr && clipsArr.count > 0)) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"上次视频编辑未完成，是否继续" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        
        void (^clearVideoBlock)(NSInteger) = ^(NSInteger buttonIndex){
            if (buttonIndex == 0) {
                //delete those clips.
                
                if (clipsArr && clipsArr.count > 0) {
                    NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:nil];
                    
                    for (NSString *dir in arr) {
                        [[NSFileManager defaultManager] removeItemAtPath:[dirPath stringByAppendingPathComponent:dir] error:nil];
                    }
                }
                
                if (existCropFile) {
                    [[NSFileManager defaultManager] removeItemAtPath:cropFilePath error:nil];
                }
            } else {
                //go to video capture view.
                VNTabBarViewController *tabbarCtl = (VNTabBarViewController *)self.window.rootViewController;
                [tabbarCtl presentVideoCaptureView];
            }
        };
        objc_setAssociatedObject(alert, @"continueEdittingVideo",
                                 clearVideoBlock, OBJC_ASSOCIATION_COPY);
        
        [alert show];
    }
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    void (^clearVideoBlock)(NSInteger) = objc_getAssociatedObject(alertView, @"continueEdittingVideo");
    
    clearVideoBlock(buttonIndex);
    
    objc_removeAssociatedObjects(alertView);
}

@end
