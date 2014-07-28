//
//  VNUserResultCollectionViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-7-11.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNUserResultCollectionViewCell.h"

@implementation VNUserResultCollectionViewCell

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        self.layer.cornerRadius = 10.0;
        self.layer.masksToBounds = YES;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [[UIColor colorWithRGBValue:0xcacaca] CGColor];
        _isMineIdol = NO;
    }
    return self;
}

- (void)awakeFromNib {
    self.thumbnailImgView.layer.cornerRadius = 5.0;
    self.thumbnailImgView.layer.masksToBounds = YES;
    
    self.fansBgView.layer.cornerRadius = 5.0;
    self.fansBgView.layer.masksToBounds = YES;
    
    self.followBtn.layer.cornerRadius = 5.0;
    self.followBtn.layer.masksToBounds = YES;
    self.followBtn.layer.borderWidth = 1.0;
    self.followBtn.layer.borderColor = [[UIColor colorWithRGBValue:0xcacaca] CGColor];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)reloadCell {
    if (self.user) {
        self.nameLabel.text = self.user.name;
        if (self.user.location && self.user.location.length) {
            self.locationLabel.text = self.user.location;
        }
        else {
            self.locationLabel.text = @"位置未知";
        }
        
        [self.thumbnailImgView setImageWithURL:[NSURL URLWithString:self.user.avatar] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
        
        CGFloat fansCountLabelWidth = 0;
        self.fansCountLabel.text = self.user.fans_count;
        NSDictionary *attribute = @{NSFontAttributeName:self.fansCountLabel.font};
        CGRect rect = [self.fansCountLabel.text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGRectGetHeight(self.fansCountLabel.bounds)) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        fansCountLabelWidth = CGRectGetWidth(rect);
        self.fansBgViewWidthLC.constant = 36.0+fansCountLabelWidth;
        self.fansCountLabelWidthLC.constant = fansCountLabelWidth;
        
        if (self.isMineIdol) {
            [self.followBtn setTitle:@"取消关注" forState:UIControlStateNormal];
            [self.followBtn setTitleColor:[UIColor colorWithRGBValue:0xcacaca] forState:UIControlStateNormal];
        }
        else {
            [self.followBtn setTitle:@"关  注" forState:UIControlStateNormal];
            [self.followBtn setTitleColor:[UIColor colorWithRGBValue:0xce2426] forState:UIControlStateNormal];
        }
    }
}

- (IBAction)click:(id)sender {
    if (self.isMineIdol) {
        if (self.unfollowHandler) {
            self.unfollowHandler(self.user);
        }
    }
    else {
        if (self.followHandler) {
            self.followHandler(self.user);
        }
    }
}
@end
