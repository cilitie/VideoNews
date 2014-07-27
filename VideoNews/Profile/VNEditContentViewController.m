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
    [self.contentTextView setText:self.initialStr];
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
    NSString *str = self.contentTextView.text;
    NSMutableString *contentStr = [[NSMutableString alloc] init];
    [contentStr setString:str];
    CFStringTrimWhitespace((CFMutableStringRef)contentStr);
    
    NSDictionary *profileInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNProfileInfo];
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionaryWithDictionary:profileInfo];
    if ([self.title isEqualToString:@"昵称"]) {
        [tempDict setObject:contentStr forKey:@"name"];
    }
    else if ([self.title isEqualToString:@"地区"]) {
        [tempDict setObject:contentStr forKey:@"location"];
    }
    else if ([self.title isEqualToString:@"描述"]) {
        [tempDict setObject:contentStr forKey:@"description"];
    }
    [[NSUserDefaults standardUserDefaults] setObject:tempDict forKey:VNProfileInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.contentTextView resignFirstResponder];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
