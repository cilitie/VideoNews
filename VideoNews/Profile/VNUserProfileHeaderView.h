//
//  VNUserProfileHeaderView.h
//  VideoNews
//
//  Created by liuyi on 14-7-23.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ClickTabHandler)(NSUInteger index);

@interface VNUserProfileHeaderView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImgView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *constellationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *genderImgView;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *followCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *fansCountLabel;
@property (strong, nonatomic) VNUser *userInfo;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameLabelWidthLC;
@property (copy, nonatomic) ClickTabHandler tabHandler;

- (void)reload;
- (void)reloadTabStatus:(NSUInteger)status;

@end
