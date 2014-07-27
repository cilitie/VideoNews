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

@interface VNEditProfileViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *saveBtn;
@property (weak, nonatomic) IBOutlet UITableView *editTableView;
@property (strong, nonatomic) NSMutableDictionary *profileInfo;

@property (strong, nonatomic) NSArray *genderArr;
@property (strong, nonatomic) NSArray *constellationArr;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;

@end

static NSUInteger genderPickerTag = 101;
static NSUInteger constellationPickerTag = 102;
static NSUInteger birthdayPickerTag = 103;


@implementation VNEditProfileViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _genderArr = @[@"男", @"女"];
        _constellationArr = @[@"白羊座", @"金牛座", @"双子座", @"巨蟹座", @"狮子座", @"处女座", @"天秤座", @"天蝎座", @"射手座", @"摩羯座", @"水瓶座", @"双鱼座"];
    }
    return self;
}

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
        self.profileInfo = [[NSMutableDictionary alloc] initWithDictionary:profileInfo];
    }
    else {
        self.profileInfo = [@{} mutableCopy];
    }
    [self.editTableView reloadData];
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
                cell.contentLabel.text = [self.profileInfo objectForKey:@"location"];
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
                if ([self.profileInfo objectForKey:@"birthday"]) {
                    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[self.profileInfo objectForKey:@"birthday"] doubleValue]];
                    NSDateFormatter *formatter =[[NSDateFormatter alloc] init];
                    formatter.dateFormat = @"YYYY年-MM月-dd日";
                    NSString *timestamp = [formatter stringFromDate:date];
                    cell.contentLabel.text = timestamp;
                }
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
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n\n\n\n\n\n\n\n\n\n"
                                                                         delegate:self
                                                                cancelButtonTitle:@"确定"
                                                           destructiveButtonTitle:nil
                                                                otherButtonTitles:nil];
                [actionSheet showInView:self.view];
                UIPickerView *genderPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 200.0f)];
                genderPicker.tag = genderPickerTag;
                genderPicker.delegate = self;
                genderPicker.dataSource = self;
                genderPicker.showsSelectionIndicator = YES;
                [actionSheet addSubview:genderPicker];
            }
                break;
            case 4: {
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n\n\n\n\n\n\n\n\n\n"
                                                                         delegate:self
                                                                cancelButtonTitle:@"确定"
                                                           destructiveButtonTitle:nil
                                                                otherButtonTitles:nil];
                [actionSheet showInView:self.view];
                UIPickerView *genderPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 200.0f)];
                genderPicker.tag = constellationPickerTag;
                genderPicker.delegate = self;
                genderPicker.dataSource = self;
                genderPicker.showsSelectionIndicator = YES;
                [actionSheet addSubview:genderPicker];
            }
                break;
            case 5: {
                UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"\n\n\n\n\n\n\n\n\n\n\n\n"
                                                                         delegate:self
                                                                cancelButtonTitle:@"确定"
                                                           destructiveButtonTitle:nil
                                                                otherButtonTitles:nil];
                [actionSheet showInView:self.view];
                UIDatePicker *datePicker = [[UIDatePicker alloc] init];
                datePicker.tag = birthdayPickerTag;
                datePicker.datePickerMode = UIDatePickerModeDate;
                [actionSheet addSubview:datePicker];
            }
                break;
            case 0: {
            }
            case 2: {
            }
            case 3: {
                [[NSUserDefaults standardUserDefaults] setObject:self.profileInfo forKey:VNProfileInfo];
                [[NSUserDefaults standardUserDefaults] synchronize];
                VNEditProfileTableViewCell *cell = (VNEditProfileTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
                VNEditContentViewController *editContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNEditContentViewController"];
                editContentViewController.title = cell.titleLabel.text;
                [self.navigationController pushViewController:editContentViewController animated:YES];
            }
                break;

        }
    }
}

#pragma mark - UIPickerViewDatesource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if (pickerView.tag == genderPickerTag) {
        return self.genderArr.count;
    }
    else if (pickerView.tag == constellationPickerTag) {
        return self.constellationArr.count;
    }
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerView.tag == genderPickerTag) {
        return [self.genderArr objectAtIndex:row];
    }
    else if (pickerView.tag == constellationPickerTag) {
        return [self.constellationArr objectAtIndex:row];
    }
    return nil;
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    UIPickerView *genderPicker= (UIPickerView *)[actionSheet viewWithTag:genderPickerTag];
    if (genderPicker) {
        [self.profileInfo setObject:[self.genderArr objectAtIndex:[genderPicker selectedRowInComponent:0]] forKey:@"sex"];
        [self.editTableView reloadData];
    }
    UIPickerView *constellationPicker= (UIPickerView *)[actionSheet viewWithTag:constellationPickerTag];
    if (constellationPicker) {
        [self.profileInfo setObject:[self.constellationArr objectAtIndex:[constellationPicker selectedRowInComponent:0]] forKey:@"constellation"];
        [self.editTableView reloadData];
    }
    UIDatePicker *birthdayPicker= (UIDatePicker *)[actionSheet viewWithTag:birthdayPickerTag];
    if (birthdayPicker) {
        NSString *timestamp = [NSString stringWithFormat:@"%f", [birthdayPicker.date timeIntervalSince1970]];
        NSLog(@"%@", timestamp);
        [self.profileInfo setObject:timestamp forKey:@"birthday"];
        [self.editTableView reloadData];
    }
}

#pragma mark - SEL

- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)save:(id)sender {
    [VNHTTPRequestManager updateUserInfo:self.profileInfo completion:^(BOOL succeed, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        if (succeed) {
            [VNUtility showHUDText:@"个人信息更新成功!" forView:self.view];
            [self.navigationController popViewControllerAnimated:YES];
            return ;
        }
        [VNUtility showHUDText:@"个人信息更新失败!" forView:self.view];
    }];
}

@end
