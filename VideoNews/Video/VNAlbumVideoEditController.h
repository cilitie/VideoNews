//
//  VNAlbumVideoEditController.h
//  VideoNews
//
//  Created by zhangxue on 14-7-23.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VNVideoOrientation) {
    VNVideoOrientationLeft = 0,
    VNVideoOrientationRight,
    VNVideoOrientationUpsideDown,
    VNVideoOrientationPortrait
};

@interface VNAlbumVideoEditController : UIViewController

- (id)initWithVideoPath:(NSString *)videoP andSize:(CGSize)s andScale:(CGFloat)scale andOrientation:(VNVideoOrientation)ori;

@end
