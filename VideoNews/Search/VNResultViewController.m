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

@interface VNResultViewController () <UITextFieldDelegate, TMQuiltViewDataSource,TMQuiltViewDelegate> {
    TMQuiltView *newsQuiltView;
}

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (strong, nonatomic) VNSearchField *searchField;

@property (strong, nonatomic) NSMutableArray *categoryNewsArr;
- (IBAction)popBack:(id)sender;

@end

static int selectedItemIndex;

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
        newsDetailViewController.news = [self.categoryNewsArr objectAtIndex:selectedItemIndex];
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

- (void)quiltView:(TMQuiltView *)quiltView didSelectCellAtIndexPath:(NSIndexPath *)indexPath {
    selectedItemIndex = indexPath.item;
    [self performSegueWithIdentifier:@"pushVNNewsDetailViewControllerForResult" sender:self];
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
@end
