//
//  VNSearchViewController.m
//  VideoNews
//
//  Created by liuyi on 14-6-27.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNSearchViewController.h"
#import "VNCategoryCollectionViewCell.h"
#import "VNResultViewController.h"
#import "VNSearchField.h"
#import "VNSearchWordViewController.h"
#import "SVPullToRefresh.h"

@interface VNSearchViewController () <UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate> {
    BOOL userScrolling;
    CGPoint initialScrollOffset;
    CGPoint previousScrollOffset;
    BOOL isToBottom;
    BOOL isTabBarHidden;
}

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
        isTabBarHidden = NO;
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
    [self.categoryCollectionView addPullToRefreshWithActionHandler:^{
        // FIXME: Hard code
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
            [VNHTTPRequestManager categoryList:^(NSArray *categoryArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", [error localizedDescription]);
                }
                else {
                    [weakSelf.categoryArr addObjectsFromArray:categoryArr];
                    [self.categoryCollectionView reloadData];
                }
                [weakSelf.categoryCollectionView.pullToRefreshView stopAnimating];

            }];;
        });
    }];
    //[self.categoryCollectionView triggerPullToRefresh];


}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    if (isTabBarHidden) {
//        [self showTabBar];
//    }
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
    
    [cell.bgImageView setImageWithURL:[NSURL URLWithString:category.img_url] placeholderImage:[UIImage imageNamed:@"300-300pic"]];
    [cell.titleLabel setText:category.name];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    VNCategory *category=[self.categoryArr objectAtIndex:selectedItemIndex];
    //NSString *label= category.name;
    //UMeng analytics
    [MobClick event:@"Category" label:[NSString stringWithFormat:@"%d",category.cid]];
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

#pragma mark - SEL

- (void)hideTabBar {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    
    for(UIView *view in self.tabBarController.view.subviews) {
        if([view isKindOfClass:[UITabBar class]]) {
            [view setFrame:CGRectMake(view.frame.origin.x, CGRectGetHeight(self.view.bounds), view.frame.size.width, view.frame.size.height)];
        }
        else {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, CGRectGetHeight(self.view.bounds))];
        }
    }
    isTabBarHidden = YES;
    [UIView commitAnimations];
}

- (void)showTabBar {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];
    for(UIView *view in self.tabBarController.view.subviews) {
        if([view isKindOfClass:[UITabBar class]]) {
            [view setFrame:CGRectMake(view.frame.origin.x, CGRectGetHeight(self.view.bounds)-49, view.frame.size.width, view.frame.size.height)];
        }
        else {
            [view setFrame:CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width,  CGRectGetHeight(self.view.bounds)-49)];
        }
    }
    isTabBarHidden = NO;
    [UIView commitAnimations];
}

#pragma mark - Scrollview Delegate

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [self showTabBar];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    userScrolling = YES;
    initialScrollOffset = scrollView.contentOffset;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (!userScrolling) return;
    
    //initialize
    if (scrollView.contentSize.height <= scrollView.bounds.size.height) {
        [self showTabBar];
        return;
    }
    
    if (scrollView.contentOffset.y <= 0) {
        //Scrolling above the page
        [self showTabBar];
        return;
    }
    
    //contentOffset
    CGFloat contentOffset = scrollView.contentOffset.y - initialScrollOffset.y;
    
    if (scrollView.contentOffset.y <= 24) {
        contentOffset = scrollView.contentOffset.y;
    } else {
        if (contentOffset < 0 && (scrollView.contentOffset.y - previousScrollOffset.y) > 0) {
            initialScrollOffset = scrollView.contentOffset;
        }
    }
    
    contentOffset = roundf(contentOffset);
    
    if (contentOffset >= 0 && (scrollView.contentOffset.y + self.categoryCollectionView.frame.size.height < scrollView.contentSize.height) && scrollView.contentOffset.y > 24) {
        [self hideTabBar];
    }
    
    //scroll to bottom, quit fullScreen
    if (scrollView.contentOffset.y + self.categoryCollectionView.frame.size.height >= scrollView.contentSize.height+49) {
        [self showTabBar];
    }
    
    if (scrollView.contentOffset.y + scrollView.frame.size.height <= scrollView.contentSize.height) {
        previousScrollOffset = scrollView.contentOffset;
    }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (velocity.y < -0.5) {
        userScrolling = NO;
        [self showTabBar];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    userScrolling = NO;
    initialScrollOffset = CGPointMake(0, 0);
}

@end
