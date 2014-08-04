//
//  VNHomeViewController.m
//  VideoNews
//
//  Created by liuyi on 14-6-26.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNHomeViewController.h"
#import "SVPullToRefresh.h"
#import "TMQuiltView.h"
#import "VNQuiltViewCell.h"
#import "VNNewsDetailViewController.h"
#import "VNProfileViewController.h"
#import "VNMineProfileViewController.h"

@interface VNHomeViewController () <TMQuiltViewDataSource,TMQuiltViewDelegate,VNQuiltViewCellDelegate> {
    TMQuiltView *newsQuiltView;
    BOOL userScrolling;
    CGPoint initialScrollOffset;
    CGPoint previousScrollOffset;
    BOOL isToBottom;
    BOOL isTabBarHidden;
}

@property (strong, nonatomic) NSMutableArray *newsArr;

@property (strong, nonatomic) VNNews *curNews;

@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

@end

//static int selectedItemIndex;

@implementation VNHomeViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _newsArr = [NSMutableArray array];
        isTabBarHidden = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeCellForNewsDeleted:) name:VNHomeCellDeleteNotification object:nil];

    
    [self.view setBackgroundColor:[UIColor colorWithRGBValue:0xe1e1e1]];
    
    CGRect frame = self.view.bounds;
    frame.origin.y +=64;
    frame.size.height -=64;
    newsQuiltView = [[TMQuiltView alloc] initWithFrame:frame];
	newsQuiltView.delegate = self;
	newsQuiltView.dataSource = self;
    
    __weak typeof(newsQuiltView) weakQuiltView = newsQuiltView;
    __weak typeof(self) weakSelf = self;
    [newsQuiltView addPullToRefreshWithActionHandler:^{
        // FIXME: Hard code
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
            [VNHTTPRequestManager newsListFromTime:refreshTimeStamp completion:^(NSArray *newsArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else {
                    [weakSelf.newsArr removeAllObjects];
                    [weakSelf.newsArr addObjectsFromArray:newsArr];
                    [weakQuiltView reloadData];
                }
                [weakQuiltView.pullToRefreshView stopAnimating];
            }];
        });
    }];
    
    [newsQuiltView addInfiniteScrollingWithActionHandler:^{
        if (![VNHTTPRequestManager isReachable]) {
            [VNUtility showHUDText:@"请检查您的网络!" forView:weakSelf.view];
            [weakQuiltView.infiniteScrollingView stopAnimating];
        }
        else {
            NSString *moreTimeStamp = nil;
            if (weakSelf.newsArr.count) {
                VNNews *lastNews = [weakSelf.newsArr lastObject];
                moreTimeStamp = lastNews.timestamp;
            }
            else {
                moreTimeStamp = [VNHTTPRequestManager timestamp];
            }
            
            [VNHTTPRequestManager newsListFromTime:moreTimeStamp completion:^(NSArray *newsArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else {
                    [weakSelf.newsArr addObjectsFromArray:newsArr];
                    [weakQuiltView reloadData];
                }
                [weakQuiltView.infiniteScrollingView stopAnimating];
            }];
        }
    }];
    [newsQuiltView triggerPullToRefresh];
    
    [self.view addSubview:newsQuiltView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //[[NSNotificationCenter defaultCenter]removeObserver:self name:VNHomeCellDeleteNotification object:nil];
    if (isTabBarHidden) {
        [self showTabBar];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VNHomeCellDeleteNotification object:nil];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"pushVNNewsDetailViewController"]) {
        VNNewsDetailViewController *newsDetailViewController = [segue destinationViewController];
        //newsDetailViewController.news = [self.newsArr objectAtIndex:selectedItemIndex];
        newsDetailViewController.news = _curNews;
        newsDetailViewController.indexPath=_selectedIndexPath;
        newsDetailViewController.hidesBottomBarWhenPushed = YES;
        newsDetailViewController.controllerType = SourceViewControllerTypeHome;
    }
}

#pragma mark - TMQuiltViewDataSource

- (NSInteger)quiltViewNumberOfCells:(TMQuiltView *)TMQuiltView {
    return self.newsArr.count;
}

- (TMQuiltViewCell *)quiltView:(TMQuiltView *)quiltView cellAtIndexPath:(NSIndexPath *)indexPath {
    VNQuiltViewCell *cell = (VNQuiltViewCell *)[quiltView dequeueReusableCellWithReuseIdentifier:@"VNQuiltViewCellIdentifier"];
    if (!cell) {
        cell = [[VNQuiltViewCell alloc] initWithReuseIdentifier:@"VNQuiltViewCellIdentifier"];
    }
    VNNews *news =[self.newsArr objectAtIndex:indexPath.item];
    cell.news=news;
    cell.indexPath=indexPath;
    cell.delegate=self;
    [cell reloadCell];
    NSLog(@"%@", news.basicDict);
    return cell;
}

#pragma mark - TMQuiltViewDelegate

- (NSInteger)quiltViewNumberOfColumns:(TMQuiltView *)quiltView {
    return 2;
}

- (CGFloat)quiltView:(TMQuiltView *)quiltView heightForCellAtIndexPath:(NSIndexPath *)indexPath {
    VNNews *news =[self.newsArr objectAtIndex:indexPath.item];
    return [self cellHeightFor:news];
}

- (CGFloat)quiltViewMargin:(TMQuiltView *)quilView marginType:(TMQuiltViewMarginType)marginType {
    return 10.0;
}

-(void)TapImageView:(VNNews *)news IndexPath:(NSIndexPath *)indexPath
{
    //selectedItemIndex = indexPath.item;
    _curNews=news;
    _selectedIndexPath=indexPath;
    [self performSegueWithIdentifier:@"pushVNNewsDetailViewController" sender:self];
}

-(void)TapUserView:(VNNews *)news {
    NSLog(@"Tap user View");
    VNUser *user = news.author;
    NSString *mineUid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    if (mineUid && [mineUid isEqualToString:user.uid]) {
        VNMineProfileViewController *mineProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNMineProfileViewController"];
        mineProfileViewController.isPush = YES;
        mineProfileViewController.navigationController.navigationBarHidden = YES;
        [self.navigationController pushViewController:mineProfileViewController animated:YES];
    }
    else {
        VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
        profileViewController.uid = user.uid;
        profileViewController.navigationController.navigationBarHidden = YES;
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
}
/*- (void)quiltView:(TMQuiltView *)quiltView didSelectCellAtIndexPath:(NSIndexPath *)indexPath {
    selectedItemIndex = indexPath.item;
    [self performSegueWithIdentifier:@"pushVNNewsDetailViewController" sender:self];
}
*/
#pragma mark - SEL
- (void)removeCellForNewsDeleted:(NSNotification *)notification {
    //int newsNid = [notification.object integerValue];
    //NSLog(@"%d",[notification.object integerValue]);
    NSIndexPath *index=notification.object;
    [_newsArr removeObjectAtIndex:index.row];
    [newsQuiltView deleteCellAtIndexPath:notification.object];
    [newsQuiltView reloadData];
}

- (CGFloat)cellHeightFor:(VNNews *)news {
    __block CGFloat cellHeight = 0.0;
    [news.mediaArr enumerateObjectsUsingBlock:^(VNMedia *obj, NSUInteger idx, BOOL *stop){
        if ([obj.type rangeOfString:@"image"].location != NSNotFound) {
            cellHeight += obj.height;
            *stop = YES;
        }
    }];
    
    NSDictionary *attribute = @{NSFontAttributeName:[UIFont systemFontOfSize:12.0]};
    CGRect rect = [news.title boundingRectWithSize:CGSizeMake(135.0, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    cellHeight += CGRectGetHeight(rect);
    
    cellHeight += cellMargin*2+1.0+cellMargin*2+thumbnailHeight+cellMargin*2;
    
    return cellHeight;
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
    
    if (contentOffset >= 0 && (scrollView.contentOffset.y + newsQuiltView.frame.size.height < scrollView.contentSize.height) && scrollView.contentOffset.y > 24) {
        [self hideTabBar];
    }
    
    //scroll to bottom, quit fullScreen
    if (scrollView.contentOffset.y + newsQuiltView.frame.size.height >= scrollView.contentSize.height+49) {
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
