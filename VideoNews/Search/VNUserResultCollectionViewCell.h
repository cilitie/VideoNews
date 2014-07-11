//
//  VNUserResultCollectionViewCell.h
//  VideoNews
//
//  Created by liuyi on 14-7-11.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ClickEventHandler)(VNUser *user);

@interface VNUserResultCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImgView;
@property (weak, nonatomic) IBOutlet UIButton *followBtn;
@property (weak, nonatomic) IBOutlet UIView *fansBgView;
@property (weak, nonatomic) IBOutlet UILabel *fansCountLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fansBgViewWidthLC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fansCountLabelWidthLC;

@property (strong, nonatomic) VNUser *user;
@property (assign, nonatomic) BOOL isMineIdol;
@property (copy, nonatomic) ClickEventHandler followHandler;
@property (copy, nonatomic) ClickEventHandler unfollowHandler;
- (IBAction)click:(id)sender;

- (void)reloadCell;

@end
