//
//  VNVideoFilterListScrollView.h
//  VideoNews
//
//  Created by zhangxue on 14-8-16.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, VNVideoFilterType) {
    VNVideoFilterTypeNone = 0,
    VNVideoFilterTypeSepiaTone,
    VNVideoFilterTypeToneCureve,
    VNVideoFilterTypeSoftElegance,
    VNVideoFilterTypeGrayscale,
    VNVideoFilterTypeTiltShift,
    VNVideoFilterTypeVignette,
    VNVideoFilterTypeGaussianSelectiveBlur,
    VNVideoFilterTypeSaturation,
    VNVideoFilterTypeMissEtikate
};

@protocol VNVideoFilterListScrollViewDataSource

@required
- (NSInteger) numberOfComponentsInFilterList;
- (UIImage *) imageForComponentAtIndex:(NSInteger)index;
- (NSString *) titleForComponentAtIndex: (NSInteger)index;
@end

@protocol VNVideoFilterListScrollViewDelegate

@required

- (void)didSelectComponentAtIndex:(NSInteger)index;

@end

@interface VNVideoFilterListScrollView : UIScrollView

- (void)loadData;

@property (nonatomic, assign) id<VNVideoFilterListScrollViewDataSource> dataSource;
@property (nonatomic, assign) id<VNVideoFilterListScrollViewDelegate> delegate;

@end
