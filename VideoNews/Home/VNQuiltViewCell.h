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

@interface VNQuiltViewCell : TMQuiltViewCell

@property (strong, nonatomic) VNNews *news;

- (void)reloadCell;

@end
