//
//  VNProgressViewForAlbum.h
//  VideoNews
//
//  Created by zhangxue on 14-7-23.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VNProgressViewForAlbumDelegate



@end

@interface VNProgressViewForAlbum : UISlider

@property (nonatomic, assign) id<VNProgressViewForAlbumDelegate> delegate;

@end
