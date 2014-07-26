//
//  VNVideoShareViewController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNVideoShareViewController.h"
#import "WXApi.h"

@interface VNVideoShareViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, strong) UIImage *coverImg;


@property (nonatomic, strong) UITextField *titleTF;
@property (nonatomic, strong) UITextField *tagsTF;


@end

@implementation VNVideoShareViewController

#pragma mark - Initialization

- (UITextField *)titleTF
{
    if (!_titleTF) {
        
        _titleTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 175, 300, 45)];
        [self customizeTextField:_titleTF WithPlaceholderText:@"添加标题"];
        
    }
    return _titleTF;
}

- (UITextField *)tagsTF
{
    if (!_tagsTF) {
        _tagsTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 230, 300, 45)];
        [self customizeTextField:_tagsTF WithPlaceholderText:@"添加标签"];
    }
    return _tagsTF;
}

- (void)customizeTextField:(UITextField *)tf WithPlaceholderText:(NSString *)text
{
    tf.layer.cornerRadius = 5;
    tf.backgroundColor = [UIColor whiteColor];
    
    [tf setLeftViewMode:UITextFieldViewModeAlways];
    [tf setLeftView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, 22, 68)]];
    
    UIFont *font = [UIFont fontWithName:@"STHeitiSC-Light" size:13];
    UIColor *color = [UIColor colorWithRed:58/255.0 green:57/255.0 blue:62/255.0 alpha:1];
    tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:text attributes:@{NSForegroundColorAttributeName: color,NSFontAttributeName:font}];
}

#pragma mark - ViewLifeCycle

- (id)initWithVideoPath:(NSString *)path andCoverImage:(UIImage *)img
{
    self = [super init];
    if (self) {
        
        self.videoPath = path;
        self.coverImg = img;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor colorWithRGBValue:0x989797];
    
    //initialize top bar view.
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    topView.backgroundColor = [UIColor colorWithRGBValue:0xF1F1F1];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 45, 44)];
    [backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [backBtn setImage:[UIImage imageNamed:@"back_a"] forState:UIControlStateSelected];
    [backBtn addTarget:self action:@selector(doPopBack) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:backBtn];
    
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(50, 20, 220, 44)];
    titleLbl.backgroundColor = [UIColor clearColor];
    titleLbl.text = @"分享";
    titleLbl.textColor = [UIColor colorWithRGBValue:0xCE2426];
    titleLbl.textAlignment = NSTextAlignmentCenter;
    titleLbl.font = [UIFont fontWithName:@"STHeitiSC-Medium" size:17];
    [topView addSubview:titleLbl];
    
    UIButton *draftBtn = [[UIButton alloc] initWithFrame:CGRectMake(275, 20, 45, 44)];
    [draftBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
    [draftBtn setImage:[UIImage imageNamed:@"back_a"] forState:UIControlStateSelected];
    [draftBtn addTarget:self action:@selector(doSaveToDraft) forControlEvents:UIControlEventTouchUpInside];
    [topView addSubview:draftBtn];
    
    [self.view addSubview:topView];
    
    UIImageView *videoCoverView = [[UIImageView alloc] initWithFrame:CGRectMake(120, 85, 80, 80)];
    videoCoverView.backgroundColor = [UIColor clearColor];
    videoCoverView.image = self.coverImg;
    [self.view addSubview:videoCoverView];
    
    [self.view addSubview:self.titleTF];
    [self.view addSubview:self.tagsTF];
    
    BOOL isWeiXinInstalled = YES;
    if (![WXApi isWXAppInstalled]) {
        isWeiXinInstalled = NO;
    }
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(10, 300, 300, 90)];
    bgView.backgroundColor = [UIColor whiteColor];
    bgView.layer.cornerRadius = 5;
    if (isWeiXinInstalled) {
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 44, 300, 2)];
        line.backgroundColor = [UIColor lightGrayColor];
        [bgView addSubview:line];
    }
    
    UILabel *shareWeiboLbl = [[UILabel alloc] initWithFrame:CGRectMake(28, 10, 90, 25)];
    shareWeiboLbl.backgroundColor = [UIColor clearColor];
    shareWeiboLbl.textColor = [UIColor colorWithRed:58/255.0 green:57/255.0 blue:62/255.0 alpha:1];
    shareWeiboLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:13];
    shareWeiboLbl.text = @"分享到微博";
    [bgView addSubview:shareWeiboLbl];
    
    UISwitch *shareWeiboSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(240, 5, 50, 30)];
    [shareWeiboSwitch setOn:YES];
    [bgView addSubview:shareWeiboSwitch];
    
    UILabel *shareWeixinLbl = [[UILabel alloc] initWithFrame:CGRectMake(28, 55, 90, 25)];
    shareWeixinLbl.backgroundColor = [UIColor clearColor];
    shareWeixinLbl.textColor = [UIColor colorWithRed:58/255.0 green:57/255.0 blue:62/255.0 alpha:1];
    shareWeixinLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:13];
    shareWeixinLbl.text = @"分享到朋友圈";
    [bgView addSubview:shareWeixinLbl];
    
    UISwitch *shareWeiXinSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(240, 50, 50, 30)];
    [shareWeiXinSwitch setOn:YES];
    if (!isWeiXinInstalled) {
        [shareWeiXinSwitch setOn:NO];
        [shareWeiXinSwitch setEnabled:NO];
    }
    [bgView addSubview:shareWeiXinSwitch];
    
    [self.view addSubview:bgView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

#pragma mark - UserInteractionMethods

- (void)doPopBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doSaveToDraft
{
    
}

#pragma mark - UIGestureRecognizerDelgate

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    [self.titleTF resignFirstResponder];
    [self.tagsTF resignFirstResponder];
}

@end
