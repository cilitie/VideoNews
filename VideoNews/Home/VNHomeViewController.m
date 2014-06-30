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

@interface VNHomeViewController () <TMQuiltViewDataSource,TMQuiltViewDelegate> {
    TMQuiltView *newsQuiltView;
}

@property (strong, nonatomic) NSMutableArray *newsArr;

@end

@implementation VNHomeViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _newsArr = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
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
            NSString *refreshTimeStamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
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
    
    NSString *moreTimeStamp = nil;
    if (self.newsArr.count) {
        VNNews *lastNews = [self.newsArr lastObject];
        moreTimeStamp = lastNews.timestamp;
    }
    else {
        moreTimeStamp = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    }
    
    [newsQuiltView addInfiniteScrollingWithActionHandler:^{
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
    if ([segue.identifier isEqualToString:@"pushVNNewsDetailViewController"]) {
        VNNewsDetailViewController *newsDetailViewController = [segue destinationViewController];
        newsDetailViewController.hidesBottomBarWhenPushed = YES;
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
    VNNews *news =[self.newsArr objectAtIndex:indexPath.row];
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
    VNNews *news =[self.newsArr objectAtIndex:indexPath.row];
    return [self cellHeightFor:news];
}

- (CGFloat)quiltViewMargin:(TMQuiltView *)quilView marginType:(TMQuiltViewMarginType)marginType {
    return 10.0;
}

- (void)quiltView:(TMQuiltView *)quiltView didSelectCellAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"index:%d",indexPath.row);
    [self performSegueWithIdentifier:@"pushVNNewsDetailViewController" sender:self];
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

@end
