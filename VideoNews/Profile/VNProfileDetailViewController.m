//
//  VNProfileDetailViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-24.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNProfileDetailViewController.h"
#import "VNLoginViewController.h"

@interface VNProfileDetailViewController () <UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *genderImg;
@property (weak, nonatomic) IBOutlet UILabel *constellationLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UITextView *userDescriptionTextView;
@property (weak, nonatomic) IBOutlet UIButton *reportBtn;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameLabelWidthLC;

- (IBAction)pop:(id)sender;
- (IBAction)report:(id)sender;

@end

@implementation VNProfileDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.reportBtn.layer.cornerRadius = 5.0;
    self.reportBtn.layer.masksToBounds = YES;
    if (self.user) {
        //videoHeaderView
        [self.thumbnail setImageWithURL:[NSURL URLWithString:self.user.avatar] placeholderImage:[UIImage imageNamed:@"150-150User"]];
        [self.thumbnail.layer setCornerRadius:CGRectGetHeight([self.thumbnail bounds]) / 2];
        self.thumbnail.layer.masksToBounds = YES;
        NSLog(@"%@", self.user.name);
        [self.nameLabel setText:self.user.name];
        NSDictionary *attribute = @{NSFontAttributeName: self.nameLabel.font};
        CGRect rect = [self.user.name boundingRectWithSize:CGSizeMake(150.0, CGRectGetHeight(self.nameLabel.frame)) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        self.nameLabelWidthLC.constant = CGRectGetWidth(rect)+1;
        
        if (self.user.sex) {
            self.genderImg.hidden = NO;
            if ([self.user.sex isEqualToString:@"male"]) {
                [self.genderImg setImage:[UIImage imageNamed:@"25-25Male"]];
            }
            else if ([self.user.sex isEqualToString:@"female"]) {
                [self.genderImg setImage:[UIImage imageNamed:@"25-25Female"]];
            }
            else {
                self.genderImg.hidden = YES;
            }
        }
        else {
            self.genderImg.hidden = YES;
        }
        if (self.user.constellation) {
            self.constellationLabel.text=self.user.constellation;
        }
        if (self.user.location) {
            self.locationLabel.text = self.user.location;
        }
        else {
            self.locationLabel.text = @"位置未知";
        }
        
        if (self.user.userDescription && ![self.user.userDescription isEqualToString:@""]) {
            self.userDescriptionTextView.text = self.user.userDescription;
        }
        else {
            self.userDescriptionTextView.text = @"ta没有任何介绍";
        }
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

- (IBAction)pop:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)report:(id)sender {
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    if (userInfo && userInfo.count) {
        NSString *uid = [userInfo objectForKey:@"openid"];
        NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
        if (uid && user_token) {
            [VNHTTPRequestManager report:self.user.uid type:@"reportUser" userID:uid userToken:user_token completion:^(BOOL succeed, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else if (succeed) {
                    [VNUtility showHUDText:@"举报成功!" forView:self.view];
                }
                else {
                    [VNUtility showHUDText:@"您已举报该用户" forView:self.view];
                }
            }];
        }
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
        [alert show];
        return;
    }
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
