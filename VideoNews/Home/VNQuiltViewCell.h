//
//  VNQuiltViewCell.h
//  VideoNews
//
//  Created by liuyi on 14-6-27.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "TMQuiltViewCell.h"

extern CGFloat const cellMargin;
extern CGFloat const thumbnailHeight;

@protocol VNQuiltViewCellDelegate <NSObject>

@optional

-(void)TapImageView:(VNNews *)news;

-(void)TapUserView:(VNNews *)news;

@end


@interface VNQuiltViewCell : TMQuiltViewCell

@property (strong, nonatomic) VNNews *news;

@property (nonatomic, assign) id<VNQuiltViewCellDelegate> delegate;

- (void)reloadCell;

@end
