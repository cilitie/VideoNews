//
//  VNResultViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNResultViewController.h"
#import "SVPullToRefresh.h"
#import "TMQuiltView.h"
#import "VNQuiltViewCell.h"
#import "VNNewsDetailViewController.h"
#import "VNSearchField.h"
#import "VNSearchWordViewController.h"

@interface VNResultViewController () <UITextFieldDelegate, TMQuiltViewDataSource,TMQuiltViewDelegate,VNQuiltViewCellDelegate> {
    TMQuiltView *newsQuiltView;
    BOOL userScrolling;
    CGPoint initialScrollOffset;
    CGPoint previousScrollOffset;
    BOOL isToBottom;
}

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (strong, nonatomic) VNSearchField *searchField;

@property (strong, nonatomic) NSMutableArray *categoryNewsArr;
@property (strong,nonatomic)VNNews *curNews;
- (IBAction)popBack:(id)sender;

@end

//static int selectedItemIndex;

@implementation VNResultViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _categoryNewsArr = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.type == ResultTypeSerach) {
        self.searchField = [[VNSearchField alloc] init];
        self.searchField.returnKeyType = UIReturnKeySearch;
        self.searchField.delegate = self;
        self.searchField.frame = CGRectMake(CGRectGetMaxX(self.backBtn.frame)+10, 20+(CGRectGetHeight(self.navBar.bounds)-20-30)/2, CGRectGetWidth(self.navBar.bounds)-CGRectGetMaxX(self.backBtn.frame)-10*2, 30);
        NSLog(@"%@", NSStringFromCGRect(self.searchField.frame));
        self.searchField.text = self.searchKey;
        [self.navBar addSubview:self.searchField];
    }
    
    
    [self.view setBackgroundColor:[UIColor colorWithRGBValue:0xe1e1e1]];
    
    CGRect frame = self.view.bounds;
    frame.origin.y +=64;
    frame.size.height -=64;
    newsQuiltView = [[TMQuiltView alloc] initWithFrame:frame];
	newsQuiltView.delegate = self;
	newsQuiltView.dataSource = self;
    
    __weak typeof(newsQuiltView) weakQuiltView = newsQuiltView;
    __weak typeof(self) weakSelf = self;
    
    if (self.type == ResultTypeSerach) {
        [VNHTTPRequestManager searchResultForKey:self.searchKey timestamp:[VNHTTPRequestManager timestamp] searchType:self.searchType completion:^(NSArray *resultNewsArr, NSError *error) {
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
    else if (self.type == ResultTypeCategory) {
        [newsQuiltView addPullToRefreshWithActionHandler:^{
            // FIXME: Hard code
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
                [VNHTTPRequestManager categoryNewsFromTime:refreshTimeStamp category:weakSelf.category.cid completion:^(NSArray *newsArr, NSError *error) {
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else {
                        [weakSelf.categoryNewsArr removeAllObjects];
                        [weakSelf.categoryNewsArr addObjectsFromArray:newsArr];
                        [weakQuiltView reloadData];
                    }
                    [weakQuiltView.pullToRefreshView stopAnimating];
                }];
            });
        }];
        
        [newsQuiltView addInfiniteScrollingWithActionHandler:^{
            NSString *moreTimeStamp = nil;
            if (weakSelf.categoryNewsArr.count) {
                VNNews *lastNews = [weakSelf.categoryNewsArr lastObject];
                moreTimeStamp = lastNews.timestamp;
            }
            else {
                moreTimeStamp = [VNHTTPRequestManager timestamp];
            }
            
            [VNHTTPRequestManager categoryNewsFromTime:moreTimeStamp category:weakSelf.category.cid completion:^(NSArray *newsArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else {
                    [weakSelf.categoryNewsArr addObjectsFromArray:newsArr];
                    [weakQuiltView reloadData];
                }
                [weakQuiltView.infiniteScrollingView stopAnimating];
            }];
        }];
        [newsQuiltView triggerPullToRefresh];
    }
    
    [self.view addSubview:newsQuiltView];
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
    if ([segue.identifier isEqualToString:@"pushVNNewsDetailViewControllerForResult"]) {
        VNNewsDetailViewController *newsDetailViewController = [segue destinationViewController];
        //newsDetailViewController.news = [self.categoryNewsArr objectAtIndex:selectedItemIndex];
        newsDetailViewController.news=_curNews;
        newsDetailViewController.controllerType = SourceViewControllerTypeCategory;
        newsDetailViewController.hidesBottomBarWhenPushed = YES;
    }
}

#pragma mark - TMQuiltViewDataSource

- (NSInteger)quiltViewNumberOfCells:(TMQuiltView *)TMQuiltView {
    return self.categoryNewsArr.count;
}

- (TMQuiltViewCell *)quiltView:(TMQuiltView *)quiltView cellAtIndexPath:(NSIndexPath *)indexPath {
    VNQuiltViewCell *cell = (VNQuiltViewCell *)[quiltView dequeueReusableCellWithReuseIdentifier:@"VNQuiltViewCellIdentifier"];
    if (!cell) {
        cell = [[VNQuiltViewCell alloc] initWithReuseIdentifier:@"VNQuiltViewCellIdentifier"];
    }
    VNNews *news =[self.categoryNewsArr objectAtIndex:indexPath.item];
    cell.delegate=self;
    cell.news=news;
    [cell reloadCell];
    NSLog(@"%@", news.basicDict);
    return cell;
}

#pragma mark - TMQuiltViewDelegate

- (NSInteger)quiltViewNumberOfColumns:(TMQuiltView *)quiltView {
    return 2;
}

- (CGFloat)quiltView:(TMQuiltView *)quiltView heightForCellAtIndexPath:(NSIndexPath *)indexPath {
    VNNews *news =[self.categoryNewsArr objectAtIndex:indexPath.item];
    return [self cellHeightFor:news];
}

- (CGFloat)quiltViewMargin:(TMQuiltView *)quilView marginType:(TMQuiltViewMarginType)marginType {
    return 10.0;
}

-(void)TapImageView:(VNNews *)news
{
    //selectedItemIndex = indexPath.item;
    _curNews=news;
    [self performSegueWithIdentifier:@"pushVNNewsDetailViewControllerForResult" sender:self];
}

-(void)TapUserView:(VNNews *)news
{
    NSLog(@"Tap user View");
}

/*- (void)quiltView:(TMQuiltView *)quiltView didSelectCellAtIndexPath:(NSIndexPath *)indexPath {
    selectedItemIndex = indexPath.item;
    [self performSegueWithIdentifier:@"pushVNNewsDetailViewControllerForResult" sender:self];
}*/

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    VNSearchWordViewController *searchWordViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNSearchWordViewController"];
    [self.navigationController pushViewController:searchWordViewController animated:NO];
    return NO;
}

#pragma mark - SEL

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

- (IBAction)popBack:(id)sender {
    if (self.type == ResultTypeSerach) {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else {
        [self.navigationController popViewControllerAnimated:YES];
    }
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
