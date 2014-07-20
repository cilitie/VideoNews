//
//  VNCameraOverlayView.h
//  VideoNews
//
//  Created by zhangxue on 14-7-17.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol VNCameraOverlayViewDelegate <NSObject>

@optional

/**
 *  @description go to close process.
 */
- (void)doCloseCurrentController;

/**
 *  @description: change current torch status
 *
 *  @param isOn: if isOn, the torch is on, and vice versa.
 */
- (void)doChangeTorchStatusTo:(BOOL)isOn;

/**
 *  @description: change current camera device.
 *
 *  @param isRear: if isRear, use rear camera, else use front camera instead.
 */
- (void)doChangeDeviceTo:(BOOL)isRear;

/**
 *  @description: delete current video.
 */
- (void)doDeleteCurrentVideo;

/**
 *  @description: start a new video
 */
- (void)doStartNewVideoRecord;

/**
 *  @description: end current video.
 */
- (void)doEndCurVideo;

/**
 *  @description: submit whole video.
 */
- (void)doSubmitWholeVideo;

@end

//long long ago, submit button has three status...
//typedef NS_ENUM(NSUInteger, SubmitBtnStatus) {
//    SubmitBtnStatusAlbum,              //btn 相册模式
//    SubmitBtnStatusDisabled,           //时间还不够，不能提交
//    SubmitBtnStatusEnabled,            //时间够了，可以提交
//};

@interface VNCameraOverlayView : UIView

@property (nonatomic, assign)id<VNCameraOverlayViewDelegate>delegate;

- (void)setTorchBtnHidden:(BOOL)hidden;
- (void)setAlbumAndSubmitBtnStatus:(BOOL)enabled;

@end
