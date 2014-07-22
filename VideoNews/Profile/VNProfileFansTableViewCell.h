//
//  VNProfileFansTableViewCell.h
//  VideoNews
//
//  Created by liuyi on 14-7-18.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VNProfileFansTableViewCell;

typedef void (^FollowHandler)();

@interface VNProfileFansTableViewCell : UITableViewCell

@property (strong, nonatomic) VNUser *user;
@property (weak, nonatomic) IBOutlet UIButton *followBtn;
@property (copy, nonatomic) FollowHandler followHandler;

- (void)reload;

@end
