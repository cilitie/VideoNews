//
//  VNSearchResultTableViewCell.h
//  VideoNews
//
//  Created by liuyi on 14-7-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNSearchResultTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *searchIcon;
@property (weak, nonatomic) IBOutlet UILabel *searchItemLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchItemLabelXLC;


@end
