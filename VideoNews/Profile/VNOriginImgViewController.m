//
//  VNOriginImgViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-24.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNOriginImgViewController.h"

@interface VNOriginImgViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *originImgView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *originImgViewHeightLC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *originImgViewWidthLC;

- (IBAction)tap:(UITapGestureRecognizer *)sender;

@end

@implementation VNOriginImgViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.originImgView setImageWithURL:[NSURL URLWithString:self.imgURL] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    [self.originImgView sizeToFit];
    self.originImgViewWidthLC.constant = CGRectGetWidth(self.originImgView.bounds);
    self.originImgViewHeightLC.constant = CGRectGetHeight(self.originImgView.bounds);
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
    [self dismissViewControllerAnimated:NO completion:nil];
}
@end
