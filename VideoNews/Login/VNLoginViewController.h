//
//  VNLoginViewController.h
//  VideoNews
//
//  Created by liuyi on 14-7-7.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SourceViewType) {
    SourceVCTypeMineProfile=0
};


@interface VNLoginViewController : UIViewController

@property (assign, nonatomic) SourceViewType controllerType;


@end
