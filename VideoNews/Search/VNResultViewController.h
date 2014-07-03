//
//  VNResultViewController.h
//  VideoNews
//
//  Created by liuyi on 14-7-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ResultType) {
    ResultTypeCategory = 0,
    ResultTypeSerach
};

@interface VNResultViewController : UIViewController

@property (strong, nonatomic) VNCategory *category;
@property (assign, nonatomic) ResultType type;

@end
