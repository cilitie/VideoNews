//
//  VNLoginViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-7.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNLoginViewController.h"
#import "WXApi.h"
#import "VNWeixinCodeResponse.h"
#import "VNAuthUser.h"
#import "UMSocial.h"
#import "VNTabBarViewController.h"
#import "VNRegisterViewController.h"
#import "VNForgetPasswdViewController.h"

@interface VNLoginViewController () <WXApiDelegate, UITextFieldDelegate>

- (IBAction)wechatLogin:(id)sender;
- (IBAction)weiboLogin:(id)sender;
- (IBAction)qqLogin:(id)sender;
- (IBAction)dismiss:(id)sender;

@property (weak, nonatomic) IBOutlet UITextField *emailTF;
@property (weak, nonatomic) IBOutlet UITextField *passwdTF;

@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@end

@implementation VNLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.emailTF setLeftViewMode:UITextFieldViewModeAlways];
    [self.emailTF setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 35)]];
    self.emailTF.layer.cornerRadius = 2.5;
    self.emailTF.delegate = self;
    self.emailTF.keyboardType = UIKeyboardTypeEmailAddress;
    
    [self.passwdTF setLeftViewMode:UITextFieldViewModeAlways];
    [self.passwdTF setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 35)]];
    self.passwdTF.layer.cornerRadius = 2.5;
    self.passwdTF.delegate = self;
    
    self.loginBtn.layer.cornerRadius = 2.5;
    
    self.title = @"登录";
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor colorWithRGBValue:0xCE2426]};
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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

- (IBAction)wechatLogin:(id)sender {
    [VNUtility showHUDText:@"暂未支持，敬请期待!" forView:self.view];
    //构造SendAuthReq结构体
//    SendAuthReq *req =[[SendAuthReq alloc] init];
//    req.scope = @"snsapi_userinfo" ;
//    req.state = @"wechat_VideoNews";
//    //第三方向微信终端发送一个SendAuthReq消息结构
//    [WXApi sendReq:req];
}

- (IBAction)weiboLogin:(id)sender {
    UMSocialSnsPlatform *snsPlatform = [UMSocialSnsPlatformManager getSocialPlatformWithName:@"sina"];
    snsPlatform.loginClickHandler(self,[UMSocialControllerService defaultControllerService],YES,^(UMSocialResponseEntity *response){
        NSLog(@"login response is %@",response);
        if ([response.message isEqualToString:@"no error"]) {
            [[UMSocialDataService defaultDataService] requestSnsInformation:UMShareToSina completion:^(UMSocialResponseEntity *respose){
                NSLog(@"response is %@",respose);
                VNAuthUser *authUser = [[VNAuthUser alloc] initWithDict:@{}];
                authUser.openid = [@"12" stringByAppendingString:[[respose.data objectForKey:@"uid"] stringValue]];
                authUser.nickname = [respose.data objectForKey:@"screen_name"];
                authUser.avatar = [respose.data objectForKey:@"profile_image_url"];
                if ([[respose.data objectForKey:@"gender"] intValue] == 1) {
                    authUser.gender = @"male";
                }
                else if([[respose.data objectForKey:@"gender"] intValue] == 0) {
                    authUser.gender = @"female";
                }
                else {
                    authUser.gender = @"";
                }
                authUser.gender = [respose.data objectForKey:@"gender"];
                [VNHTTPRequestManager loginWithUser:authUser completion:^(BOOL succeed, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (succeed) {
                        [VNUtility showHUDText:@"登录成功!" forView:self.view];
                        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:isLogin];
                        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:VNLoginDate];
                        if (![[NSUserDefaults standardUserDefaults] objectForKey:VNIsWiFiAutoPlay]) {
                            [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:VNIsWiFiAutoPlay];
                            //[[NSUserDefaults standardUserDefaults] synchronize];
                        }
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [[NSNotificationCenter defaultCenter]postNotificationName:VNLoginNotification object:nil];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    else {
                        [VNUtility showHUDText:@"登录失败!" forView:self.view];
                    }
                }];
            }];
        }
    });
}

- (IBAction)qqLogin:(id)sender {
    UMSocialSnsPlatform *snsPlatform = [UMSocialSnsPlatformManager getSocialPlatformWithName:@"qq"];
    snsPlatform.loginClickHandler(self,[UMSocialControllerService defaultControllerService],YES,^(UMSocialResponseEntity *response){
        NSLog(@"login response is %@",response);
        if ([response.message isEqualToString:@"no error"]) {
            [[UMSocialDataService defaultDataService] requestSnsInformation:UMShareToQQ completion:^(UMSocialResponseEntity *respose){
                NSLog(@"response is %@",respose);
                VNAuthUser *authUser = [[VNAuthUser alloc] initWithDict:@{}];
                authUser.openid = [@"13" stringByAppendingString:[respose.data objectForKey:@"openid"]];
                authUser.nickname = [respose.data objectForKey:@"screen_name"];
                authUser.avatar = [respose.data objectForKey:@"profile_image_url"];
                
                NSString *genderStr = [[respose.data objectForKey:@"gender"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                if ([genderStr isEqualToString:@"男"]) {
                    authUser.gender = @"male";
                }
                else if([genderStr isEqualToString:@"女"]) {
                    authUser.gender = @"female";
                }
                else {
                    authUser.gender = @"";
                }
                
                authUser.gender = [respose.data objectForKey:@"gender"];
                NSLog(@"%@", authUser.basicDict);
                [VNHTTPRequestManager loginWithUser:authUser completion:^(BOOL succeed, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (succeed) {
                        [VNUtility showHUDText:@"登录成功!" forView:self.view];
                        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:isLogin];
                        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:VNLoginDate];
                        if (![[NSUserDefaults standardUserDefaults] objectForKey:VNIsWiFiAutoPlay]) {
                            [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:VNIsWiFiAutoPlay];
                            //[[NSUserDefaults standardUserDefaults] synchronize];
                        }
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [[NSNotificationCenter defaultCenter]postNotificationName:VNLoginNotification object:nil];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    else {
                        [VNUtility showHUDText:@"登录失败!" forView:self.view];
                    }
                }];
            }];
        }
    });
}

- (IBAction)dismiss:(id)sender {
    //VNTabBarViewController *tabbarCtl = (VNTabBarViewController *)self.window.rootViewController;
    if (_controllerType==SourceVCTypeMineProfile) {
        [[NSNotificationCenter defaultCenter] postNotificationName:VNSignOutNotification object:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - WXApiDelegate

-(void)onResp:(BaseResp *)resp
{
    if([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *authResp = (SendAuthResp *)resp;
        if (authResp.errCode) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"授权失败" message:[NSString stringWithFormat:@"错误码：%d", authResp.errCode] delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
            [alert show];
            return;
        }
        else {
            if (authResp.code && ![authResp.code isEqualToString:@""]) {
//               https://api.weixin.qq.com/sns/oauth2/access_token?appid=APPID&secret=SECRET&code=CODE&grant_type=authorization_code
                NSString *URLStr = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code", WXAppkey, WXAppScrectkey, authResp.code] ;
                NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
                [request setURL:[NSURL URLWithString:URLStr]];
                [request setHTTPMethod:@"GET"];
                NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                NSError *error = nil;
                NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:returnData options:kNilOptions error:&error];
                NSLog(@"%@", responseObject);
                VNWeixinCodeResponse *weixinCodeResponse = [[VNWeixinCodeResponse alloc] initWithDict:responseObject];
//                https://api.weixin.qq.com/sns/userinfo?access_token=ACCESS_TOKEN&openid=OPENID
                
                URLStr = [NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@", weixinCodeResponse.access_token, weixinCodeResponse.openid] ;
                [request setURL:[NSURL URLWithString:URLStr]];
                [request setHTTPMethod:@"GET"];
                returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                responseObject = [NSJSONSerialization JSONObjectWithData:returnData options:kNilOptions error:&error];
                NSLog(@"%@", responseObject);
                VNAuthUser *authUser = [[VNAuthUser alloc] initWithDict:@{}];
                authUser.openid = [@"14" stringByAppendingString:[responseObject objectForKey:@"openid"]];
                authUser.nickname = [responseObject objectForKey:@"nickname"];
                [VNHTTPRequestManager loginWithUser:authUser completion:^(BOOL succeed, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (succeed) {
                        [VNUtility showHUDText:@"登录成功!" forView:self.view];
                        [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:isLogin];
                        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:VNLoginDate];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                    else {
                        [VNUtility showHUDText:@"登录失败!" forView:self.view];
                    }
                }];
            }
        }
    }
}

- (IBAction)doLogin:(UIButton *)sender {
    
    //邮箱不能为空
    if ([self.emailTF.text isEqualToString:@""]) {

        [VNUtility showHUDText:@"邮箱不能为空~" forView:self.view];
        return;
    }
    
    //密码格式验证
    if (![VNUtility validatePasswd:self.passwdTF.text]) {
        
        [VNUtility showHUDText:@"密码为长度6到20位字符或数字~" forView:self.view];
        return;
    }
    
    //邮箱格式正确
    if (![VNUtility validateEmail:self.emailTF.text]) {
        
        [VNUtility showHUDText:@"请输入正确邮箱~" forView:self.view];
        return;
    }
    
    //发起登录请求 post
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [VNHTTPRequestManager loginWithEmail:self.emailTF.text passwd:[self.passwdTF.text md5] completion:^(BOOL success, NSError *err) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [VNUtility showHUDText:@"登录成功!" forView:self.view];
                    
                    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:isLogin];
                    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:VNLoginDate];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [[NSNotificationCenter defaultCenter]postNotificationName:VNLoginNotification object:nil];
                    [self dismissViewControllerAnimated:YES completion:nil];
                }else {
                    if ([err.domain isEqualToString:VNCustomErrorDomain]) {
                        if (err.code == VNInvalidUserErrorCode) {
                            [VNUtility showHUDText:@"非注册用户，先注册吧~" forView:self.view];
                            return ;
                        }
                        if (err.code == VNWrongPasswdErrorCode) {
                            [VNUtility showHUDText:@"密码错误~" forView:self.view];
                            return ;
                        }
                    }else {
                        [VNUtility showHUDText:@"登录失败!" forView:self.view];
                    }
                }
            });
        }];
    });
    
}

- (IBAction)doRegister:(UIButton *)sender {
    
    VNRegisterViewController *registerViewCtl = [[VNRegisterViewController alloc] init];
    [self.navigationController pushViewController:registerViewCtl animated:YES];
}

- (IBAction)doForgetPasswd:(UIButton *)sender {

    VNForgetPasswdViewController *forgetPasswdCtl = [[VNForgetPasswdViewController alloc] init];
    [self.navigationController pushViewController:forgetPasswdCtl animated:YES];
}

- (IBAction)doHideKeyboard:(UIControl *)sender {
    [self hideKeyboard];
}

- (void)hideKeyboard
{
    [self.emailTF resignFirstResponder];
    [self.passwdTF resignFirstResponder];
    [UIView animateWithDuration:0.3f animations:^{
        CGRect frame = self.view.frame;
        frame.origin.y = 0;
        self.view.frame = frame;
    }];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == self.emailTF) {
        [UIView animateWithDuration:0.3f animations:^{
            CGRect frame = self.view.frame;
            frame.origin.y = -150;
            self.view.frame = frame;
        }];
    }else if (textField == self.passwdTF) {
        [UIView animateWithDuration:0.3f animations:^{
            CGRect frame = self.view.frame;
            frame.origin.y = -150;
            self.view.frame = frame;
        }];
    }
    return YES;
}

@end
