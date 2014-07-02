//
//  VNCommentTableViewCell.h
//  VideoNews
//
//  Created by liuyi on 14-7-2.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNCommentTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *thumbnail;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *replyBtn;


@end
