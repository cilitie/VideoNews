//
//  VNAboutViewController.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-8-19.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNAboutViewController.h"

@interface VNAboutViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *logoImage;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UILabel *copyrightLabel;

@end

@implementation VNAboutViewController

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
    _contentLabel.text=@"       时尚拍由北京晓林网络科技有限公司于2014年创建，是一款微视频分享软件，旨在打造新型的时尚交流社区。";
    //我们鼓励用户分享日常穿搭和造型想法的相关时尚信息。同时时尚拍也为用户提供了一个交流时尚观点的平台。这里对于有个性的人而言是最好的展示自己的舞台！";
    _copyrightLabel.text=@"Copyright@2014\n北京晓林网络科技有限公司";
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)pop:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
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

@end
