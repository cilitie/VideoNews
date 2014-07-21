//
//  VNCustomizedAlbumPickerController.m
//  VideoNews
//
//  Created by zhangxue on 14-7-21.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCustomizedAlbumPickerController.h"

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
        
        
//        UIImagePickerControllerMediaType = "public.movie";
//        UIImagePickerControllerMediaURL = "file:///private/var/mobile/Applications/C5798254-1C98-42D7-B7DE-910E873B8196/tmp/trim.B51BD016-D293-4D52-B855-05EEC4D07184.MOV";
//        UIImagePickerControllerReferenceURL = "assets-library://asset/asset.MOV?id=8DA75856-346A-4BAA-9EE2-A14A10D5D2B9&ext=MOV";
        
    }
    
}


@end
