//
//  VNTabBarViewController.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNTabBarViewController.h"

@interface VNTabBarViewController ()

@end

@implementation VNTabBarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.tabBar setBarTintColor:[UIColor whiteColor]];
    [self.tabBar setSelectionIndicatorImage:[self createImageWithColor:[UIColor colorWithRGBValue:0x51c4d4]]];
    
    NSArray *tabBarIcons = @[@"Home", @"Search", @"Add", @"Notification", @"Profile"];
    NSArray *tabBarSelectedIcons = @[@"Home_A", @"Search_A", @"Add_A", @"Notification_A", @"Profile_A"];
    
    [self.tabBar.items enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UITabBarItem *item = obj;
        [item setImage:[[UIImage imageNamed:[tabBarIcons objectAtIndex:idx]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [item setSelectedImage:[[UIImage imageNamed:[tabBarSelectedIcons objectAtIndex:idx]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - SEL

- (UIImage *)createImageWithColor:(UIColor*)color
{
    CGRect rect=CGRectMake(0.0f, 0.0f, 64.0f, 49.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
