//
//  VNSettingViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-28.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNSettingViewController.h"
#import "VNSettingTableViewCell.h"
#import "UMFeedback.h"
#import "VNLoginViewController.h"
#import "VNDraftListController.h"
#import "UMSocial.h"
#import "VNAboutViewController.h"
#import "VNCheckOutTableViewCell.h"

@interface VNSettingViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UMSocialUIDelegate>

@property (weak, nonatomic) IBOutlet UITableView *settingTableView;

- (IBAction)pop:(id)sender;

@end

@implementation VNSettingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)presentDraftViewCtl
{
    [MobClick event:@"video_record" label:@"draft"];
    
    VNDraftListController *draftCtl = [[VNDraftListController alloc] init];
    
    UINavigationController *draftNav = [[UINavigationController alloc] initWithRootViewController:draftCtl];
    draftNav.navigationBarHidden = YES;
    
    [self presentViewController:draftNav animated:YES completion:nil];
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

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 2) {
        //return 6;
        return 5;
    }
    else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"VNSettingViewControllerCellIdentifier";
    VNSettingTableViewCell *cell = (VNSettingTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (indexPath.section == 0) {
        cell.titleLabel.text = @"草稿箱";
    }
    else if (indexPath.section == 1) {
        cell.titleLabel.text = @"WiFi下自动播放";
        [cell reload];
    }
    else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0: {
                cell.titleLabel.text = @"检查更新";
            }
                break;
            case 1: {
                cell.titleLabel.text = @"意见反馈";
            }
                break;
            case 2: {
                cell.titleLabel.text = @"推荐给朋友";
            }
                break;
            case 3: {
                cell.titleLabel.text = @"清除缓存";
            }
                break;
            case 4:{
                cell.titleLabel.text = @"关于我们";
            }
                break;
                /*
            case 5:{
                cell.titleLabel.text = @"收银台";
            }
                break;
                 */
        }
    }
    else if (indexPath.section == 3) {
        cell.titleLabel.text = @"退出登录";
        cell.titleLabel.textColor = [UIColor colorWithRGBValue:0xce2426];
        cell.titleLabel.textAlignment = NSTextAlignmentCenter;
        cell.titleLabelHeadLC.constant = (CGRectGetWidth(cell.bounds)-CGRectGetWidth(cell.titleLabel.bounds))/2;
    }
    
    return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        
        //present draft view controller
        [self presentDraftViewCtl];
        
    }
    else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0: {
                //commented by zx 20140903
                [MobClick checkUpdate];
//                [MobClick checkUpdateWithDelegate:self selector:@selector(checkUpdateFinished:)];
            }
                break;
            case 1: {
                [UMFeedback showFeedback:self withAppkey:UmengAppkey];
            }
                break;
            case 2: {
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接", nil];
                [actionSheet showInView:self.view];
            }
                break;
            case 3: {
                [VNCacheDataManager cacheSizeWithCompletion:^(NSString *cacheSize) {
                    NSString *curCacheSize = cacheSize;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [VNCacheDataManager clearCacheWithCompletion:^(BOOL succeeded) {
                            if (succeeded) {
                                [VNUtility showHUDText:[NSString stringWithFormat:@"清除缓存%@", curCacheSize] forView:self.view];
                            }
                            else {
                                [VNUtility showHUDText:@"清除缓存失败" forView:self.view];
                            }
                        }];
                    });
                }];
            }
                break;
            case 4:{
                VNAboutViewController *aboutVC=[self.storyboard instantiateViewControllerWithIdentifier:@"VNAboutViewController"];
                [self.navigationController pushViewController:aboutVC animated:YES];
            }
                break;
                /*
            case 5:{
                VNCheckOutTableViewCell *checkoutVC=[self.storyboard instantiateViewControllerWithIdentifier:@"VNCheckOutViewController"];
                [self.navigationController pushViewController:checkoutVC animated:YES];
            }
                break;
              */
        }
    }
    else if (indexPath.section == 3) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"确定退出登录？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
        
    }
}

//- (void)checkUpdateFinished:(NSDictionary *)info
//{
//    {
//        "current_version" = "1.01";
//        update = NO;
//    }
//    NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
//    NSString * localVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
//    
//    NSString *onlineVersion = [info objectForKey:@"current_version"];
//    
//    BOOL update = [[info objectForKey:@"update"] boolValue];
//    if (update) {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:@"有新版本%@可以更新",onlineVersion] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
//        [alert show];
//    }else {
//        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"当前已经是最新版本了" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
//        [alert show];
//    }
//    NSLog(@"info :%@",info);
//}

- (void)appUpdate:(NSDictionary *)appInfo
{
    NSLog(@"appinfo :%@",appInfo);
}

#pragma mark - SEL

- (IBAction)pop:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    }
    else if (buttonIndex == 1) {
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:VNLoginUser];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:isLogin];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:VNLoginDate];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:VNPushToken];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:VNUserToken];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:VNProfileInfo];
        [[NSUserDefaults standardUserDefaults]removeObjectForKey:VNIsWiFiAutoPlay];
        [[NSUserDefaults standardUserDefaults] synchronize];
        VNLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNLoginViewController"];
        loginViewController.controllerType=SourceVCTypeMineProfile;
        [self.navigationController popViewControllerAnimated:YES];
        /*if (self.navigationController.viewControllers.count > 1) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }*/
        UINavigationController *loginNavCtl = [[UINavigationController alloc] initWithRootViewController:loginViewController];
        [self presentViewController:loginNavCtl animated:YES completion:nil];
        
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSLog(@"%@", [UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray);
    //NSString *shareURL = @"https://itunes.apple.com/cn/app/xiao-xiao-huo-ban-sago-mini/id874425722?mt=8";
    NSString *shareURL=@"https://itunes.apple.com/cn/app/fashionmaker/id907182257?mt=8";
    NSString *snsName = nil;
    switch (buttonIndex) {
            //微信朋友圈
        case 0: {
            snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:3];
            [UMSocialData defaultData].extConfig.wechatTimelineData.url = shareURL;
        }
            break;
            //微信好友
        case 1: {
            snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:2];
            [UMSocialData defaultData].extConfig.wechatSessionData.url = shareURL;
        }
            break;
            //新浪微博
        case 2: {
            snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:0];
        }
            break;
            //QQ空间
        case 3: {
            snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:5];
            [UMSocialData defaultData].extConfig.qzoneData.url = shareURL;
        }
            break;
            //QQ好友
        case 4: {
            snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:6];
            [UMSocialData defaultData].extConfig.qqData.url = shareURL;
        }
            break;
            //腾讯微博
        case 5: {
            snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:1];
        }
            break;
            //人人网
        case 6: {
            snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:7];
        }
            break;
            //取消或复制
        case 7: {
            UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
            pasteboard.string = shareURL;
            [VNUtility showHUDText:@"已复制应用链接" forView:self.view];
        }
            break;
            //取消
        case 8: {
            return ;
        }
            break;
    }
    //设置分享内容，和回调对象
    if (buttonIndex < 7) {
        //NSString *shareText = [NSString stringWithFormat:@"分享%@的视频：“%@”，快来看看吧~ %@",  self.shareNews.author.name,self.shareNews.title,self.shareNews.url];
        NSString *shareText = [NSString stringWithFormat:@"点击下载“时尚拍”，记录你的生活，分享你的穿搭 %@", shareURL];
        UIImage *shareImage = [UIImage imageNamed:@"Icon"];
        
        [[UMSocialControllerService defaultControllerService] setShareText:shareText shareImage:shareImage socialUIDelegate:self];
        UMSocialSnsPlatform *snsPlatform = [UMSocialSnsPlatformManager getSocialPlatformWithName:snsName];
        snsPlatform.snsClickHandler(self,[UMSocialControllerService defaultControllerService],YES);
    }
}


@end
