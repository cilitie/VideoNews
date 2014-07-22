//
//  VNProfileFansTableViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-7-18.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNProfileFansTableViewCell.h"
#import "UIImageView+AFNetworking.h"

@interface VNProfileFansTableViewCell ()

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImgView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *genderImgView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameLabelWidthLC;
- (IBAction)follow:(id)sender;

@end

@implementation VNProfileFansTableViewCell

- (void)awakeFromNib
{
    self.followBtn.layer.cornerRadius = 5.0;
    self.followBtn.layer.masksToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)reload {
    if (self.user) {
        [self.thumbnailImgView setImageWithURL:[NSURL URLWithString:self.user.avatar] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
        [self.thumbnailImgView.layer setCornerRadius:CGRectGetHeight([self.thumbnailImgView bounds]) / 2];
        self.thumbnailImgView.layer.masksToBounds = YES;
        
        NSLog(@"%@", self.user.name);
        self.nameLabel.text = self.user.name;
        NSDictionary *attribute = @{NSFontAttributeName: self.nameLabel.font};
        CGRect rect = [self.user.name boundingRectWithSize:CGSizeMake(150.0, CGRectGetHeight(self.nameLabel.frame)) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        self.nameLabelWidthLC.constant = CGRectGetWidth(rect)+1;

        if (self.user.sex) {
            self.genderImgView.hidden = NO;
            if ([self.user.sex isEqualToString:@"male"]) {
                [self.genderImgView setImage:[UIImage imageNamed:@"25-25Male"]];
            }
            else if ([self.user.sex isEqualToString:@"female"]) {
                [self.genderImgView setImage:[UIImage imageNamed:@"25-25Female"]];
            }
            else {
                self.genderImgView.hidden = YES;
            }
        }
        else {
            self.genderImgView.hidden = YES;
        }
        
        if (self.user.isMineIdol) {
            self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            self.followBtn.hidden = YES;
        }
        else {
            self.accessoryType = UITableViewCellAccessoryNone;
            self.followBtn.hidden = NO;
        }
    }
}

- (IBAction)follow:(id)sender {
    if (self.followHandler) {
        self.followHandler();
    }
}

@end
