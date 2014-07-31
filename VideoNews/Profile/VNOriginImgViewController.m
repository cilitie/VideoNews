//
//  VNOriginImgViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-24.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNOriginImgViewController.h"

@interface VNOriginImgViewController ()

@property (strong, nonatomic) UIImageView *originImgView;

- (IBAction)tap:(UITapGestureRecognizer *)sender;

@end

@implementation VNOriginImgViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.originImgView = [[UIImageView alloc] init];
    [self.originImgView setImageWithURL:[NSURL URLWithString:self.imgURL] placeholderImage:[UIImage imageNamed:@"600-600pic"]];
    [self.originImgView sizeToFit];
    self.originImgView.center = self.view.center;
    [self.view addSubview:self.originImgView];
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

- (IBAction)tap:(UITapGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
