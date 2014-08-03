//
//  VNVideoShareViewController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//
// 草稿中文件的保存
// 路径 cache/VideoFiles/Draft/时间戳/时间戳.mp4 视频文件
// 路径 cache/VideoFiles/Draft/时间戳/时间戳.jpg 封面文件
// 路径 cache/VideoFiles/Draft/时间戳/时间戳     封面时间记录文件

#import "VNVideoShareViewController.h"
#import "VNAppDelegate.h"
#import "VNTabBarViewController.h"
#import "UMSocial.h"
#import "WXApi.h"

@interface VNVideoShareViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, copy) NSString *videoPath;
@property (nonatomic, strong) UIImage *coverImg;


@property (nonatomic, strong) UITextField *titleTF;
@property (nonatomic, strong) UITextField *tagsTF;

@property (nonatomic, assign) BOOL shareSina;
@property (nonatomic, assign) BOOL shareWeixin;

@end

@implementation VNVideoShareViewController

@synthesize fromDraft, coverTime;

#define screenH ([[UIScreen mainScreen] bounds].size.height)

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

    self.view.backgroundColor = [UIColor colorWithRGBValue:0xE1E1E1];
    
    //initialize top bar view.
    UIView *topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 64)];
    topView.backgroundColor = [UIColor colorWithRGBValue:0xF1F1F1];
    
    UIButton *backBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 20, 60, 44)];
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
    
    if (!fromDraft) {
        
        UIButton *draftBtn = [[UIButton alloc] initWithFrame:CGRectMake(260, 20, 60, 44)];

        [draftBtn setImage:[UIImage imageNamed:@"save_draft"] forState:UIControlStateNormal];
        [draftBtn setImage:[UIImage imageNamed:@"blank"] forState:UIControlStateSelected];
        
        [draftBtn setTitle:@"" forState:UIControlStateNormal];
        [draftBtn setTitle:@"继续" forState:UIControlStateSelected];
        [draftBtn setTitleColor:[UIColor colorWithRGBValue:0xCE2426] forState:UIControlStateSelected];
        
        [draftBtn addTarget:self action:@selector(doSaveToDraft:) forControlEvents:UIControlEventTouchUpInside];
        [draftBtn setSelected:NO];
        
        [topView addSubview:draftBtn];
    }
    

    [self.view addSubview:topView];
    
    UIImageView *videoCoverView = [[UIImageView alloc] initWithFrame:CGRectMake(120, 85, 80, 80)];
    videoCoverView.backgroundColor = [UIColor clearColor];
    videoCoverView.image = self.coverImg;
    [self.view addSubview:videoCoverView];
    
    [self.view addSubview:self.titleTF];
    [self.view addSubview:self.tagsTF];
    
    BOOL isWeiXinInstalled = YES;
    self.shareWeixin = YES;
    if (![WXApi isWXAppInstalled]) {
        isWeiXinInstalled = NO;
        self.shareWeixin = NO;
    }
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(10, 300, 300, 90)];
    bgView.backgroundColor = [UIColor whiteColor];
    bgView.layer.cornerRadius = 5;
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 44, 300, 1)];
    line.backgroundColor = [UIColor colorWithRGBValue:0xE1E1E1];
    [bgView addSubview:line];
    
    UILabel *shareWeiboLbl = [[UILabel alloc] initWithFrame:CGRectMake(28, 10, 90, 25)];
    shareWeiboLbl.backgroundColor = [UIColor clearColor];
    shareWeiboLbl.textColor = [UIColor colorWithRed:58/255.0 green:57/255.0 blue:62/255.0 alpha:1];
    shareWeiboLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:13];
    shareWeiboLbl.text = @"分享到微博";
    [bgView addSubview:shareWeiboLbl];
    
    UISwitch *shareWeiboSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(240, 5, 50, 30)];
    shareWeiboSwitch.tag = 9100;
    [shareWeiboSwitch setOn:YES];
    self.shareSina = YES;
    if (![UMSocialAccountManager isOauthWithPlatform:UMShareToSina]) {
        [shareWeiboSwitch setOn:NO];
        self.shareSina = NO;
    }
    [shareWeiboSwitch addTarget:self action:@selector(handleSwitch:) forControlEvents:UIControlEventValueChanged];
    [bgView addSubview:shareWeiboSwitch];
    
    UILabel *shareWeixinLbl = [[UILabel alloc] initWithFrame:CGRectMake(28, 55, 90, 25)];
    shareWeixinLbl.backgroundColor = [UIColor clearColor];
    shareWeixinLbl.textColor = [UIColor colorWithRed:58/255.0 green:57/255.0 blue:62/255.0 alpha:1];
    shareWeixinLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:13];
    shareWeixinLbl.text = @"分享到朋友圈";
    [bgView addSubview:shareWeixinLbl];
    
    UISwitch *shareWeiXinSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(240, 50, 50, 30)];
    shareWeiXinSwitch.tag = 9101;
    [shareWeiXinSwitch setOn:YES];
    if (!isWeiXinInstalled) {
        [shareWeiXinSwitch setOn:NO];
    }
    [shareWeiXinSwitch addTarget:self action:@selector(handleSwitch:) forControlEvents:UIControlEventValueChanged];
    [bgView addSubview:shareWeiXinSwitch];
    
    [self.view addSubview:bgView];
    
    CGFloat y = 485;
    if (screenH == 480) {
        y = 430;
    }
    
    UIButton *submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(10, y, 300, 45)];
    submitBtn.backgroundColor = [UIColor colorWithRGBValue:0xCE2426];
    [submitBtn.titleLabel setFont:[UIFont fontWithName:@"STHeitiSC-Light" size:16]];
    [submitBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [submitBtn setTitle:@"完成" forState:UIControlStateNormal];
    submitBtn.layer.cornerRadius = 5;
    submitBtn.clipsToBounds = YES;
    [submitBtn addTarget:self action:@selector(doSubmit) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:submitBtn];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [self.view addGestureRecognizer:tapGesture];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

- (void)dealloc
{
    NSLog(@"dealloc ..... :%s",__FUNCTION__);
}

#pragma mark - UserInteractionMethods

- (void)doPopBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doSaveToDraft:(UIButton *)sender
{
    
    if (!sender.selected) {
        
        double timeInterval = [NSDate timeIntervalSinceReferenceDate];

        NSString *filePath = [VNUtility getNSCachePath:[NSString stringWithFormat:@"VideoFiles/Draft/%lf",timeInterval]];
        
        BOOL _isDir;
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&_isDir]){
            if (![[NSFileManager defaultManager] createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil]) {
                
            }
        }
        
        NSString *videoFilePath = [NSString stringWithFormat:@"%@/%lf.mp4",filePath,timeInterval];
        NSString *coverFilePath = [NSString stringWithFormat:@"%@/%lf.jpg",filePath,timeInterval];
        NSString *coverTimePointFilePath = [NSString stringWithFormat:@"%@/%lf",filePath,timeInterval];
        
        NSError *err;
        
        NSString *coverTimeString = [NSString stringWithFormat:@"%f",self.coverTime];
        [coverTimeString writeToFile:coverTimePointFilePath atomically:YES encoding:NSUTF8StringEncoding error:&err];
        
        NSData *data = UIImageJPEGRepresentation(self.coverImg, 1);
        [data writeToFile:coverFilePath atomically:YES];

        [[NSFileManager defaultManager] copyItemAtPath:self.videoPath toPath:videoFilePath error:&err];
        
        if (!err) {
            
            MBProgressHUD *hud = [[MBProgressHUD alloc] init];
            hud.labelText = @"已存草稿";
            [self.view addSubview:hud];
            [hud show:YES];
            [hud hide:YES afterDelay:1];
            
            sender.selected = YES;
        }
        
    }else {
        
        [self clearTempVideos];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ClearVideoClipsNotification" object:nil userInfo:nil];

        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)handleSwitch:(UISwitch *)sw
{
    if (sw.tag == 9100) {
        //sina
        self.shareSina = sw.isOn;
        
    }else if (sw.tag == 9101) {
        //wechat
        self.shareWeixin = sw.isOn;
    }
}

- (void)doSubmit
{
    
    NSString *titleText = [self.titleTF.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!titleText || titleText.length == 0 || [titleText isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"亲~ 标题一定要有内容哦~" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    NSString *tagsText = [self.tagsTF.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (!tagsText) {
        tagsText = @"";
    }
 
    VNAppDelegate *appDelegate = (VNAppDelegate *)[[UIApplication sharedApplication] delegate];
    VNTabBarViewController *tabbarCtl = (VNTabBarViewController *)appDelegate.window.rootViewController;
    tabbarCtl.selectedIndex = 4;
    
    NSDictionary *userInfoDic = @{@"title":titleText,@"tags":tagsText,@"coverTime":[NSNumber numberWithFloat:self.coverTime],@"videoPath":self.videoPath,@"isSinaOn":[NSNumber numberWithBool:self.shareSina],@"isWeChatOn":[NSNumber numberWithBool:self.shareWeixin],@"isFromDraft":[NSNumber numberWithBool:self.fromDraft],@"coverImg":self.coverImg};
    
    __weak VNVideoShareViewController *weakSelf = self;
    
    [weakSelf dismissViewControllerAnimated:YES completion:^{
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [[NSNotificationCenter defaultCenter] postNotificationName:VNMineProfileUploadVideoNotifiction object:nil userInfo:userInfoDic];
            
        });
    }];
    

    
}

/**
 *  @description: clear temp videos in temp directory.
 */
- (void)clearTempVideos
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *videoFilePath = [VNUtility getNSCachePath:@"VideoFiles"];
    
    NSString *filePath = [videoFilePath stringByAppendingPathComponent:@"Clips"];
    
    NSArray *arr = [fm contentsOfDirectoryAtPath:filePath error:nil];
    
    for (NSString *dir in arr) {
        [fm removeItemAtPath:[filePath stringByAppendingPathComponent:dir] error:nil];
    }
    
    filePath = [videoFilePath stringByAppendingPathComponent:@"Temp"];
    
    arr = [fm contentsOfDirectoryAtPath:filePath error:nil];
    
    for (NSString *dir in arr) {
        [fm removeItemAtPath:[filePath stringByAppendingPathComponent:dir] error:nil];
    }
    
}

#pragma mark - UIGestureRecognizerDelgate

- (void)handleTap:(UITapGestureRecognizer *)gesture
{
    [self.titleTF resignFirstResponder];
    [self.tagsTF resignFirstResponder];
}

@end
