//
//  VNUserProfileHeaderView.m
//  VideoNews
//
//  Created by liuyi on 14-7-23.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNUserProfileHeaderView.h"

@interface VNUserProfileHeaderView ()

@property (weak, nonatomic) IBOutlet UILabel *videoTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *followTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *fansTitleLabel;
- (IBAction)tap:(UITapGestureRecognizer *)sender;

@end

@implementation VNUserProfileHeaderView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _userInfo = nil;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)reload {
    if (self.userInfo) {
        //videoHeaderView
        [self.thumbnailImgView setImageWithURL:[NSURL URLWithString:self.userInfo.avatar] placeholderImage:[UIImage imageNamed:@"150-150User"]];
        [self.thumbnailImgView.layer setCornerRadius:CGRectGetHeight([self.thumbnailImgView bounds]) / 2];
        self.thumbnailImgView.layer.masksToBounds = YES;
        NSLog(@"%@", self.userInfo.name);
        [self.nameLabel setText:self.userInfo.name];
        NSDictionary *attribute = @{NSFontAttributeName: self.nameLabel.font};
        CGRect rect = [self.userInfo.name boundingRectWithSize:CGSizeMake(200.0, CGRectGetHeight(self.nameLabel.frame)) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        self.nameLabelWidthLC.constant = CGRectGetWidth(rect)+1;
        
        if (self.userInfo.sex) {
            self.genderImgView.hidden = NO;
            if ([self.userInfo.sex isEqualToString:@"male"]) {
                [self.genderImgView setImage:[UIImage imageNamed:@"25-25Male"]];
            }
            else if ([self.userInfo.sex isEqualToString:@"female"]) {
                [self.genderImgView setImage:[UIImage imageNamed:@"25-25Female"]];
            }
            else {
                self.genderImgView.hidden = YES;
            }
        }
        else {
            self.genderImgView.hidden = YES;
        }
        
        if (self.userInfo.location) {
            self.locationLabel.text = self.userInfo.location;
        }
        else {
            self.locationLabel.text = @"位置未知";
        }
        
        if (self.userInfo.userDescription && ![self.userInfo.userDescription isEqualToString:@""]) {
            self.descriptionLabel.text = self.userInfo.userDescription;
        }
        else {
            self.descriptionLabel.text = @"ta没有任何介绍";
        }
        
        [self.videoCountLabel setText:self.userInfo.video_count];
        [self.followCountLabel setText:self.userInfo.idol_count];
        [self.fansCountLabel setText:self.userInfo.fans_count];
    }
}

- (IBAction)tap:(UITapGestureRecognizer *)sender {
    CGPoint point = [sender locationInView:self];
    NSUInteger index = 0;
    if (CGRectContainsPoint(CGRectMake(0, 94, 106, 50), point)) {
        //FIXME: tab变化需要修改
        self.videoTitleLabel.textColor = [UIColor colorWithRGBValue:0xce2426];
        self.followTitleLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
        self.fansTitleLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
        index = 0;
    }
    else if (CGRectContainsPoint(CGRectMake(106, 94, 106, 50), point)) {
        self.videoTitleLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
        self.followTitleLabel.textColor = [UIColor colorWithRGBValue:0xce2426];
        self.fansTitleLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
        index = 1;
    }
    else if (CGRectContainsPoint(CGRectMake(106*2, 94, 106, 50), point)) {
        self.videoTitleLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
        self.followTitleLabel.textColor = [UIColor colorWithRGBValue:0xa2a2a2];
        self.fansTitleLabel.textColor = [UIColor colorWithRGBValue:0xce2426];
        index = 2;
    }
    else if (CGRectContainsPoint(CGRectMake(10, 10, 75, 75), point)) {
        index = 11;
    }
    else if (CGRectContainsPoint(CGRectMake(85, 0, CGRectGetWidth(self.bounds)-85.0, 95), point)) {
        index = 12;
    }
    else {
        return;
    }
    if (self.tabHandler) {
        self.tabHandler(index);
    }
}
@end
