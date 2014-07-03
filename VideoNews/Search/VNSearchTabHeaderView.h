//
//  VNSearchTabHeaderView.h
//  VideoNews
//
//  Created by liuyi on 14-7-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, SearchType) {
    SearchTypeVideo = 0,
    SearchTypeUser
};

@interface VNSearchTabHeaderView : UIView

@property (assign, nonatomic) SearchType searchType;

@end
