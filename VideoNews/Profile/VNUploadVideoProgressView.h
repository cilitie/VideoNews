//
//  VNUploadVideoProgressView.h
//  VideoNews
//
//  Created by zhangxue on 14-8-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNUploadVideoProgressView : UIView
{
@private
	float progress ;
}

@property (nonatomic, assign) float progress;

- (void)show;
- (void)hide;

@end
