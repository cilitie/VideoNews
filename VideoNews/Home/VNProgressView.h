//
//  VNProgressView.h
//  VideoNews
//
//  Created by zhangxue on 14-7-22.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ProgressViewStatus) {
    ProgressViewStatusNormal = 0,              //普通模式
    ProgressViewStatusEditing,             //编辑模式
};

@interface VNProgressView : UIView
{
@private
	float progress ;
}

@property (nonatomic, assign) float progress ;

@property (nonatomic, strong) NSArray *timePointArr;

@property (nonatomic, assign) ProgressViewStatus status;

//小方块闪烁
- (void)setTippingPointShining:(BOOL)shine;

@end
