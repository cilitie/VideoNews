//
//  VNMineProfileHeaderView.h
//  VideoNews
//
//  Created by liuyi on 14-7-21.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ClickEditHandler)();
typedef void(^ClickTabHandler)(NSUInteger index);

@interface VNMineProfileHeaderView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImgView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *favouriteCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *followCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *fansCountLabel;
@property (strong, nonatomic) VNUser *userInfo;

@property (copy, nonatomic) ClickEditHandler editHandler;
@property (copy, nonatomic) ClickTabHandler tabHandler;

- (void)reload;

@end
