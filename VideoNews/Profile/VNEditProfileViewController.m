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
#import "VNUploadManager.h"
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, EditPickerType) {
    EditPickerTypeGender,
    EditPickerTypeConstellation,
    EditPickerTypeBirthday
};

@interface VNEditProfileViewController () <UITableViewDataSource, UITableViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,VNUploadManagerDelegate>

@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UIButton *saveBtn;
@property (weak, nonatomic) IBOutlet UITableView *editTableView;
@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIView *pickerBgView;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UIPickerView *customPicker;

@property (strong, nonatomic) NSMutableDictionary *profileInfo;
@property (strong, nonatomic) VNEditProfileTableViewCell *thumbnailCell;

@property (strong, nonatomic) NSArray *genderArr;
@property (strong, nonatomic) NSArray *constellationArr;

- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)cancelPicker:(id)sender;
- (IBAction)completePicker:(id)sender;
- (IBAction)tap:(UITapGestureRecognizer *)sender;

@end

static EditPickerType pickerType = EditPickerTypeGender;

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
    
    self.cancelBtn.layer.cornerRadius = 5.0;
    self.cancelBtn.layer.masksToBounds = YES;
    self.cancelBtn.layer.borderWidth = 1.0;
    self.cancelBtn.layer.borderColor = [[UIColor colorWithRGBValue:0xcacaca] CGColor];
    
    self.saveBtn.layer.cornerRadius = 5.0;
    self.saveBtn.layer.masksToBounds = YES;
    
    NSString *uid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    [VNHTTPRequestManager userInfoForUser:uid completion:^(VNUser *userInfo, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        if (userInfo) {
            self.userInfo = userInfo;
            self.profileInfo = self.userInfo.basicDict;
            [[NSUserDefaults standardUserDefaults] setObject:self.profileInfo forKey:VNProfileInfo];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self.editTableView reloadData];
        }
    }];
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
        //_thumbnailCell=cell;
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
                NSString *gender = [self.profileInfo objectForKey:@"sex"];
                if ([gender isEqualToString:@"male"]) {
                    cell.contentLabel.text = @"男";
                }
                else if ([gender isEqualToString:@"female"]) {
                    cell.contentLabel.text = @"女";
                }
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
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"取消"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"拍照", @"从手机相册选择", nil];
        [actionSheet showInView:self.view];
    }
    else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 1: {
                pickerType = EditPickerTypeGender;
                [self showPicker];
            }
                break;
            case 4: {
                pickerType = EditPickerTypeConstellation;
                [self showPicker];
            }
                break;
            case 5: {
                pickerType = EditPickerTypeBirthday;
                [self showPicker];
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
                editContentViewController.initialStr=cell.contentLabel.text;
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
    if (pickerType == EditPickerTypeGender) {
        return self.genderArr.count;
    }
    else if (pickerType == EditPickerTypeConstellation) {
        return self.constellationArr.count;
    }
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (pickerType == EditPickerTypeGender) {
        return [self.genderArr objectAtIndex:row];
    }
    else if (pickerType == EditPickerTypeConstellation) {
        return [self.constellationArr objectAtIndex:row];
    }
    return nil;
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = YES;
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied) {
                    [VNUtility showHUDText:@"程序没有权限访问您的摄像头，请在隐私设置中开启。" forView:self.view];
                }
                else {
                    picker.videoQuality = UIImagePickerControllerQualityTypeLow;
                    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
                    [self presentViewController:picker
                                       animated:YES
                                     completion:nil];
                }
            }
            else{
                NSLog(@"模拟器无法打开相机");
            }
        }
            break;
        case 1: {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.allowsEditing = YES;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:picker
                               animated:YES
                             completion:nil];
        }
            break;
        case 2: {
            return;
        }
            break;
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    if (editedImage) {
        //CGSize size=CGSizeMake(300, 300);//把大小压缩
        //UIImage *newImage=[self scaleToSize:size withImage:editedImage];
        NSData *imageData = UIImageJPEGRepresentation(editedImage, 0.5);
        [picker dismissViewControllerAnimated:YES completion:nil];
        if (imageData) {
            NSString *uid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
            VNUploadManager *uploadManager=[VNUploadManager sharedInstance];
            uploadManager.delegate=self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [uploadManager uploadImage:imageData Uid:uid completion:^(bool succeed, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (succeed) {
                        //[VNUtility showHUDText:@"头像更新成功！" forView:self.view];
                        //return ;
                    }
                    //[VNUtility showHUDText:@"头像更新失败！" forView:self.view];
                }];
            });
            
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -resizeImage
-(UIImage *)scaleToSize:(CGSize)size withImage:(UIImage*)image
{
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

#pragma mark - uploadDelegate

// Upload completed successfully.
- (void)uploadProgressUpdated:(NSString *)filePath percent:(float)percent
{
    
}
- (void)uploadSucceeded:(NSString *)key ret:(NSDictionary *)ret
{
    //self.thumbnailCell.thumbnailURLstr=[ret objectForKey:@"avatar"];
    [self.profileInfo setObject:[ret objectForKey:@"avatar"] forKey:@"avatar"];
    [[NSUserDefaults standardUserDefaults] setObject:self.profileInfo forKey:VNProfileInfo];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.editTableView reloadData];
    //[self.thumbnailCell reload];
    [VNUtility showHUDText:@"头像更新成功！" forView:self.view];
}

// Upload failed.
- (void)uploadFailed:(NSString *)key error:(NSError *)error
{
    [VNUtility showHUDText:@"头像更新失败！" forView:self.view];
}

#pragma mark - SEL

- (void)showPicker {
    if (pickerType == EditPickerTypeGender) {
        [UIView animateWithDuration:0.3 animations:^{
            self.bgView.hidden = NO;
            [self.customPicker reloadAllComponents];
            self.customPicker.hidden = NO;
            self.datePicker.hidden = YES;
            CGRect pickerFrame = CGRectMake(0, CGRectGetHeight(self.view.window.bounds)-238, CGRectGetWidth(self.view.window.bounds), 238);
            NSLog(@"%@", NSStringFromCGRect(pickerFrame));
            self.pickerBgView.frame = pickerFrame;
        } completion:nil];
    }
    else if (pickerType == EditPickerTypeConstellation) {
        [UIView animateWithDuration:0.3 animations:^{
            self.bgView.hidden = NO;
            [self.customPicker reloadAllComponents];
            self.customPicker.hidden = NO;
            self.datePicker.hidden = YES;
            CGRect pickerFrame = CGRectMake(0, CGRectGetHeight(self.view.window.bounds)-238, CGRectGetWidth(self.view.window.bounds), 238);
            self.pickerBgView.frame = pickerFrame;
        } completion:nil];
    }
    else if (pickerType == EditPickerTypeBirthday) {
        [UIView animateWithDuration:0.3 animations:^{
            self.bgView.hidden = NO;
            self.customPicker.hidden = YES;
            self.datePicker.hidden = NO;
            CGRect pickerFrame = CGRectMake(0, CGRectGetHeight(self.view.window.bounds)-238, CGRectGetWidth(self.view.window.bounds), 238);
            self.pickerBgView.frame = pickerFrame;
        } completion:nil];
    }
}

- (void)hidePicker {
    [UIView animateWithDuration:0.3 animations:^{
        NSLog(@"%@", NSStringFromCGRect(self.pickerBgView.frame));
        CGRect pickerFrame = self.pickerBgView.frame;
        pickerFrame.origin.y += CGRectGetHeight(pickerFrame);
        self.pickerBgView.frame = pickerFrame;
    } completion:^(BOOL finished) {
        self.bgView.hidden = YES;
    }];
}

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

- (IBAction)cancelPicker:(id)sender {
    [self hidePicker];
}

- (IBAction)completePicker:(id)sender {
    if (pickerType == EditPickerTypeGender) {
        if ([self.customPicker selectedRowInComponent:0] == 0) {
            [self.profileInfo setObject:@"male" forKey:@"sex"];
        }
        else {
            [self.profileInfo setObject:@"female" forKey:@"sex"];
        }
        [self.editTableView reloadData];
    }
    else if (pickerType == EditPickerTypeConstellation) {
        [self.profileInfo setObject:[self.constellationArr objectAtIndex:[self.customPicker selectedRowInComponent:0]] forKey:@"constellation"];
        [self.editTableView reloadData];
    }
    else if (pickerType == EditPickerTypeBirthday) {
        NSString *timestamp = [NSString stringWithFormat:@"%f", [self.datePicker.date timeIntervalSince1970]];
        NSLog(@"%@", timestamp);
        [self.profileInfo setObject:timestamp forKey:@"birthday"];
        [self.editTableView reloadData];
    }
    [self hidePicker];
}

- (IBAction)tap:(UITapGestureRecognizer *)sender {
    [self hidePicker];
}

@end
