//
//  VNEditProfileTableViewCell.h
//  VideoNews
//
//  Created by liuyi on 14-7-25.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNEditProfileTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeadLC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelWidthLC;
@property (strong, nonatomic) UIImageView *thumbnail;
@property (strong, nonatomic) NSString *thumbnailURLstr;

- (void)reload;

@end
