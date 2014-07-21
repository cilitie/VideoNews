//
//  VNCustomizedActionSheet.h
//  VideoNews
//
//  Created by zhangxue on 14-7-21.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VNCustomizedActionSheetDelegate <NSObject>

@optional

- (void) draftBtnDidPressed;
- (void) cameraBtnDidPressed;
- (void) albumBtnDidPressed;

- (void) cancelBtnClicked;

@end

@interface VNCustomizedActionSheet : UIView

@property (nonatomic, assign) id<VNCustomizedActionSheetDelegate> delegate;
@property (nonatomic, strong) UIView *superView;
- (void)show;

@end
