//
//  VNUserResultViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-11.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNUserResultViewController.h"
#import "VNUserResultCollectionViewCell.h"
#import "SVPullToRefresh.h"
#import "VNSearchWordViewController.h"
#import "VNSearchField.h"
#import "VNLoginViewController.h"
#import "VNProfileViewController.h"


@interface VNUserResultViewController () <UITextFieldDelegate, UIAlertViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate> {
    BOOL userScrolling;
    CGPoint initialScrollOffset;
    CGPoint previousScrollOffset;
    BOOL isToBottom;
    BOOL isTabBarHidden;
}

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UICollectionView *userResultCollectionView;
@property (strong, nonatomic) NSMutableArray *userResultArr;
@property (strong, nonatomic) NSMutableArray *idolListArr;
@property (strong, nonatomic) VNSearchField *searchField;

- (IBAction)popBack:(id)sender;

@end

//static int selectedItemIndex;

@implementation VNUserResultViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _userResultArr = [NSMutableArray array];
        _idolListArr = [NSMutableArray array];
        isTabBarHidden = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.searchField = [[VNSearchField alloc] init];
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.delegate = self;
    self.searchField.frame = CGRectMake(CGRectGetMaxX(self.backBtn.frame)+10, 20+(CGRectGetHeight(self.navBar.bounds)-20-30)/2, CGRectGetWidth(self.navBar.bounds)-CGRectGetMaxX(self.backBtn.frame)-10*2, 30);
    NSLog(@"%@", NSStringFromCGRect(self.searchField.frame));
    self.searchField.text = self.searchKey;
    [self.navBar addSubview:self.searchField];
    
    //获取关注列表
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    if (userInfo && userInfo.count) {
        NSString *uid = [userInfo objectForKey:@"openid"];
        NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
        if (uid && user_token) {
            [VNHTTPRequestManager idolListForUser:uid userToken:user_token completion:^(NSArray *idolArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                if (idolArr.count) {
                    [self.idolListArr addObjectsFromArray:idolArr];
                }

            }];
        }
    }
    
    __weak typeof(self) weakSelf = self;
    
    [VNHTTPRequestManager searchResultForKey:self.searchKey timestamp:[VNHTTPRequestManager timestamp] searchType:@"user" completion:^(NSArray *resultNewsArr, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            [weakSelf.userResultArr addObjectsFromArray:resultNewsArr];
            for (VNUser *user in weakSelf.userResultArr) {
                if ([self.idolListArr containsObject:user.uid]) {
                    user.isMineIdol = YES;
                }
                else {
                    user.isMineIdol = NO;
                }
            }
            [weakSelf.userResultCollectionView reloadData];
        }
    }];
    
    [weakSelf.userResultCollectionView addInfiniteScrollingWithActionHandler:^{
        NSString *moreTimeStamp = nil;
        if (weakSelf.userResultArr.count) {
            VNNews *lastNews = [weakSelf.userResultArr lastObject];
            NSLog(@"%@", lastNews.timestamp);
            moreTimeStamp = lastNews.timestamp;
        }
        else {
            moreTimeStamp = [VNHTTPRequestManager timestamp];
        }
        
        [VNHTTPRequestManager searchResultForKey:weakSelf.searchKey timestamp:moreTimeStamp searchType:@"user" completion:^(NSArray *resultNewsArr, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else {
                for (VNUser *user in resultNewsArr) {
                    if ([self.idolListArr containsObject:user.uid]) {
                        user.isMineIdol = YES;
                    }
                    else {
                        user.isMineIdol = NO;
                    }
                }
                [weakSelf.userResultArr addObjectsFromArray:resultNewsArr];
                [weakSelf.userResultCollectionView reloadData];
            }
            [weakSelf.userResultCollectionView.infiniteScrollingView stopAnimating];
        }];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (isTabBarHidden) {
        [self showTabBar];
    }
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
    return self.userResultArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    VNUserResultCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VNUserResultCollectionViewCellIdentifier" forIndexPath:indexPath];
    VNUser *user = [self.userResultArr objectAtIndex:indexPath.item];
    cell.user = user;
    [cell reloadCell];
    
    __weak typeof(cell) weakCell = cell;
    cell.followHandler = ^(VNUser *user){
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        if (userInfo && userInfo.count) {
            NSString *uid = [userInfo objectForKey:@"openid"];
            NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
            if ([user.uid isEqualToString:uid]) {
                [VNUtility showHUDText:@"你不能关注自己!" forView:self.view];
                return ;
            }
            if (uid && user_token) {
                [VNHTTPRequestManager followIdol:user.uid follower:uid userToken:user_token operation:@"add" completion:^(BOOL succeed, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (succeed) {
                        [VNUtility showHUDText:@"关注成功!" forView:self.view];
                        [weakCell.followBtn setTitle:@"取消关注" forState:UIControlStateNormal];
                        [weakCell.followBtn setTitleColor:[UIColor colorWithRGBValue:0xcacaca] forState:UIControlStateNormal];
                    }
                    else {
                        [VNUtility showHUDText:@"关注失败!" forView:self.view];
                    }
                }];
            }
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
            [alert show];
            return;
        }
    };
    
    cell.unfollowHandler = ^(VNUser *user){
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        if (userInfo && userInfo.count) {
            NSString *uid = [userInfo objectForKey:@"openid"];
            NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
            if (uid && user_token) {
                if ([user.uid isEqualToString:uid]) {
                    [VNUtility showHUDText:@"你不能关注自己!" forView:self.view];
                    return ;
                }
                [VNHTTPRequestManager followIdol:user.uid follower:uid userToken:user_token operation:@"remove" completion:^(BOOL succeed, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (succeed) {
                        [VNUtility showHUDText:@"取消关注成功!" forView:self.view];
                        [weakCell.followBtn setTitle:@"关  注" forState:UIControlStateNormal];
                        [weakCell.followBtn setTitleColor:[UIColor colorWithRGBValue:0xce2426] forState:UIControlStateNormal];
                    }
                    else {
                        [VNUtility showHUDText:@"取消关注失败!" forView:self.view];
                    }
                }];
            }
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
            [alert show];
            return;
        }
    };
    
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
    VNUser *user = [self.userResultArr objectAtIndex:indexPath.item];
    profileViewController.uid = user.uid;
    [self.navigationController pushViewController:profileViewController animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    VNSearchWordViewController *searchWordViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNSearchWordViewController"];
    [self.navigationController pushViewController:searchWordViewController animated:NO];
    return NO;
}

#pragma mark - SEL

- (IBAction)popBack:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

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
    
    if (contentOffset >= 0 && (scrollView.contentOffset.y + self.userResultCollectionView.frame.size.height < scrollView.contentSize.height) && scrollView.contentOffset.y > 24) {
        [self hideTabBar];
    }
    
    //scroll to bottom, quit fullScreen
    if (scrollView.contentOffset.y + self.userResultCollectionView.frame.size.height >= scrollView.contentSize.height+49) {
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

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        return;
    }
    else if (buttonIndex == 1) {
        VNLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNLoginViewController"];
        [self presentViewController:loginViewController animated:YES completion:nil];
    }
}


@end
