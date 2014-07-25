//
//  VNEditContentViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-25.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNEditContentViewController.h"

@interface VNEditContentViewController ()

@property (weak, nonatomic) IBOutlet UIButton *saveBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UILabel *navTitleLabel;
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;

- (IBAction)pop:(id)sender;
- (IBAction)save:(id)sender;

@end

@implementation VNEditContentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.saveBtn.layer.cornerRadius = 5.0;
    self.saveBtn.layer.masksToBounds = YES;
    
    self.cancelBtn.layer.cornerRadius = 5.0;
    self.cancelBtn.layer.masksToBounds = YES;
    self.cancelBtn.layer.borderWidth = 1.0;
    self.cancelBtn.layer.borderColor = [[UIColor colorWithRGBValue:0xcacaca] CGColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navTitleLabel.text = self.title;
    [self.contentTextView becomeFirstResponder];
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
    [self.contentTextView resignFirstResponder];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)save:(id)sender {
}

@end
