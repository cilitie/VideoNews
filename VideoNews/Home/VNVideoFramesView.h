//
//  VNVideoFramesView.h
//  VideoNews
//
//  Created by zhangxue on 14-7-20.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VNVideoFramesViewDelegate <NSObject>

- (void)didSelecteTime:(CGFloat)time;

@end

@interface VNVideoFramesView : UIView

- (id)initWithFrame:(CGRect)frame andVideoPath:(NSString *)videoPath;

@property (nonatomic,assign)id<VNVideoFramesViewDelegate> delegate;

@end
