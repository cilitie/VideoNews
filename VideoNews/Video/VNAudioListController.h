//
//  VNMusicListController.h
//  VideoNews
//
//  Created by zhangxue on 14-7-31.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VNAudioListDelegate <NSObject>

@required

- (void)didSelectedAudioAtFilePath:(NSString *)filePath;

@end

@interface VNAudioListController : UIViewController

@property (nonatomic, copy) NSString *onSelectionAudioPath;

@property (nonatomic, assign) id<VNAudioListDelegate>delegate;

@end
