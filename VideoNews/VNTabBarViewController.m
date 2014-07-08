//
//  VNTabBarViewController.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNTabBarViewController.h"
#import "VNAuthUser.h"
#import "VNLoginViewController.h"

@interface VNTabBarViewController () <UIAlertViewDelegate>

@end

@implementation VNTabBarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.tabBar setBarTintColor:[UIColor whiteColor]];
    [self.tabBar setSelectionIndicatorImage:[self createImageWithColor:[UIColor colorWithRGBValue:0x3f3f3f]]];
    
    NSArray *tabBarIcons = @[@"Home", @"Search", @"Camera", @"Notification", @"Profile"];
    NSArray *tabBarSelectedIcons = @[@"Home_A", @"Search_A", @"Camera_A", @"Notification_A", @"Profile_A"];
    
    [self.tabBar.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UITabBarItem *item = obj;
        [item setImage:[[UIImage imageNamed:[tabBarIcons objectAtIndex:idx]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [item setSelectedImage:[[UIImage imageNamed:[tabBarSelectedIcons objectAtIndex:idx]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    }];
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    VNAuthUser *authUser = nil;
    if (userInfo.count) {
        authUser = [[VNAuthUser alloc] initWithDict:userInfo];
    }
    
    if (authUser) {
        [VNHTTPRequestManager loginWithUser:authUser completion:^(BOOL succeed, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (succeed) {
                [VNUtility showHUDText:@"登录成功!" forView:self.view];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else {
                [VNUtility showHUDText:@"登录失败!" forView:self.view];
            }
        }];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"是否登录应用？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - SEL

- (UIImage *)createImageWithColor:(UIColor*)color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 64.0f, 49.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    }
    else if (buttonIndex == 1) {
        VNLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNLoginViewController"];
        [self presentViewController:loginViewController animated:YES completion:nil];
    }
}

@end
