//
//  VNMoviePlayer.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-9-6.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNMoviePlayer.h"



@implementation VNMoviePlayer

+(MPMoviePlayerController *)shareMoviePlayer
{
    static MPMoviePlayerController *moviePlayInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        moviePlayInstance = [[MPMoviePlayerController alloc] init];
    });
    moviePlayInstance.controlStyle = MPMovieControlStyleNone;
    moviePlayInstance.movieSourceType = MPMovieSourceTypeStreaming;
    moviePlayInstance.shouldAutoplay = NO;
    moviePlayInstance.view.layer.masksToBounds=YES;
    moviePlayInstance.view.layer.cornerRadius=5;
    [moviePlayInstance.view setBackgroundColor:[UIColor clearColor]];
    return moviePlayInstance;
}

@end
