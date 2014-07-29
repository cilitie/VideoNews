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

#import "VNVideoCaptureViewController.h"
#import "VNCustomizedAlbumPickerController.h"
#import "VNDraftListController.h"
#import "VNCustomizedActionSheet.h"

@interface VNTabBarViewController () <UIAlertViewDelegate, UITabBarControllerDelegate, VNCustomizedActionSheetDelegate>

@end

@implementation VNTabBarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.tabBar setBarTintColor:[UIColor whiteColor]];
    [self.tabBar setSelectionIndicatorImage:[self createImageWithColor:[UIColor colorWithRGBValue:0x3f3f3f]]];
    self.delegate = self;
    
    NSArray *tabBarIcons = @[@"Home", @"Search", @"Camera", @"Notification", @"Profile"];
    NSArray *tabBarSelectedIcons = @[@"Home_A", @"Search_A", @"Camera_A", @"Notification_A", @"Profile_A"];
    
    [self.tabBar.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UITabBarItem *item = obj;
        [item setImage:[[UIImage imageNamed:[tabBarIcons objectAtIndex:idx]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [item setSelectedImage:[[UIImage imageNamed:[tabBarSelectedIcons objectAtIndex:idx]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    }];
    
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    [[NSUserDefaults standardUserDefaults] setObject:@NO forKey:isLogin];
    [[NSUserDefaults standardUserDefaults] synchronize];
    VNAuthUser *authUser = nil;
    if (userInfo.count) {
        authUser = [[VNAuthUser alloc] initWithDict:userInfo];
    }
    NSDate *lastLoginDate = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginDate];
    BOOL isUserLoginTimeout = [[NSDate date] timeIntervalSinceDate:lastLoginDate] > 30*24*60*60;
    
    if (authUser && !isUserLoginTimeout) {
        [VNHTTPRequestManager loginWithUser:authUser completion:^(BOOL succeed, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (succeed) {
                [VNUtility showHUDText:@"登录成功!" forView:self.view];
                [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:isLogin];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else {
                [VNUtility showHUDText:@"登录失败!" forView:self.view];
            }
        }];
    }
    else {
        if (isUserLoginTimeout) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你登录的账号已过期~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
            [alert show];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
            [alert show];
        }
    }
    
    //btn to open UIImagePickerController in the middle of tabbarcontroller.
    UIButton *openPickerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    openPickerBtn.frame = CGRectMake(125, 0, 70, 49);
    openPickerBtn.backgroundColor = [UIColor clearColor];
    [openPickerBtn addTarget:self action:@selector(doOpenImagePickerCtl) forControlEvents:UIControlEventTouchUpInside];
    [self.tabBar addSubview:openPickerBtn];
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

#pragma mark - UITabBarControllerDelegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    if ([self.viewControllers indexOfObject:viewController] == 4) {
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
        if (userInfo[@"openid"] && user_token) {
            return YES;
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
            [alert show];
            return NO;
        }
    }
    return YES;
}

#pragma mark - UserInteractionMethods

/**
 *  @description: open video capture view , start video capture.
 */
- (void)doOpenImagePickerCtl
{
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    VNCustomizedActionSheet *actionSheet = [[VNCustomizedActionSheet alloc] initWithFrame:CGRectMake(0, 0, 320, height)];
    actionSheet.delegate = self;
    actionSheet.superView = self.view;
    [actionSheet show];
}

- (void)presentVideoCaptureView
{
    [MobClick event:@"video_record" label:@"camera"];
    
    VNVideoCaptureViewController *captureCtl = [[VNVideoCaptureViewController alloc] initWithVideoClips];
    UINavigationController *videoNav = [[UINavigationController alloc] initWithRootViewController:captureCtl];
    videoNav.navigationBarHidden = YES;
    [self presentViewController:videoNav animated:YES completion:nil];
}

#pragma mark - VNCustomizedActionSheetDelegate

- (void)draftBtnDidPressed
{
    [MobClick event:@"video_record" label:@"draft"];
    
    VNDraftListController *draftCtl = [[VNDraftListController alloc] init];
    
    UINavigationController *draftNav = [[UINavigationController alloc] initWithRootViewController:draftCtl];
    draftNav.navigationBarHidden = YES;
    
    [self presentViewController:draftNav animated:YES completion:nil];
}

- (void)cameraBtnDidPressed
{
    [MobClick event:@"video_record" label:@"camera"];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        VNVideoCaptureViewController *captureCtl = [[VNVideoCaptureViewController alloc] init];
        UINavigationController *videoNav = [[UINavigationController alloc] initWithRootViewController:captureCtl];
        videoNav.navigationBarHidden = YES;
        [self presentViewController:videoNav animated:YES completion:nil];
        
    }else {
        
        //if camera is not avaliable, use album instead.
        [self albumBtnDidPressed];
    }
}

- (void)albumBtnDidPressed
{
    [MobClick event:@"video_record" label:@"album"];
    VNCustomizedAlbumPickerController *picker = [[VNCustomizedAlbumPickerController alloc] init];
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)cancelBtnClicked
{
    //do nothing
}

@end
