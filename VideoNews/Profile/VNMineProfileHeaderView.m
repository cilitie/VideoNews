//
//  VNMineProfileHeaderView.m
//  VideoNews
//
//  Created by liuyi on 14-7-21.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNMineProfileHeaderView.h"

@interface VNMineProfileHeaderView ()

@property (weak, nonatomic) IBOutlet UILabel *videoNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *likeNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *followNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *fansNameLabel;

- (IBAction)edit:(id)sender;
- (IBAction)tap:(UITapGestureRecognizer *)sender;

@end


@implementation VNMineProfileHeaderView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)reload {
    if (self.userInfo) {
        [self.thumbnailImgView setImageWithURL:[NSURL URLWithString:self.userInfo.avatar] placeholderImage:[UIImage imageNamed:@"150-150User"]];
        [self.thumbnailImgView.layer setCornerRadius:CGRectGetHeight([self.thumbnailImgView bounds]) / 2];
        self.thumbnailImgView.layer.masksToBounds = YES;
        [self.nameLabel setText:self.userInfo.name];
        [self.videoCountLabel setText:self.userInfo.video_count];
        [self.favouriteCountLabel setText:self.userInfo.like_count];
        [self.followCountLabel setText:self.userInfo.idol_count];
        [self.fansCountLabel setText:self.userInfo.fans_count];
    }
}

- (IBAction)edit:(id)sender {
    if (self.editHandler) {
        self.editHandler();
    }
}

- (IBAction)tap:(UITapGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:self];
    NSUInteger index = 0;
    if (CGRectContainsPoint(CGRectMake(0, 94, 80, 50), point)) {
        index = 0;
    }
    else if (CGRectContainsPoint(CGRectMake(80, 94, 80, 50), point)) {
        index = 1;
    }
    else if (CGRectContainsPoint(CGRectMake(80*2, 94, 80, 50), point)) {
        index = 2;
    }
    else if (CGRectContainsPoint(CGRectMake(80*3, 94, 80, 50), point)) {
        index = 3;
    }
    else if (CGRectContainsPoint(CGRectMake(10, 10, 75, 75), point)) {
        index = 11;
    }
    else {
        return;
    }
    if (self.tabHandler) {
        self.tabHandler(index);
    }
}

- (void)reloadTabStatus:(NSUInteger)status {
    switch (status) {
        case 0:{
            self.videoNameLabel.textColor = [UIColor colorWithRGBValue:0xce2426];
            self.likeNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
            self.followNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
            self.fansNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
        }
            break;
        case 1:{
            self.videoNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
            self.likeNameLabel.textColor = [UIColor colorWithRGBValue:0xce2426];
            self.followNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
            self.fansNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
        }
            break;
        case 2:{
            self.videoNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
            self.likeNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
            self.followNameLabel.textColor = [UIColor colorWithRGBValue:0xce2426];
            self.fansNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
        }
            break;
        case 3:{
            self.videoNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
            self.likeNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
            self.followNameLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
            self.fansNameLabel.textColor = [UIColor colorWithRGBValue:0xce2426];
        }
            break;
        default:
            break;
    }
}


@end
