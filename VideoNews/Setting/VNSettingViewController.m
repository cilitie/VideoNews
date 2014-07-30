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

@interface VNSettingViewController () <UITableViewDataSource, UITableViewDelegate>

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
        return 4;
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
        cell.isAutoPlay = YES;
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
    }
    else if (indexPath.section == 2) {
        switch (indexPath.row) {
            case 0: {
                [MobClick checkUpdate];
            }
                break;
            case 1: {
                [UMFeedback showFeedback:self withAppkey:UmengAppkey];
            }
                break;
            case 2: {
                NSString *appStoreURLStr = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", AppID];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appStoreURLStr]];
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
        }
    }
    else if (indexPath.section == 3) {
        VNLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNLoginViewController"];
        [self presentViewController:loginViewController animated:YES completion:nil];
    }
}

#pragma mark - SEL

- (IBAction)pop:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
