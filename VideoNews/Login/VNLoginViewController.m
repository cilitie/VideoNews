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

@interface VNLoginViewController () <WXApiDelegate>

- (IBAction)wechatLogin:(id)sender;
- (IBAction)weiboLogin:(id)sender;
- (IBAction)qqLogin:(id)sender;
- (IBAction)dismiss:(id)sender;

@end

@implementation VNLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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

- (IBAction)wechatLogin:(id)sender {
    //构造SendAuthReq结构体
    SendAuthReq *req =[[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo" ;
    req.state = @"wechat_VideoNews";
    //第三方向微信终端发送一个SendAuthReq消息结构
    [WXApi sendReq:req];
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
                authUser.gender = [respose.data objectForKey:@"gender"];
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
                        [[NSUserDefaults standardUserDefaults] synchronize];
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

@end
