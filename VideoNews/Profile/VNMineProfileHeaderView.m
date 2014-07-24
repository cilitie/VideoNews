//
//  VNMineProfileHeaderView.m
//  VideoNews
//
//  Created by liuyi on 14-7-21.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNMineProfileHeaderView.h"

@interface VNMineProfileHeaderView ()

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
        [self.thumbnailImgView setImageWithURL:[NSURL URLWithString:self.userInfo.avatar] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
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
    else {
        return;
    }
    if (self.tabHandler) {
        self.tabHandler(index);
    }
}

@end
