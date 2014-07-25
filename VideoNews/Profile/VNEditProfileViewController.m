//
//  VNEditProfileViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-25.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNEditProfileViewController.h"
#import "VNEditProfileTableViewCell.h"
#import "VNEditContentViewController.h"

@interface VNEditProfileViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *saveBtn;
@property (weak, nonatomic) IBOutlet UITableView *editTableView;
@property (strong, nonatomic) NSDictionary *profileInfo;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end

@implementation VNEditProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.cancelBtn.layer.cornerRadius = 5.0;
    self.cancelBtn.layer.masksToBounds = YES;
    self.cancelBtn.layer.borderWidth = 1.0;
    self.cancelBtn.layer.borderColor = [[UIColor colorWithRGBValue:0xcacaca] CGColor];
    
    self.saveBtn.layer.cornerRadius = 5.0;
    self.saveBtn.layer.masksToBounds = YES;
    
    if (self.userInfo) {
        self.profileInfo = self.userInfo.basicDict;
        [[NSUserDefaults standardUserDefaults] setObject:self.profileInfo forKey:VNProfileInfo];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSDictionary *profileInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNProfileInfo];
    if (profileInfo && profileInfo.count) {
        self.profileInfo = [[NSDictionary alloc] initWithDictionary:profileInfo];
    }
    else {
        self.profileInfo = @{};
    }
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

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    else if (section == 1) {
        return 6;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"VNEditProfileViewControllerCellIdentifier";
    VNEditProfileTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (indexPath.section == 0) {
        cell.thumbnailURLstr = [self.profileInfo objectForKey:@"avatar"];
        cell.titleLabel.text = @"用户头像";
        [cell reload];
    }
    else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0: {
                cell.titleLabel.text = @"昵称";
                cell.contentLabel.text = [self.profileInfo objectForKey:@"name"];
            }
                break;
            case 1: {
                cell.titleLabel.text = @"性别";
                cell.contentLabel.text = [self.profileInfo objectForKey:@"sex"];
            }
                break;
            case 2: {
                cell.titleLabel.text = @"地区";
                cell.contentLabel.text = [self.profileInfo objectForKey:@"location3"];
            }
                break;
            case 3: {
                cell.titleLabel.text = @"描述";
                cell.contentLabel.text = [self.profileInfo objectForKey:@"description"];
            }
                break;
            case 4: {
                cell.titleLabel.text = @"星座";
                cell.contentLabel.text = [self.profileInfo objectForKey:@"constellation"];
            }
                break;
            case 5: {
                cell.titleLabel.text = @"生日";
                cell.contentLabel.text = [self.profileInfo objectForKey:@"birthday"];
            }
                break;
        }
    }
    
    return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        //FIXME: 上传头像
    }
    else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 1: {
            }
                break;
            case 4: {
            }
                break;
            case 5: {
            }
                break;
            case 0: {
            }
            case 2: {
            }
            case 3: {
                VNEditProfileTableViewCell *cell = (VNEditProfileTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
                VNEditContentViewController *editContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNEditContentViewController"];
                editContentViewController.title = cell.titleLabel.text;
                [self.navigationController pushViewController:editContentViewController animated:YES];
            }
                break;

        }
    }
}

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)save:(id)sender {
}

@end
