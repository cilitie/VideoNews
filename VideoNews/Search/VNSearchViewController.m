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
#import "VNResultViewController.h"
#import "VNSearchField.h"
#import "VNSearchWordViewController.h"

@interface VNSearchViewController () <UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *categoryCollectionView;
@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (strong, nonatomic) NSMutableArray *categoryArr;
@property (strong, nonatomic) VNSearchField *searchField;

@end

static int selectedItemIndex;

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
    
    self.searchField = [[VNSearchField alloc] init];
    self.searchField.delegate = self;
    self.searchField.frame = CGRectMake(10, 20+(CGRectGetHeight(self.navBar.bounds)-20-30)/2, CGRectGetWidth(self.navBar.bounds)-10*2, 30);
    NSLog(@"%@", NSStringFromCGRect(self.searchField.frame));
    [self.navBar addSubview:self.searchField];
    
    __weak typeof(self) weakSelf = self;
    [VNHTTPRequestManager categoryList:^(NSArray *categoryArr, NSError *error) {
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
        }
        else {
            [weakSelf.categoryArr addObjectsFromArray:categoryArr];
            [self.categoryCollectionView reloadData];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"pushVNResultViewController"]) {
        VNResultViewController *resultViewController = [segue destinationViewController];
        resultViewController.category = [self.categoryArr objectAtIndex:selectedItemIndex];
    }
}


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
