//
//  VNVideoShareViewController.h
//  VideoNews
//
//  Created by zhangxue on 14-7-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VNVideoShareViewController : UIViewController

@property (nonatomic, assign) BOOL fromDraft;
@property (nonatomic, assign) CGFloat coverTime;

- (id)initWithVideoPath:(NSString *)path andCoverImage:(UIImage *)img;

@end
