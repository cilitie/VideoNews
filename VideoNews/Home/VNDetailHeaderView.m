//
//  VNDetailHeaderView.m
//  VideoNews
//
//  Created by liuyi on 14-6-30.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNDetailHeaderView.h"

@interface VNDetailHeaderView ()

- (IBAction)click:(id)sender;
- (IBAction)tap:(UITapGestureRecognizer *)sender;

@property (weak, nonatomic) IBOutlet UIButton *moreBtn;

@end

@implementation VNDetailHeaderView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)click:(id)sender {
    UIButton *button = sender;
    if (button == self.moreBtn) {
        if (self.moreHandler) {
            self.moreHandler();
        }
    }
    else if (button == self.commentBtn) {
        if (self.commentHandler) {
            self.commentHandler();
        }
    }
    else if (button == self.likeBtn) {
        if (self.likeHandler) {
            self.likeHandler();
        }
    }
    else {
        if (self.profileHandler) {
            self.profileHandler();
        }
    }
}

- (IBAction)tap:(UITapGestureRecognizer *)sender {
    if (self.profileHandler) {
        self.profileHandler();
    }
}

- (void)likeStatus:(BOOL)liked {
    if (liked) {
        [self.likeImg setImage:[UIImage imageNamed:@"30-30heart_a"]];
    }
    else {
        [self.likeImg setImage:[UIImage imageNamed:@"30-30heart"]];
    }
}

@end
