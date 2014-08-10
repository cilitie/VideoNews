//
//  VNProfileVideoTableViewCell.h
//  VideoNews
//
//  Created by liuyi on 14-7-18.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^ClickEventHandler)();

@interface VNProfileVideoTableViewCell : UITableViewCell

@property (strong, nonatomic) VNNews *news;
@property (assign, nonatomic) BOOL isPlaying;
@property (weak, nonatomic) IBOutlet UILabel *favouriteLabel;
@property (weak, nonatomic) IBOutlet UIImageView *likeImg;
@property (assign, nonatomic) BOOL isFavouriteNews;
@property (copy, nonatomic) ClickEventHandler likeHandler;
@property (copy, nonatomic) ClickEventHandler moreHandler;
@property (copy, nonatomic) ClickEventHandler commentHandler;

- (void)reload;
- (void)startOrPausePlaying:(BOOL)isPlay;
- (void)likeStatus:(BOOL)liked;

@end
