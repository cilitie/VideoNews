//
//  VNDetailHeaderView.h
//  VideoNews
//
//  Created by liuyi on 14-6-30.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ClickEventHandler)();

@interface VNDetailHeaderView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *newsImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *tagLabel;
@property (weak, nonatomic) IBOutlet UILabel *likeNumLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (copy, nonatomic) ClickEventHandler moreHandler;

@end
