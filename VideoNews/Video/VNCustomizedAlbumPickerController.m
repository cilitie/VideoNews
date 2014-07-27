//
//  VNCustomizedAlbumPickerController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-21.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCustomizedAlbumPickerController.h"
#import <AVFoundation/AVFoundation.h>
#import "VNAlbumVideoEditController.h"

@interface VNCustomizedAlbumPickerController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@end

@implementation VNCustomizedAlbumPickerController

- (id)init
{
    self = [super init];
    if (self) {
        
        self.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.mediaTypes = @[@"public.movie"];
        self.delegate = self;
        
        BOOL _isDir;
        NSString *fileDir = [VNUtility getNSCachePath:@"VideoFiles/Temp"];
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:fileDir isDirectory:&_isDir]){
            if (![[NSFileManager defaultManager] createDirectoryAtPath:fileDir withIntermediateDirectories:YES attributes:nil error:nil]) {
                
            }
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    NSLog(@"info....:%@",info);
    
    if ([mediaType isEqualToString:@"public.movie"] && picker.sourceType == UIImagePickerControllerSourceTypePhotoLibrary){
        
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        AVAsset *anAsset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
        float currVideoDuration = anAsset.duration.value / anAsset.duration.timescale;
        
        CGSize size;
        AVAssetTrack *vt;
        CGFloat timeScale;
        
        if ([[anAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0)
        {
            vt = [[anAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
        }
        
        //check the orientation
        CGAffineTransform txf = [vt preferredTransform];
        
        if (txf.a == 0 && txf.d == 0) {
            //lans
            size = CGSizeMake(vt.naturalSize.height, vt.naturalSize.width);
        }
        if (txf.b == 0 && txf.c == 0) {
            //po
            size = vt.naturalSize;
        }
        
        timeScale = anAsset.duration.timescale;
        
        if (currVideoDuration < 5.0) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~视频时长至少要5秒哦~~" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alert show];
            [self popViewControllerAnimated:YES];
        }else if (currVideoDuration <= 30.0){
            
            NSString *videoPath = [VNUtility getNSCachePath:@"VideoFiles/Temp"];
            NSString *filePath = [videoPath stringByAppendingPathComponent:@"VN_Video_Final.mp4"];
            
            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
            AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                                   
                                                   initWithAsset:anAsset presetName:AVAssetExportPresetPassthrough];
            
            exportSession.outputURL = [NSURL fileURLWithPath:filePath];
            
            exportSession.outputFileType = AVFileTypeMPEG4;
            
            __weak VNCustomizedAlbumPickerController *weakSelf = self;
            
            [exportSession exportAsynchronouslyWithCompletionHandler:^{
                
                switch ([exportSession status]) {
                    case AVAssetExportSessionStatusFailed:
                    {
                        NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频导出失败" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
                        [alert show];
                        [self popViewControllerAnimated:YES];
                    }
                        break;
                    case AVAssetExportSessionStatusCancelled:
                    {
                        NSLog(@"Export canceled");
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频导出失败" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
                        [alert show];
                        [self popViewControllerAnimated:YES];
                    }
                        break;
                    default:
                        NSLog(@"NONE");
                        dispatch_async(dispatch_get_main_queue(), ^{
                            
                            VNAlbumVideoEditController *editCtl = [[VNAlbumVideoEditController alloc] initWithVideoPath:filePath andSize:size andScale:timeScale];
                            [weakSelf pushViewController:editCtl animated:YES];
                        });
                        break;
                }
            }];
            
        }else {
            
            NSString *filePath = [[VNUtility getNSCachePath:@"VideoFiles/Temp"] stringByAppendingPathComponent:@"VN_Video_Final.mp4"];

            if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
                [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
            }
            
            NSURL *videoFileUrl = [NSURL fileURLWithPath:filePath];
            
            NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:anAsset];
            
            if ([compatiblePresets containsObject:AVAssetExportPresetMediumQuality]) {
                
                
                AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                      
                                      initWithAsset:anAsset presetName:AVAssetExportPresetPassthrough];
                
                exportSession.outputURL = videoFileUrl;
                
                exportSession.outputFileType = AVFileTypeMPEG4;
                
                CMTime start = CMTimeMakeWithSeconds(0, anAsset.duration.timescale);
                
                CMTime duration = CMTimeMakeWithSeconds(30, anAsset.duration.timescale);
                
                CMTimeRange range = CMTimeRangeMake(start, duration);
                
                exportSession.timeRange = range;
                
                __weak VNCustomizedAlbumPickerController *weakSelf = self;

                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    
                    switch ([exportSession status]) {
                        case AVAssetExportSessionStatusFailed:
                        {
                            NSLog(@"Export failed: %@", [[exportSession error] localizedDescription]);
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频导出失败" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
                            [alert show];
                            [self popViewControllerAnimated:YES];
                        }
                            break;
                        case AVAssetExportSessionStatusCancelled:
                        {
                            NSLog(@"Export canceled");
                            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频导出失败" message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
                            [alert show];
                            [self popViewControllerAnimated:YES];
                        }
                            break;
                        default:
                            NSLog(@"NONE");
                            dispatch_async(dispatch_get_main_queue(), ^{
                                
                                VNAlbumVideoEditController *editCtl = [[VNAlbumVideoEditController alloc] initWithVideoPath:filePath andSize:size andScale:timeScale];
                                [weakSelf pushViewController:editCtl animated:YES];
                            });
                            break;
                    }
                }];
            }
        }
    }
    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
