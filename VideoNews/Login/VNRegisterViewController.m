//
//  VNRegisterViewController.m
//  VideoNews
//
//  Created by zhangxue on 14-8-29.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNRegisterViewController.h"

@interface VNRegisterViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *nicknameTF;
@property (nonatomic, strong) UITextField *emailTF;
@property (nonatomic, strong) UITextField *passwdTF;
@property (nonatomic, strong) UITextField *passwdConfirmTF;
@property (nonatomic, strong) UIButton *registerBtn;

@end

@implementation VNRegisterViewController

#pragma mark - Initialization

- (UITextField *)nicknameTF
{
    if (!_nicknameTF) {
        _nicknameTF = [[UITextField alloc] initWithFrame:CGRectMake(20, 90, 280, 35)];
        _nicknameTF.returnKeyType= UIReturnKeyNext;
        _nicknameTF.placeholder = @"昵称";
    }
    return _nicknameTF;
}

- (UITextField *)emailTF
{
    if (!_emailTF) {
        _emailTF = [[UITextField alloc] initWithFrame:CGRectMake(20, 140, 280, 35)];
        _emailTF.keyboardType = UIKeyboardTypeEmailAddress;
        _emailTF.returnKeyType = UIReturnKeyNext;
        _emailTF.placeholder = @"邮箱";
    }
    return _emailTF;
}

- (UITextField *)passwdTF
{
    if (!_passwdTF) {
        _passwdTF = [[UITextField alloc] initWithFrame:CGRectMake(20, 190, 280, 35)];
        _passwdTF.secureTextEntry = YES;
        _passwdTF.returnKeyType = UIReturnKeyNext;
        _passwdTF.placeholder = @"密码(6-20位字符或数字)";
    }
    return _passwdTF;
}

- (UITextField *)passwdConfirmTF
{
    if (!_passwdConfirmTF) {
        _passwdConfirmTF = [[UITextField alloc] initWithFrame:CGRectMake(20, 240, 280, 35)];
        _passwdConfirmTF.secureTextEntry = YES;
        _passwdConfirmTF.returnKeyType = UIReturnKeyGo;
        _passwdConfirmTF.placeholder = @"密码确认";
    }
    return _passwdConfirmTF;
}

- (UIButton *)registerBtn
{
    if (!_registerBtn) {
        _registerBtn = [[UIButton alloc] initWithFrame:CGRectMake(20, 290, 280, 40)];
        _registerBtn.backgroundColor = [UIColor colorWithRGBValue:0xCE2426];
        _registerBtn.titleLabel.textColor = [UIColor whiteColor];
        _registerBtn.layer.cornerRadius = 2.5;
        [_registerBtn setTitle:@"注册" forState:UIControlStateNormal];
        [_registerBtn addTarget:self action:@selector(doRegister) forControlEvents:UIControlEventTouchUpInside];
    }
    return _registerBtn;
}

#pragma mark - View Life Cycle

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
    
    self.title = @"注册";
    
    UIControl *control = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    control.backgroundColor = [UIColor colorWithRed:226/255.0 green:226/255.0 blue:226/255.0 alpha:1];
    [control addTarget:self
                action:@selector(hideKeyboard) forControlEvents:UIControlEventTouchDown];
    self.view = control;
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 44)];
    [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"back_a"] forState:UIControlStateSelected];
    [backBtn addTarget:self action:@selector(doPopBack) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setShowsTouchWhenHighlighted:TRUE];
    UIBarButtonItem * backBtnItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = backBtnItem;
    
    [self initTextField:self.nicknameTF];
    [self initTextField:self.emailTF];
    [self initTextField:self.passwdTF];
    [self initTextField:self.passwdConfirmTF];
    
    [self.view addSubview:self.nicknameTF];
    [self.view addSubview:self.emailTF];
    [self.view addSubview:self.passwdTF];
    [self.view addSubview:self.passwdConfirmTF];
    
    [self.view addSubview:self.registerBtn];
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

- (void)hideKeyboard
{
    [self.nicknameTF resignFirstResponder];
    [self.emailTF resignFirstResponder];
    [self.passwdTF resignFirstResponder];
    [self.passwdConfirmTF resignFirstResponder];
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

- (void)doRegister
{
    //昵称不能为空
    if ([self.nicknameTF.text isEqual:@""]) {
        [VNUtility showHUDText:@"昵称不能为空" forView:self.view];
        return;
    }
    
    //邮箱不能为空
    if ([self.emailTF.text isEqual:@""]) {
        [VNUtility showHUDText:@"邮箱不能为空" forView:self.view];
        return;
    }
    
    //密码不能为空
    if ([self.passwdTF.text isEqual:@""]) {
        [VNUtility showHUDText:@"密码不能为空" forView:self.view];
        return;
    }
    
    //确认密码不能为空
    if ([self.passwdConfirmTF.text isEqual:@""]) {
        [VNUtility showHUDText:@"确认密码不能为空" forView:self.view];
        return;
    }
    
    //密码和确认密码一致
    if (![self.passwdTF.text isEqualToString:self.passwdConfirmTF.text]) {
        [VNUtility showHUDText:@"密码和确认密码不一致~" forView:self.view];
        return;
    }
    
    //检查昵称符合规范格式
    NSRange urgentRange = [self.nicknameTF.text rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"~￥#&*<>《》()[]{}【】^@/￡¤￥|§¨「」『』￠￢￣~@#￥&*（）——+|《》$€;,.，。:：、？?!！\"“”'% "]];
    if (urgentRange.location != NSNotFound)
    {
        [VNUtility showHUDText:@"昵称只包含字符、数字、下划线" forView:self.view];
        return;
    }
    
    NSInteger length = 0;
    for(int i=0; i< [self.nicknameTF.text length];i++){
        int a = [self.nicknameTF.text characterAtIndex:i];
        if( a >= 0x4e00 && a <= 0x9fff)
            length += 2;
        else length += 1;
    }
    if (length < 2) {
        
        [VNUtility showHUDText:@"昵称过短(至少1个中文字符或2个英文字符)" forView:self.view];
        return;
    }else if(length > 20) {
        
        [VNUtility showHUDText:@"昵称过长(至多10个中文字符或20个英文字符)" forView:self.view];

        return;
    }
    
    //邮箱格式正确
    if (![VNUtility validateEmail:self.emailTF.text]) {
        
        [VNUtility showHUDText:@"请输入正确邮箱~" forView:self.view];
        return;
    }
    
    //密码格式验证
    if (![VNUtility validatePasswd:self.passwdTF.text]) {
        
        [VNUtility showHUDText:@"密码为长度6到20位字符或数字~" forView:self.view];
        return;
    }
    
    //密码格式验证
    if (![VNUtility validatePasswd:self.passwdConfirmTF.text]) {
        
        [VNUtility showHUDText:@"验证密码为长度6到20位字符或数字~" forView:self.view];
        return;
    }
    
    //发起注册请求
    _registerBtn.userInteractionEnabled=NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        [VNHTTPRequestManager registerWithNickname:self.nicknameTF.text Email:self.emailTF.text passwd:[self.passwdTF.text md5] completion:^(BOOL success, NSError *err) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"已经向邮箱发送了激活链接，请激活后登录~" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
                    [alert show];
                    
                    [self.navigationController popViewControllerAnimated:YES];
                }else {
                    _registerBtn.userInteractionEnabled=YES;
                    [VNUtility showHUDText:@"该账号已存在，请直接登录!" forView:self.view];
                }
            });
        }];
    });
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.nicknameTF) {
        [self.emailTF becomeFirstResponder];
    }else if (textField == self.emailTF) {
        [self.passwdTF becomeFirstResponder];
    }else if (textField == self.passwdTF) {
        [self.passwdConfirmTF becomeFirstResponder];
    }else if (textField == self.passwdConfirmTF){
        [self doRegister];
    }
    return YES;
}

@end
