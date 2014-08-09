//
//  VNVideoDraftTableViewCell.m
//  VideoNews
//
//  Created by zhangxue on 14-7-27.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNVideoDraftTableViewCell.h"

@interface VNVideoDraftTableViewCell ()

@property (nonatomic, strong) UIImageView *displayImageView;
@property (nonatomic, strong) UILabel *timeLbl;

@property (nonatomic, copy) ShareHandler shareHandler;

@end

@implementation VNVideoDraftTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        //display thumb video cover
        _displayImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 70, 70)];
        _displayImageView.backgroundColor = [UIColor darkGrayColor];
        
        UIImageView *playImgView = [[UIImageView alloc] initWithFrame:CGRectMake(20, 20, 30, 30)];
        playImgView.backgroundColor = [UIColor clearColor];
        playImgView.image = [UIImage imageNamed:@"video_play"];
        [_displayImageView addSubview:playImgView];
        
        [self.contentView addSubview:_displayImageView];
        
        
        _timeLbl = [[UILabel alloc] initWithFrame:CGRectMake(80, 20, 150, 30)];
        _timeLbl.backgroundColor = [UIColor clearColor];
        _timeLbl.textColor = [UIColor colorWithRed:116/255.0 green:115/255.0 blue:121/255.0 alpha:1];
        _timeLbl.font = [UIFont fontWithName:@"STHeitiSC-Light" size:13];
        [self.contentView addSubview:_timeLbl];
        
        UIButton *shareBtn = [[UIButton alloc] initWithFrame:CGRectMake(248, 23, 66, 24)];
        shareBtn.backgroundColor = [UIColor colorWithRGBValue:0xCE2426];
        [shareBtn.titleLabel setFont:[UIFont fontWithName:@"STHeitiSC-Light" size:11]];
        [shareBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [shareBtn setTitle:@"分享" forState:UIControlStateNormal];
        [shareBtn setTitle:@"分享" forState:UIControlStateSelected];
        shareBtn.layer.cornerRadius = 7.5;
        shareBtn.clipsToBounds = YES;
        [shareBtn addTarget:self action:@selector(doShare) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:shareBtn];
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 69, 320, 1)];
        lineView.backgroundColor = [UIColor lightGrayColor];
        [self.contentView addSubview:lineView];
    }
    return self;
}

- (void)awakeFromNib
{

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setShareHandlerBlock:(ShareHandler)handler
{
    self.shareHandler = handler;
}

- (void)setDisplayImage:(UIImage *)img timeLabelText:(NSString *)time
{
    _displayImageView.image = img;
    _timeLbl.text = time;
}

#pragma mark - UserInteractionMethods

- (void)doShare
{
    self.shareHandler();
}

@end
