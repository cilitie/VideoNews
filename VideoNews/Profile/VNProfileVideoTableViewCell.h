//
//  VNProfileVideoTableViewCell.h
//  VideoNews
//
//  Created by liuyi on 14-7-18.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNProfileVideoTableViewCell : UITableViewCell

@property (strong, nonatomic) VNNews *news;

- (void)reload;
- (void)startOrPausePlaying:(BOOL)isPlay;

@end
