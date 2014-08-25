//
//  GPLoadingButton.h
//  GPLoadingView
//
//  Created by crazypoo on 14/7/29.
//  Copyright (c) 2014年  广州文思海辉亚信外派iOS开发小组. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPLoadingButton : UIButton
@property (nonatomic, retain) NSMutableArray *activityViewArray;
@property (nonatomic, retain) UIColor *rotatorColor;
@property (nonatomic, assign) CGFloat *rotatorSize;
@property (nonatomic, assign) CGFloat *rotatorSpeed;
@property (nonatomic, assign) CGFloat *rotatorPadding;
@property (nonatomic, retain) NSString *defaultTitle;
@property (nonatomic, retain) NSString *activityTitle;
-(void)startActivity;
-(void)stopActivity;
@end
