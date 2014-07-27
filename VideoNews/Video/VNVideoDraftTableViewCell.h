//
//  VNVideoDraftTableViewCell.h
//  VideoNews
//
//  Created by zhangxue on 14-7-27.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ShareHandler) ();

@interface VNVideoDraftTableViewCell : UITableViewCell

- (void) setShareHandlerBlock:(ShareHandler)handler;
- (void) setDisplayImage:(UIImage *)img timeLabelText:(NSString *)time;

@end
