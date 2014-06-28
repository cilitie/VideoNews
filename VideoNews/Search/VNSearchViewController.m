//
//  VNSearchViewController.m
//  VideoNews
//
//  Created by liuyi on 14-6-27.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNSearchViewController.h"
#import "VNCategoryCollectionViewCell.h"
#import "UIImageView+AFNetworking.h"

@interface VNSearchViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) NSMutableArray *categoryArr;

@end

@implementation VNSearchViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _categoryArr = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    __weak typeof(self) weakSelf = self;
    [VNHTTPRequestManager categoryList:^(NSArray *categoryArr, NSError *error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
        else {
            [weakSelf.categoryArr addObjectsFromArray:categoryArr];
        }
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

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.categoryArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    VNCategoryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VNCategoryCollectionViewCellIdentifier" forIndexPath:indexPath];
    VNCategory *category = [self.categoryArr objectAtIndex:indexPath.item];
    
    [cell.bgImageView setImageWithURL:[NSURL URLWithString:category.img_url] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    [cell.titleLabel setText:category.name];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"%d", indexPath.row);
}


@end
