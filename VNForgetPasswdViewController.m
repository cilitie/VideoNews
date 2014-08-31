//
//  VNForgetPasswdViewController.m
//  VideoNews
//
//  Created by zhangxue on 14-8-29.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNForgetPasswdViewController.h"

@interface VNForgetPasswdViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *emailTF;
@property (nonatomic, strong) UIButton *resetBtn;

@end

@implementation VNForgetPasswdViewController

#pragma mark - Initialization

- (UITextField *)emailTF
{
    if (!_emailTF) {
        _emailTF = [[UITextField alloc] initWithFrame:CGRectMake(20, 150, 280, 35)];
        _emailTF.keyboardType = UIKeyboardTypeEmailAddress;
        _emailTF.returnKeyType = UIReturnKeyGo;
        _emailTF.placeholder = @"邮箱";
    }
    return _emailTF;
}

- (UIButton *)resetBtn
{
    if (!_resetBtn) {
        _resetBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 200, 280, 40)];
        _resetBtn.backgroundColor = [UIColor colorWithRGBValue:0xCE2426];
        _resetBtn.titleLabel.textColor = [UIColor whiteColor];
        _resetBtn.layer.cornerRadius = 2.5;
        [_resetBtn setTitle:@"重置" forState:UIControlStateNormal];
        [_resetBtn addTarget:self action:@selector(doResetPasswd) forControlEvents:UIControlEventTouchUpInside];
    }
    return _resetBtn;
}

#pragma mark - View Life Cycle

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
    
    self.title = @"密码重置";
    
    self.view.backgroundColor = [UIColor colorWithRed:226/255.0 green:226/255.0 blue:226/255.0 alpha:1];

    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 44)];
    [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"back_a"] forState:UIControlStateSelected];
    [backBtn addTarget:self action:@selector(doPopBack) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setShowsTouchWhenHighlighted:TRUE];
    UIBarButtonItem * backBtnItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = backBtnItem;
    
    UILabel *descLbl = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 280, 50)];
    descLbl.backgroundColor = [UIColor clearColor];
    descLbl.textColor = [UIColor darkGrayColor];
    descLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:12];
    descLbl.numberOfLines = 0;
    descLbl.textAlignment = NSTextAlignmentCenter;
    descLbl.text = @"请在下面输入你的邮箱地址，我们会发送一个重置密码的链接。";
    [self.view addSubview:descLbl];
    
    [self initTextField:self.emailTF];

    [self.view addSubview:self.emailTF];
    [self.view addSubview:self.resetBtn];
    
}

- (void)initTextField:(UITextField *)textF
{
    textF.backgroundColor = [UIColor whiteColor];
    textF.textColor = [UIColor darkGrayColor];
    textF.font = [UIFont systemFontOfSize:15];
    [textF setLeftViewMode:UITextFieldViewModeAlways];
    [textF setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 35)]];
    textF.layer.cornerRadius = 2.5;
    textF.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UserInteractionMethods

- (void)doPopBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doResetPasswd
{
    //邮箱不能为空
    if ([self.emailTF.text isEqual:@""]) {
        [VNUtility showHUDText:@"邮箱不能为空" forView:self.view];
        return;
    }
    
    //邮箱格式正确
    if (![VNUtility validateEmail:self.emailTF.text]) {
        
        [VNUtility showHUDText:@"请输入正确邮箱~" forView:self.view];
        return;
    }
    
    //发起重置请求
<<<<<<< HEAD
    self.resetBtn.userInteractionEnabled=NO;
=======
    self.emailTF.userInteractionEnabled = NO;
    self.resetBtn.userInteractionEnabled = NO;
    
>>>>>>> FETCH_HEAD
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [VNHTTPRequestManager resetPasswdWithEmail:self.emailTF.text completion:^(BOOL success, NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^{

                if (success) {
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"已经向该邮箱发了修改链接" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                    [alert show];
                    
                    [self.navigationController popViewControllerAnimated:YES];
                }else {
<<<<<<< HEAD
                    _resetBtn.userInteractionEnabled=YES;
                    [VNUtility showHUDText:@"重置密码邮件发送失败.." forView:self.view];
=======
                    
                    if ([err.domain isEqualToString:VNCustomErrorDomain]) {
                        if (err.code == VNResetPasswdFailed) {
                            [VNUtility showHUDText:@"没有这个用户" forView:self.view];
                            return ;
                        }
                    }else {
                        [VNUtility showHUDText:@"发送邮件失败!" forView:self.view];
                    }
>>>>>>> FETCH_HEAD
                }
                
                self.emailTF.userInteractionEnabled = YES;
                self.resetBtn.userInteractionEnabled = YES;
            });
        }];
    });
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self doResetPasswd];
    return YES;
}

@end
