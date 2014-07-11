//
//  VNUserResultViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-11.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNUserResultViewController.h"
#import "VNUserResultCollectionViewCell.h"

@interface VNUserResultViewController () <UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *userResultCollectionView;
@property (strong, nonatomic) NSMutableArray *userResultArr;

@end

@implementation VNUserResultViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _userResultArr = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [VNHTTPRequestManager searchResultForKey:self.searchKey timestamp:[VNHTTPRequestManager timestamp] searchType:@"user" completion:^(NSArray *resultNewsArr, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            [weakSelf.categoryNewsArr addObjectsFromArray:resultNewsArr];
            [weakQuiltView reloadData];
        }
    }];
    
    [newsQuiltView addInfiniteScrollingWithActionHandler:^{
        NSString *moreTimeStamp = nil;
        if (weakSelf.categoryNewsArr.count) {
            VNNews *lastNews = [weakSelf.categoryNewsArr lastObject];
            NSLog(@"%@", lastNews.timestamp);
            moreTimeStamp = lastNews.timestamp;
        }
        else {
            moreTimeStamp = [VNHTTPRequestManager timestamp];
        }
        
        [VNHTTPRequestManager searchResultForKey:weakSelf.searchKey timestamp:moreTimeStamp searchType:weakSelf.searchType completion:^(NSArray *resultNewsArr, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else {
                [weakSelf.categoryNewsArr addObjectsFromArray:resultNewsArr];
                [weakQuiltView reloadData];
            }
            [weakQuiltView.infiniteScrollingView stopAnimating];
        }];
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

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.categoryArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    VNCategoryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VNCategoryCollectionViewCellIdentifier" forIndexPath:indexPath];
    VNCategory *category = [self.categoryArr objectAtIndex:indexPath.item];
    
    [cell.bgImageView setImageWithURL:[NSURL URLWithString:category.img_url] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    [cell.titleLabel setText:category.name];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    selectedItemIndex = indexPath.item;
    [self performSegueWithIdentifier:@"pushVNResultViewController" sender:self];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    VNSearchWordViewController *searchWordViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNSearchWordViewController"];
    [self.navigationController pushViewController:searchWordViewController animated:NO];
    return NO;
}


@end
