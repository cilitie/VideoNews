//
//  VNNewsDetailViewController.m
//  VideoNews
//
//  Created by liuyi on 14-6-30.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNNewsDetailViewController.h"
#import "VNDetailHeaderView.h"
#import "UIButton+AFNetworking.h"

#import "SVPullToRefresh.h"
#import "VNCommentTableViewCell.h"

#import "UMSocial.h"
#import "VNLoginViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "AGEmojiKeyboardView.h"
#import "VNProfileViewController.h"
#import "VNMineProfileViewController.h"

@interface VNNewsDetailViewController () <UITextViewDelegate, UIActionSheetDelegate, UMSocialUIDelegate, UIAlertViewDelegate, VNCommentTableViewCellDelegate, AGEmojiKeyboardViewDelegate, AGEmojiKeyboardViewDataSource> {
    BOOL isKeyboardShowing;
    CGFloat keyboardHeight;
    BOOL isPlaying;
    BOOL isDefaultKeyboard;
    
    BOOL isAutoPlayOption;
}

@property (weak, nonatomic) IBOutlet UITableView *commentTableView;
@property (weak, nonatomic) IBOutlet UITextView *inputTextView;
@property (weak, nonatomic) IBOutlet UIView *inputBar;
@property (weak, nonatomic) IBOutlet UIButton *favouriteBtn;
@property (weak, nonatomic) IBOutlet UILabel *noCommentLabel;
@property (strong, nonatomic) NSMutableArray *commentArr;
@property (strong, nonatomic) NSMutableArray *commentArrNotify;
@property (strong,nonatomic)VNComment *curComment;
@property (strong,nonatomic)NSIndexPath *curIndexPath;
@property (strong, nonatomic) VNDetailHeaderView *headerView;
@property (strong, nonatomic) MPMoviePlayerController *moviePlayer;
@property (strong, nonatomic) UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UILabel *thresholdLabel;
@property (weak, nonatomic) IBOutlet UIView *dismissTapView;
@property (weak, nonatomic) IBOutlet UIButton *keyboardToggleBtn;
@property (strong, nonatomic) AGEmojiKeyboardView *emojiKeyboardView;
@property (strong, nonatomic)UIAlertView *deleteAlert;
@property (assign, nonatomic) int curLikeCount;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputBarHeightLC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputTextViewHeightLC;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputBarBottomLC;


- (IBAction)popBack:(id)sender;
- (IBAction)like:(id)sender;
- (IBAction)share:(id)sender;
- (IBAction)sendComment:(id)sender;
- (IBAction)switchEmoji:(id)sender;
- (IBAction)dismissViewTapped:(UITapGestureRecognizer *)sender;

@end

#define kTagShare 101
#define kTagCommentMine 102
#define kTagCommentAnybody 103
#define kTagCommentOtherUser 104
#define kTagCommentMineNews 106
#define kTagNews 105
#define KReplyButton 1000
static NSString *shareStr;

@implementation VNNewsDetailViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _commentArr = [NSMutableArray arrayWithCapacity:0];
        _commentArrNotify=[NSMutableArray arrayWithCapacity:0];
        isAutoPlayOption = [[[NSUserDefaults standardUserDefaults] objectForKey:VNIsWiFiAutoPlay] boolValue];
        _curLikeCount = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.commentTableView.backgroundColor=[UIColor clearColor];
    self.inputTextView.layer.cornerRadius = 5;
    self.inputTextView.layer.masksToBounds = YES;
    self.inputTextView.layer.borderWidth = 1.0;
    self.inputTextView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    isDefaultKeyboard = YES;

    self.headerView = loadXib(@"VNDetailHeaderView");
    [self.headerView.thumbnailImageView setImageWithURL:[NSURL URLWithString:self.news.author.avatar] placeholderImage:[UIImage imageNamed:@"150-150User"]];
    [self.headerView.thumbnailImageView.layer setCornerRadius:CGRectGetHeight([self.headerView.thumbnailImageView bounds]) / 2];
    self.headerView.thumbnailImageView.layer.masksToBounds = YES;
    self.headerView.nameLabel.text = self.news.author.name;
    self.headerView.newsImageView.layer.masksToBounds=YES;
    [self.headerView.newsImageView.layer setCornerRadius:5];

    
    __weak typeof(self) weakSelf = self;
    
    self.headerView.profileHandler = ^{
        VNUser *user = weakSelf.news.author;
        NSString *mineUid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
        if (mineUid && [mineUid isEqualToString:user.uid]) {
            VNMineProfileViewController *mineProfileViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"VNMineProfileViewController"];
            mineProfileViewController.isPush = YES;
            [weakSelf.navigationController pushViewController:mineProfileViewController animated:YES];
        }
        else {
            VNProfileViewController *profileViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
            profileViewController.uid = user.uid;
            [weakSelf.navigationController pushViewController:profileViewController animated:YES];
        }
    };
    
    self.headerView.likeHandler = ^{
        NSString *user_token = @"";
        NSString *uid = @"";
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:isLogin] boolValue]) {
            NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
            if (userInfo.count) {
                uid = [userInfo objectForKey:@"openid"];
            }
            user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
        }
        else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:weakSelf cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
            [alert show];
            return;
        }
        
        if (weakSelf.headerView.likeBtn.isSelected) {
            [VNHTTPRequestManager favouriteNews:weakSelf.news.nid operation:@"remove" userID:uid user_token:user_token completion:^(BOOL succeed,BOOL isNewsDeleted, int like_count,int user_like_count,NSError *error) {
                //isNewsDeleted=YES;
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else if(isNewsDeleted)
                {
                    //pop，并且发通知
                    [weakSelf deleteCellAndPop:0];
                }
                else if (succeed) {
                    [weakSelf.headerView.likeBtn setSelected:NO];
                    [weakSelf.favouriteBtn setSelected:NO];
                    weakSelf.curLikeCount -= 1;
                    weakSelf.headerView.likeNumLabel.text = [NSString stringWithFormat:@"%d", weakSelf.curLikeCount];
                }
                else {
                    [VNUtility showHUDText:@"取消点赞失败!" forView:weakSelf.view];
                }
            }];
        }
        else {
            [VNHTTPRequestManager favouriteNews:weakSelf.news.nid operation:@"add" userID:uid user_token:user_token completion:^(BOOL succeed,BOOL isNewsDeleted, int like_count,int user_like_count,NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else if (isNewsDeleted)
                {
                    //pop，并且发通知
                    [weakSelf deleteCellAndPop:0];
                }
                else if (succeed) {
                    [weakSelf.headerView.likeBtn setSelected:YES];
                    [weakSelf.favouriteBtn setSelected:YES];
                    weakSelf.curLikeCount += 1;
                    weakSelf.headerView.likeNumLabel.text = [NSString stringWithFormat:@"%d", weakSelf.curLikeCount];
                    //[VNUtility showHUDText:@"点赞成功!" forView:self.view];
                }
                else {
                    [VNUtility showHUDText:@"已点赞!" forView:weakSelf.view];
                }
            }];
        }
    };
    
    self.headerView.moreHandler = ^{
        [VNHTTPRequestManager isNewsDeleted:weakSelf.news.nid completion:^(BOOL isNewsDeleted,NSError *error)
         {
             //isNewsDeleted=YES;
             if (error) {
                 NSLog(@"%@", error.localizedDescription);
             }
             else if (isNewsDeleted) {
                 [weakSelf deleteCellAndPop:0];
             }
             else
             {
                 UIActionSheet *actionSheet = nil;
                 NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
                 NSString *mineID = [userInfo objectForKey:@"openid"];
                 actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接", [weakSelf.news.author.uid isEqualToString:mineID] ? @"删除" : @"举报", nil];
                 actionSheet.tag = kTagNews;
                 [actionSheet showFromTabBar:weakSelf.tabBarController.tabBar];
             }
         }];
        /*UIActionSheet *actionSheet = nil;
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        NSString *mineID = [userInfo objectForKey:@"openid"];
        actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", @"复制链接", [weakSelf.news.author.uid isEqualToString:mineID] ? @"删除" : @"举报", nil];
        actionSheet.tag = kTagNews;
        [actionSheet showFromTabBar:weakSelf.tabBarController.tabBar];*/
    };
    
    [self.news.mediaArr enumerateObjectsUsingBlock:^(VNMedia *obj, NSUInteger idx, BOOL *stop){
        if ([obj.type rangeOfString:@"image"].location != NSNotFound) {
            self.media = obj;
        }
        else {
            self.vedioMedia = obj;
        }
    }];
    [self.headerView.newsImageView setImageWithURL:[NSURL URLWithString:self.media.url] placeholderImage:[UIImage imageNamed:@"600-600pic"]];
    
    CGFloat diff = 0;
    self.headerView.titleLabel.text = self.news.title;
    NSDictionary *attribute = @{NSFontAttributeName:self.headerView.titleLabel.font};
    CGRect rect = [self.headerView.titleLabel.text boundingRectWithSize:CGSizeMake(self.headerView.titleLabel.bounds.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    CGRect titleLabelframe = self.headerView.titleLabel.frame;
    titleLabelframe.size.height += CGRectGetHeight(rect);
    diff = CGRectGetHeight(rect);
    self.headerView.titleLabel.frame = titleLabelframe;
    
    CGRect headerFrame = self.headerView.bounds;
    headerFrame.size.height += diff;
    self.headerView.bounds = headerFrame;
    
    //self.headerView.timeLabel.text = self.news.date;
    self.headerView.timeLabel.text = [VNUtility timeFormatToDisplay:[self.news.timestamp floatValue]];
    self.headerView.tagLabel.text = self.news.tags;
   
    if (self.news.comment_count>10000) {
        NSString *comment_count_str=[NSString stringWithFormat:@"%d万",self.news.comment_count/10000];
        self.headerView.commentLabel.text=comment_count_str;
    }
    else
    {
        self.headerView.commentLabel.text = [NSString stringWithFormat:@"%d", self.news.comment_count];
    }
    if (self.news.like_count>10000) {
        NSString *like_count_str=[NSString stringWithFormat:@"%d万",self.news.like_count/10000];
        self.headerView.likeNumLabel.text=like_count_str;
    }
    else
    {
        self.headerView.likeNumLabel.text = [NSString stringWithFormat:@"%d", self.news.like_count];
    }
    self.curLikeCount = self.news.like_count;
    
    //视频URL
    NSLog(@"%@", self.vedioMedia.url);
    NSURL *url = [NSURL URLWithString:self.vedioMedia.url];
    //NSURL *url = [NSURL URLWithString:@"http://cloud.video.taobao.com//play/u/320975160/p/1/e/2/t/1/12378629.M3u8"];
    self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
    self.moviePlayer.controlStyle = MPMovieControlStyleNone;
    self.moviePlayer.movieSourceType = MPMovieSourceTypeStreaming;
    [self.moviePlayer.view setFrame:self.headerView.newsImageView.frame];
    self.moviePlayer.shouldAutoplay = NO;
    self.moviePlayer.view.layer.masksToBounds=YES;
    self.moviePlayer.view.layer.cornerRadius=5;
    [self.moviePlayer.view setBackgroundColor:[UIColor clearColor]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoFinishedPlayCallback:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
    [self.headerView addSubview:self.moviePlayer.view];
    
    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playBtn.frame = CGRectMake(0, 0, 300.0, 300.0);
    self.playBtn.center = self.headerView.newsImageView.center;
    if ([VNHTTPRequestManager isReachableViaWiFi] && isAutoPlayOption) {
        //[self.moviePlayer play];
        [self playAndCount];
        [self.playBtn addTarget:self action:@selector(pauseVideo) forControlEvents:UIControlEventTouchUpInside];
        isPlaying = YES;
    }
    else {
        [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
        self.moviePlayer.view.hidden = YES;
        isPlaying = NO;
    }
    [self.headerView addSubview:self.playBtn];
    
    //已收藏判断
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    if (userInfo && userInfo.count) {
        NSString *uid = [userInfo objectForKey:@"openid"];
        NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
        if (uid && user_token) {
            [VNHTTPRequestManager favouriteNewsListFor:uid userToken:user_token completion:^(NSArray *favouriteNewsArr, NSError *error) {
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                if (favouriteNewsArr.count) {
                    NSLog(@"%@", favouriteNewsArr);
                    for (NSDictionary *dic in favouriteNewsArr) {
                        if ([[dic objectForKey:@"nid"] isEqualToString:[NSString stringWithFormat:@"%d", self.news.nid]]) {
                            [self.favouriteBtn setSelected:YES];
                            [self.headerView.likeBtn setSelected:YES];
                            break;
                        }
                    }
                }
            }];
        }
    }
    
    self.commentTableView.tableHeaderView = self.headerView;
    [self.commentTableView registerNib:[UINib nibWithNibName:@"VNCommentTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNCommentTableViewCellIdentifier"];
    //self.commentTableView.layer.cornerRadius = 5.0;
    //self.commentTableView.layer.masksToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    //zmy modify
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(replyCommentFromNotification:)
//                                                 name:@"replyCommentFromNotification"
//                                               object:nil];
//    
    [VNHTTPRequestManager commentListForNews:self.news.nid timestamp:[VNHTTPRequestManager timestamp] completion:^(NSArray *commemtArr, BOOL isNewsDeleted,NSError *error) {
        //isNewsDeleted=YES;
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        else if (isNewsDeleted)
        {
            [self deleteCellAndPop:0];
        }
        else {
            [self.commentArr addObjectsFromArray:commemtArr];
            [self.commentTableView reloadData];
        }
    }];
    
    [self.commentTableView addPullToRefreshWithActionHandler:^{
        // FIXME: Hard code
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
            [VNHTTPRequestManager commentListForNews:self.news.nid timestamp:refreshTimeStamp completion:^(NSArray *commemtArr, BOOL isNewsDeleted,NSError *error) {
                //isNewsDeleted=YES;
                if (error) {
                    NSLog(@"%@", error.localizedDescription);
                }
                else if (isNewsDeleted)
                {
                    [self deleteCellAndPop:0];
                }
                else {
                    [weakSelf.commentArr removeAllObjects];
                    [weakSelf.commentArr addObjectsFromArray:commemtArr];
                    [weakSelf.commentTableView reloadData];
                }
                [weakSelf.commentTableView.pullToRefreshView stopAnimating];
            }];;
        });
    }];
    
    [self.commentTableView addInfiniteScrollingWithActionHandler:^{
        NSString *moreTimeStamp = nil;
        if (weakSelf.commentArr.count) {
            VNComment *lastComent = [weakSelf.commentArr lastObject];
//            NSLog(@"%@", lastComent.insert_time);
            moreTimeStamp = lastComent.insert_time;
        }
        else {
            moreTimeStamp = [VNHTTPRequestManager timestamp];
        }
        
        [VNHTTPRequestManager commentListForNews:self.news.nid timestamp:moreTimeStamp completion:^(NSArray *commemtArr, BOOL isNewsDeleted,NSError *error) {
            //isNewsDeleted=YES;
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (isNewsDeleted)
            {
                [self deleteCellAndPop:0];
            }
            else {
                [weakSelf.commentArr addObjectsFromArray:commemtArr];
                [weakSelf.commentTableView reloadData];
            }
            [weakSelf.commentTableView.infiniteScrollingView stopAnimating];
        }];
    }];
    if (self.controllerType==SourceViewControllerTypeNotification) {
        [self replyCommentFromNotification];
    }

}

-(void) replyButtonClicked:(UIButton *)sender
{
    int row=sender.tag;
    _curComment=_commentArr[row-KReplyButton];
    _curIndexPath=[NSIndexPath indexPathForRow: (row-KReplyButton) inSection:0];
   // NSLog(@"%d",_curIndexPath.row);
    
    [self.inputTextView setText:[NSString stringWithFormat:@"回复@%@:", self.curComment.author.name]];
    [self.inputTextView becomeFirstResponder];
    
}

-(void) thumbnailClicked:(UIButton *)sender
{
    int row=sender.tag;
    _curComment=_commentArr[row-KReplyButton];
    //NSLog(@"nid:%@",_curComment.author.uid);
    VNUser *user = _curComment.author;
    NSString *mineUid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
    if (mineUid && [mineUid isEqualToString:user.uid]) {
        VNMineProfileViewController *mineProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNMineProfileViewController"];
        mineProfileViewController.isPush = YES;
        [self.navigationController pushViewController:mineProfileViewController animated:YES];
    }
    else {
        VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
        profileViewController.uid = user.uid;
        [self.navigationController pushViewController:profileViewController animated:YES];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.moviePlayer stop];
    switch (self.controllerType) {
        case SourceViewControllerTypeCategory:
            break;
        case SourceViewControllerTypeProfile:
            break;
        default:
//            self.navigationController.navigationBarHidden = NO;
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"replyCommentFromNotification" object:nil];
    //销毁播放通知
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
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

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.commentArr.count) {
        return self.commentArr.count;
    }
    else {
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.commentArr.count) {
        static NSString *cellIdentifier = @"VNCommentTableViewCellIdentifier";
        VNCommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            VNComment *comment = [self.commentArr objectAtIndex:indexPath.row];
        [cell.thumbnail setImageForState:UIControlStateNormal withURL:[NSURL URLWithString:comment.author.avatar] placeholderImage:[UIImage imageNamed:@"150-150User"]];
        [cell.thumbnail.layer setCornerRadius:CGRectGetHeight([cell.thumbnail bounds]) / 2];
        cell.thumbnail.layer.masksToBounds = YES;
        cell.nameLabel.text = comment.author.name;
        cell.delegate=self;
        cell.replyBtn.tag=KReplyButton+indexPath.row;
        cell.thumbnail.tag=KReplyButton+indexPath.row;
        cell.commentLabel.text = comment.content;
        NSDictionary *attribute = @{NSFontAttributeName:cell.commentLabel.font};
        CGRect rect = [cell.commentLabel.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.commentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        //    NSLog(@"%@", NSStringFromCGRect(rect));
        CGRect titleLabelframe = cell.commentLabel.frame;
        titleLabelframe.size.height = CGRectGetHeight(rect);
        //    NSLog(@"%@", NSStringFromCGRect(titleLabelframe));
        cell.commentLabel.frame = titleLabelframe;
        
        //cell.timeLabel.text = [comment.date substringToIndex:10];
        cell.timeLabel.text = [VNUtility timeFormatToDisplay:[[comment.insert_time substringToIndex:10] floatValue]];
        return cell;
    }
    else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 40.0, 300, 20)];
        label.font = [UIFont systemFontOfSize:15.0];
        label.text = @"暂时没有评论";
        label.textColor = [UIColor colorWithRGBValue:0x474747];
        label.textAlignment = NSTextAlignmentCenter;
        [cell addSubview:label];
        return cell;
    }
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.commentArr.count) {
        VNComment *comment = [self.commentArr objectAtIndex:indexPath.row];
        _curIndexPath=indexPath;
        self.curComment = comment;
        UIActionSheet *actionSheet = nil;
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        NSString *mineID = [userInfo objectForKey:@"openid"];
        NSLog(@"author:%@,length:%d", comment.author.uid, comment.author.uid.length);
        NSLog(@"openid:%@,length:%d",mineID, mineID.length);
        if ([self.news.author.uid isEqualToString:mineID]) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"回复", @"查看个人主页",  @"删除评论", nil];
            actionSheet.tag=kTagCommentMineNews;
        }
        else if ([comment.author.uid isEqualToString:mineID]) {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"回复", @"查看个人主页",  @"删除评论", nil];
            actionSheet.tag = kTagCommentMine;
        }
        else if([comment.author.uid isEqualToString:@"1"])
        {
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"回复", @"举报评论", nil];
            actionSheet.tag = kTagCommentAnybody;
        }
        else{
            actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"回复",@"查看个人主页", @"举报评论", nil];
            actionSheet.tag = kTagCommentOtherUser;
        }
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
        actionSheet.delegate = self;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.commentArr.count) {
        CGFloat diff = 0;
        VNComment *comment = [self.commentArr objectAtIndex:indexPath.row];
        VNCommentTableViewCell *cell = loadXib(@"VNCommentTableViewCell");
        NSDictionary *attribute = @{NSFontAttributeName:cell.commentLabel.font};
        CGRect rect = [comment.content boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.commentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        //    NSLog(@"%@", NSStringFromCGRect(rect));
        if (CGRectGetHeight(rect) > 15) {
            diff = CGRectGetHeight(rect)-15;
        }
        return 60.0+diff;
    }
    else {
        return 100.0;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self stopVideoWhenScrollOut];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self stopVideoWhenScrollOut];
}

#pragma mark - SEL

- (void)stopVideoWhenScrollOut {
    if (self.moviePlayer && isPlaying) {
        CGRect convertFrame = [self.moviePlayer.view convertRect:self.headerView.frame toView:self.view.window];
        //FIXME: hard code
        convertFrame.size.height -= 180.0;
//        NSLog(@"%@", NSStringFromCGRect(self.moviePlayer.view.frame));
//        NSLog(@"%@,%@", NSStringFromCGRect(convertFrame), NSStringFromCGRect(self.view.frame));
        if (!CGRectIntersectsRect(convertFrame, self.view.frame)) {
            [self.moviePlayer pause];
            [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
            isPlaying = NO;
        }
    }
}

- (IBAction)popBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)like:(id)sender {
    __block UIButton *button = sender;
    VNAuthUser *authUser = nil;
    NSString *user_token = @"";
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:isLogin] boolValue]) {
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        if (userInfo.count) {
            authUser = [[VNAuthUser alloc] initWithDict:userInfo];
        }
        user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
        [alert show];
        return;
    }
    
    if (button.isSelected) {
        [VNHTTPRequestManager favouriteNews:self.news.nid operation:@"remove" userID:authUser.openid user_token:user_token completion:^(BOOL succeed,BOOL isNewsDeleted, int like_count,int user_like_count,NSError *error) {
            //isNewsDeleted=YES;
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if(isNewsDeleted)
            {
                //pop，并且发通知
                [self deleteCellAndPop:0];
            }
            else if (succeed) {
                [button setSelected:NO];
                self.curLikeCount -= 1;
                [self.headerView.likeBtn setSelected:NO];
                self.headerView.likeNumLabel.text = [NSString stringWithFormat:@"%d", self.curLikeCount];
                //[VNUtility showHUDText:@"已取消!" forView:self.view];

            }
            else {
                [VNUtility showHUDText:@"取消点赞失败!" forView:self.view];
            }
        }];
    }
    else {
        [VNHTTPRequestManager favouriteNews:self.news.nid operation:@"add" userID:authUser.openid user_token:user_token completion:^(BOOL succeed,BOOL isNewsDeleted, int like_count,int user_like_count,NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (isNewsDeleted)
            {
                //pop，并且发通知
                [self deleteCellAndPop:0];
                
            }
            else if (succeed) {
                [button setSelected:YES];
                [self.headerView.likeBtn setSelected:YES];
                self.curLikeCount += 1;
                self.headerView.likeNumLabel.text = [NSString stringWithFormat:@"%d", self.curLikeCount];
                //[VNUtility showHUDText:@"点赞成功!" forView:self.view];
            }
            else {
                [VNUtility showHUDText:@"已点赞!" forView:self.view];
            }
        }];
    }
}
-(void)deleteCellAndPop:(int)tag
{
    switch (_controllerType) {
        case SourceViewControllerTypeHome:
            //NSLog(@"%d",_indexPath.row);
            [[NSNotificationCenter defaultCenter] postNotificationName:VNHomeCellDeleteNotification object:_indexPath];
            break;
        case SourceViewControllerTypeCategory:
            [[NSNotificationCenter defaultCenter] postNotificationName:VNCategoryCellDeleteNotification object:_indexPath];
            break;
        case SourceViewControllerTypeMineProfileVideo:
            [[NSNotificationCenter defaultCenter] postNotificationName:VNMineProfileVideoCellDeleteNotification object:_indexPath];
            break;
        case SourceViewControllerTypeNotification:
            [[NSNotificationCenter defaultCenter] postNotificationName:VNNotificationCellDeleteNotification object:_indexPath];
            break;
        case SourceViewControllerTypeProfile:
            [[NSNotificationCenter defaultCenter] postNotificationName:VNProfileCellDeleteNotification object:_indexPath];
            break;
        case SourceViewControllerTypeMineProfileFavourite:
            [[NSNotificationCenter defaultCenter] postNotificationName:VNMineProfileFavouriteCellDeleteNotification object:_indexPath];
            break;
            
        default:
            break;
    }
    if (tag==0) {
        [VNUtility showHUDText:@"视频已被删除!" forView:self.view];
    }
    else
    {
        [VNUtility showHUDText:@"视频删除成功!" forView:self.view];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)share:(id)sender {
    __weak typeof(self) weakSelf = self;

    [VNHTTPRequestManager isNewsDeleted:self.news.nid completion:^(BOOL isNewsDeleted,NSError *error)
     {
         //isNewsDeleted=YES;
         if (error) {
             NSLog(@"%@", error.localizedDescription);
         }
         else if (isNewsDeleted) {
             [self deleteCellAndPop:0];
         }
         else
         {
             UIActionSheet * shareActionSheet = [[UIActionSheet alloc] initWithTitle:@"分享到" delegate:weakSelf cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", nil];
             [shareActionSheet showFromTabBar:weakSelf.tabBarController.tabBar];
             shareActionSheet.tag = kTagShare;
             shareActionSheet.delegate = weakSelf;
         }
     }];

    /*UIActionSheet * shareActionSheet = [[UIActionSheet alloc] initWithTitle:@"分享到" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"微信朋友圈", @"微信好友",  @"新浪微博", @"QQ空间", @"QQ好友", @"腾讯微博", @"人人网", nil];
    [shareActionSheet showFromTabBar:self.tabBarController.tabBar];
    shareActionSheet.tag = kTagShare;
    shareActionSheet.delegate = self;*/
}

- (IBAction)sendComment:(id)sender {
    NSString *str = self.inputTextView.text;
    NSMutableString *commentStr = [[NSMutableString alloc] init];
    [commentStr setString:str];
    CFStringTrimWhitespace((CFMutableStringRef)commentStr);
    //NSLog(@"%@", commentStr);
    if (commentStr.length == 0) {
        [VNUtility showHUDText:@"发送内容为空!" forView:self.view];
        return;
    }
    else {
        if (!self.thresholdLabel.hidden) {
            [VNUtility showHUDText:@"发送内容字数超过140!" forView:self.view];
            return;
        }
        else {
            if ([self.inputTextView.text hasPrefix:@"回复"] && self.curComment!=nil && self.curComment.author!=nil) {
                //NSLog(@"%@",self.curComment);
                __weak typeof(self) weakSelf = self;
                [VNHTTPRequestManager replyComment:self.curComment.cid replyUser:self.curComment.author.uid replyNews:self.news.nid content:commentStr completion:^(BOOL succeed,BOOL isNewsDeleted,BOOL isCommentDeleted, VNComment *comment, int comment_count,NSError *error) {
                    //isCommentDeleted=YES;
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (isNewsDeleted) {
                        [self deleteCellAndPop:0];
                    }
                    else if (isCommentDeleted)
                    {
                        //NSLog(@"%@",_curIndexPath);
                        [weakSelf.commentArr removeObjectAtIndex:_curIndexPath.row];
                        [weakSelf.commentTableView deleteRowsAtIndexPaths:@[_curIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                        weakSelf.inputTextView.text=@"";
                        [weakSelf.inputTextView resignFirstResponder];
                        [VNUtility showHUDText:@"该评论已被删除!" forView:self.view];
                    }
                    else if (succeed) {
                        //[VNUtility showHUDText:@"回复成功!" forView:self.view];
                        self.inputTextView.text = @"";
                        self.inputBarHeightLC.constant = 44.0;
                        self.inputTextViewHeightLC.constant = 30.0;
                        [self.inputTextView resignFirstResponder];
                        if (comment) {
                            [self.commentArr insertObject:comment atIndex:0];
                            [self.commentTableView reloadData];
                        }
                        if (comment_count>10000) {
                            self.headerView.commentLabel.text=[NSString stringWithFormat:@"%d万",comment_count/10000];
                        }
                        else
                        {
                            self.headerView.commentLabel.text=[NSString stringWithFormat:@"%d",comment_count];
                        }
                        
                    }
                    else {
                        [VNUtility showHUDText:@"回复失败!" forView:self.view];
                    }
                }];
            }
            else {
                [VNHTTPRequestManager commentNews:self.news.nid content:commentStr completion:^(BOOL succeed,BOOL isNewsDeleted, VNComment *comment, int comment_count,NSError *error) {
                    //isNewsDeleted=YES;
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                    else if (isNewsDeleted)
                    {
                        [self deleteCellAndPop:0];
                    }
                    else if (succeed) {
                        //[VNUtility showHUDText:@"评论成功!" forView:self.view];
                        self.inputTextView.text = @"";
                        self.inputBarHeightLC.constant = 44.0;
                        self.inputTextViewHeightLC.constant = 30.0;
                        [self.inputTextView resignFirstResponder];
                        if (comment) {
                            [self.commentArr insertObject:comment atIndex:0];
                            [self.commentTableView reloadData];
                        }
                        if (comment_count>10000) {
                            self.headerView.commentLabel.text=[NSString stringWithFormat:@"%d万",comment_count/10000];
                        }
                        else
                        {
                            self.headerView.commentLabel.text=[NSString stringWithFormat:@"%d",comment_count];
                        }
                        
                    }
                    else {
                        [VNUtility showHUDText:@"评论失败!" forView:self.view];
                    }
                }];
            }
        }
    }
}

-(void)playVideo {
    NSLog(@"PlayMovieAction====");
    if (self.moviePlayer) {
        self.moviePlayer.view.hidden = NO;
        //[self.moviePlayer play];
        [self playAndCount];
        [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.playBtn addTarget:self action:@selector(pauseVideo) forControlEvents:UIControlEventTouchUpInside];
        isPlaying = YES;
    }
}
-(void)playAndCount
{
    [self.moviePlayer play];
    [MobClick event:@"video_play" label:@"newsDetail"];
}
- (void)pauseVideo {
    if (self.moviePlayer) {
        [self.moviePlayer pause];
        [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
        isPlaying = NO;
    }
}

-(void)videoFinishedPlayCallback:(NSNotification*)notify {
    self.moviePlayer.view.hidden = YES;
    [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    isPlaying = NO;
    NSLog(@"视频播放完成");
}

- (IBAction)switchEmoji:(id)sender {
    if (isDefaultKeyboard) {
        [self.keyboardToggleBtn setTitle:@"键盘" forState:UIControlStateNormal];
        if (!self.emojiKeyboardView) {
            self.emojiKeyboardView = [[AGEmojiKeyboardView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 216) dataSource:self isStandard:NO];
            self.emojiKeyboardView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
            self.emojiKeyboardView.delegate = self;
        }
        [self.inputTextView setInputView:self.emojiKeyboardView];
        [self.inputTextView becomeFirstResponder];
    }
    else {
        [self.keyboardToggleBtn setTitle:@"表情" forState:UIControlStateNormal];
        [self.inputTextView  setInputView:nil];
        [self.inputTextView  becomeFirstResponder];
    }
    [self.inputTextView reloadInputViews];
    isDefaultKeyboard = !isDefaultKeyboard;
}

- (IBAction)dismissViewTapped:(UITapGestureRecognizer *)sender {
    [self.inputTextView resignFirstResponder];
    self.dismissTapView.hidden = YES;
}

- (int)countWord:(NSString *)s
{
    int i,n=[s length],l=0,a=0,b=0;
    unichar c;
    for(i=0;i<n;i++){
        c=[s characterAtIndex:i];
        if(isblank(c)){
            b++;
        }else if(isascii(c)){
            a++;
        }else{
            l++;
        }
    }
    if(a==0 && l==0) return 0;
    return l+(int)ceilf((float)(a+b)/2.0);
}

- (void)updateHeightOfInputBar {
    int textCount = [self countWord:self.inputTextView.text];
    if (textCount > 140) {
        self.thresholdLabel.text = [NSString stringWithFormat:@"-%d", textCount-140];
        self.thresholdLabel.hidden = NO;
    }
    else {
        self.thresholdLabel.hidden = YES;
    }
    
    CGSize size = self.inputTextView.contentSize;
    NSLog(@"%@", NSStringFromCGSize(size));
    size.height -= 4;
    if (size.height >= 68) {
        size.height = 68;
    }
    else if (size.height <= 30) {
        size.height = 30;
    }
    
    if (size.height != self.inputTextViewHeightLC.constant) {
        
        CGFloat span = size.height - self.inputTextViewHeightLC.constant;
        
        self.inputBarHeightLC.constant +=span;
        self.inputTextViewHeightLC.constant +=span;
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //NSLog(@"%d",actionSheet.tag);
    if (actionSheet.tag == kTagShare || actionSheet.tag == kTagNews) {
        NSLog(@"%@", [UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray);
        //NSLog(@"%@", self.news.url);
        NSString *shareURL = self.news.url;
        if (!shareURL || [shareURL isEqualToString:@""]) {
            //shareURL = @"http://www.baidu.com";
            shareURL = [[NSString alloc]initWithFormat:@"http://www.shishangpai.com.cn/view.php?id=%d&start=1",self.news.nid];
            //NSLog(@"url:%@",shareURL);
        }
        NSString *snsName = nil;
        switch (buttonIndex) {
                //微信朋友圈
            case 0: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:3];
                [UMSocialData defaultData].extConfig.wechatTimelineData.url = shareURL;
            }
                break;
                //微信好友
            case 1: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:2];
                [UMSocialData defaultData].extConfig.wechatSessionData.url = shareURL;
            }
                break;
                //新浪微博
            case 2: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:0];
            }
                break;
                //QQ空间
            case 3: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:5];
                [UMSocialData defaultData].extConfig.qzoneData.url = shareURL;
            }
                break;
                //QQ好友
            case 4: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:6];
                [UMSocialData defaultData].extConfig.qqData.url = shareURL;
            }
                break;
                //腾讯微博
            case 5: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:1];
            }
                break;
                //人人网
            case 6: {
                snsName = [[UMSocialSnsPlatformManager sharedInstance].allSnsValuesArray objectAtIndex:7];
            }
                break;
                //取消或复制
            case 7: {
                if (actionSheet.tag == kTagShare) {
                    return ;
                }
                else {
                    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                    pasteboard.string = self.news.url;
                    [VNUtility showHUDText:@"已复制该文章链接" forView:self.view];
                }
            }
                break;
                //删除或举报
            case 8: {
                NSString *buttonTitle = [actionSheet buttonTitleAtIndex:8];
                if ([buttonTitle isEqualToString:@"删除"]) {
                    //TODO: 删除帖子
                    [actionSheet dismissWithClickedButtonIndex:9 animated:YES];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"确定要永久删除视频？" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
                    _deleteAlert=alert;
                    [alert show];
                    
                }
                else if ([buttonTitle isEqualToString:@"举报"]) {
                    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
                    if (userInfo && userInfo.count) {
                        NSString *uid = [userInfo objectForKey:@"openid"];
                        NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
                        if (uid && user_token) {
                            [VNHTTPRequestManager report:[NSString stringWithFormat:@"%d", self.news.nid] type:@"reportNews" userID:uid userToken:user_token completion:^(BOOL succeed, NSError *error) {
                                if (error) {
                                    NSLog(@"%@", error.localizedDescription);
                                }
                                else if (succeed) {
                                    [VNUtility showHUDText:@"举报成功!" forView:self.view];
                                    self.inputTextView.text = @"";
                                }
                                else {
                                    [VNUtility showHUDText:@"您已举报该文章" forView:self.view];
                                }
                            }];
                        }
                    }
                    else {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
                        [alert show];
                        return;
                    }
                }
            }
                break;
                //取消
            case 9: {
                return ;
            }
                break;
        }
        //设置分享内容，和回调对象
        if (buttonIndex < 7) {
            //NSString *shareText = [NSString stringWithFormat:@"我在用follow my style看到一个有趣的视频：“%@”，来自@“%@”快来看看吧~ %@", self.news.title,_news.author.name,_news.url];
            //NSString *shareText = [NSString stringWithFormat:@"分享%@的视频：“%@”，快来看看吧~ %@",  self.news.author.name,self.news.title,self.news.url];
            NSString *shareText = [NSString stringWithFormat:@"我用“时尚拍”分享了一段视频，不看你后悔一辈子！：“%@”",self.news.url];
            UIImage *shareImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:self.media.url]]];
            shareStr = shareText;
            
            [[UMSocialControllerService defaultControllerService] setShareText:shareText shareImage:shareImage socialUIDelegate:self];
            UMSocialSnsPlatform *snsPlatform = [UMSocialSnsPlatformManager getSocialPlatformWithName:snsName];
            NSLog(@"%@", snsPlatform);
            snsPlatform.snsClickHandler(self,[UMSocialControllerService defaultControllerService],YES);
        }
    }
    else if (actionSheet.tag == kTagCommentMine ||actionSheet.tag==kTagCommentMineNews) {
       // NSLog(@"%d", buttonIndex);
        switch (buttonIndex) {
                //回复
            case 0: {
                [self.inputTextView setText:[NSString stringWithFormat:@"回复@%@:", self.curComment.author.name]];
                [self.inputTextView becomeFirstResponder];
            }
                break;
                //查看个人主页
            case 1: {
                VNUser *user = self.curComment.author;
                NSString *mineUid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
                if (mineUid && [mineUid isEqualToString:user.uid]) {
                    VNMineProfileViewController *mineProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNMineProfileViewController"];
                    mineProfileViewController.isPush = YES;
                    [self.navigationController pushViewController:mineProfileViewController animated:YES];
                }
                else {
                    VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
                    profileViewController.uid = user.uid;
                    [self.navigationController pushViewController:profileViewController animated:YES];
                }
            }
                break;
                //删除评论
            case 2: {
                NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
                __weak typeof(self) weakSelf = self;
                if (userInfo && userInfo.count) {
                    NSString *uid = [userInfo objectForKey:@"openid"];
                    NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
                    if (uid && user_token) {
                        [VNHTTPRequestManager deleteComment:self.curComment.cid news:self.news.nid userID:uid userToken:user_token completion:^(BOOL succeed, BOOL isNewsDeleted,int comment_count,NSError *error) {
                            if (error) {
                                NSLog(@"%@", error.localizedDescription);
                            }
                            else if(isNewsDeleted)
                            {
                                [self deleteCellAndPop:0];
                            }
                            else if (succeed) {
                                self.inputTextView.text = @"";
                                [weakSelf.commentArr removeObjectAtIndex:weakSelf.curIndexPath.row];
                                if (weakSelf.curIndexPath.row == 0) {
                                    [self.commentTableView reloadData];
                                }
                                else {
                                    [self.commentTableView deleteRowsAtIndexPaths:@[weakSelf.curIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
                                }
                                
                                if (comment_count>10000) {
                                    weakSelf.headerView.commentLabel.text=[NSString stringWithFormat:@"%d万",comment_count/10000];
                                }
                                else
                                {
                                    weakSelf.headerView.commentLabel.text=[NSString stringWithFormat:@"%d",comment_count];
                                }

                                //weakSelf.inputTextView.text=@"";
                                //[weakSelf.inputTextView resignFirstResponder];
                                //[VNUtility showHUDText:@"删除评论成功!" forView:self.view];
                            }
                            else {
                                [VNUtility showHUDText:@"删除评论失败!" forView:self.view];
                            }
                        }];
                    }
                }
             }
                break;
                ///取消
            case 3: {
                return ;
            }
                break;
        }
    }
    else if (actionSheet.tag == kTagCommentAnybody) {
        NSLog(@"%d", buttonIndex);
        switch (buttonIndex) {
                //回复
            case 0: {
                [self.inputTextView setText:[NSString stringWithFormat:@"回复匿名:"]];
                [self.inputTextView becomeFirstResponder];
            }
                break;
                //举报评论
            case 1: {
                NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
                if (userInfo && userInfo.count) {
                    NSString *uid = [userInfo objectForKey:@"openid"];
                    NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
                    if (uid && user_token) {
                        [VNHTTPRequestManager report:[NSString stringWithFormat:@"%d", self.curComment.cid] type:@"reportComment" userID:uid userToken:user_token completion:^(BOOL succeed, NSError *error) {
                            if (error) {
                                NSLog(@"%@", error.localizedDescription);
                            }
                            else if (succeed) {
                                [VNUtility showHUDText:@"举报成功!" forView:self.view];
                                self.inputTextView.text = @"";
                                [self.commentTableView triggerPullToRefresh];
                            }
                            else {
                                [VNUtility showHUDText:@"您已举报该评论" forView:self.view];
                            }
                        }];
                    }
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
                    [alert show];
                    return;
                }
            }
                break;
                //取消
            case 2: {
                return ;
            }
                break;
        }
    }
    else if (actionSheet.tag == kTagCommentOtherUser) {
        NSLog(@"%d", buttonIndex);
        switch (buttonIndex) {
                //回复
            case 0: {
                NSLog(@"%@", self.curComment.author.name);
                [self.inputTextView setText:[NSString stringWithFormat:@"回复@%@:", self.curComment.author.name]];
                [self.inputTextView becomeFirstResponder];
            }
                break;
                //查看个人主页
            case 1: {
                //TODO:查看个人主页
                VNUser *user = self.curComment.author;
                NSString *mineUid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
                if (mineUid && [mineUid isEqualToString:user.uid]) {
                    VNMineProfileViewController *mineProfileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNMineProfileViewController"];
                    mineProfileViewController.isPush = YES;
                    [self.navigationController pushViewController:mineProfileViewController animated:YES];
                }
                else {
                    VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
                    profileViewController.uid = user.uid;
                    [self.navigationController pushViewController:profileViewController animated:YES];
                }
            }
                break;
                //举报评论
            case 2: {
                NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
                if (userInfo && userInfo.count) {
                    NSString *uid = [userInfo objectForKey:@"openid"];
                    NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
                    if (uid && user_token) {
                        [VNHTTPRequestManager report:[NSString stringWithFormat:@"%d", self.curComment.cid] type:@"reportComment" userID:uid userToken:user_token completion:^(BOOL succeed, NSError *error) {
                            if (error) {
                                NSLog(@"%@", error.localizedDescription);
                            }
                            else if (succeed) {
                                [VNUtility showHUDText:@"举报成功!" forView:self.view];
                                self.inputTextView.text = @"";
                                [self.commentTableView triggerPullToRefresh];
                            }
                            else {
                                [VNUtility showHUDText:@"您已举报该评论" forView:self.view];
                            }
                        }];
                    }
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
                    [alert show];
                    return;
                }
            }
                break;
                ///取消
            case 3: {
                return ;
            }
                break;
        }
    }
}

#pragma mark - UMSocialUIDelegate

-(void)didCloseUIViewController:(UMSViewControllerType)fromViewControllerType
{
    NSLog(@"didClose is %d",fromViewControllerType);
}

//下面得到分享完成的回调
-(void)didFinishGetUMSocialDataInViewController:(UMSocialResponseEntity *)response
{
    NSLog(@"didFinishGetUMSocialDataInViewController with response is %@",response);
    //根据`responseCode`得到发送结果,如果分享成功
    if(response.responseCode == UMSResponseCodeSuccess) {
        //得到分享到的微博平台名
        NSLog(@"share to sns name is %@",[[response.data allKeys] objectAtIndex:0]);
        [VNUtility showHUDText:@"分享成功!" forView:self.view];
        [VNHTTPRequestManager commentNews:self.news.nid content:shareStr completion:^(BOOL succeed, BOOL isNewsDeleted,VNComment *comment, int comment_count,NSError *error) {
            //isNewsDeleted=YES;
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (isNewsDeleted)
            {
                [self deleteCellAndPop:0];
            }
            else if (succeed) {
                if (comment) {
                    [self.commentArr insertObject:comment atIndex:0];
                    [self.commentTableView reloadData];
                    if (comment_count>10000) {
                        self.headerView.commentLabel.text=[NSString stringWithFormat:@"%d万",comment_count/10000];
                    }
                    else
                    {
                        self.headerView.commentLabel.text=[NSString stringWithFormat:@"%d",comment_count];
                    }
                    
                }
            }
        }];
    }
}
#pragma mark - Notification
-(void)replyCommentFromNotification{
//    NSDictionary *comment=@{@"cid":_pid,@"content":@"",@"date":@"",@"ding":[NSNumber numberWithInt:0],@"insert_time":@"",@"author":@{@"uid":_sender_id,@"name":_sender_name,@"avatar":@"",@"fans_count":@"",@"timestamp":@"",@"location":@"",@"sex":@"",@"main_uid":@""}};
////    _curComment=[[VNComment alloc]initWithDict:comment];
    //_curComment=nil;
    __weak typeof(self) weakSelf = self;
    [VNHTTPRequestManager commentByCid:[_pid intValue] completion:^(NSArray *comment, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            [weakSelf.commentArrNotify addObjectsFromArray:comment];
            NSLog(@"%@",weakSelf.commentArrNotify);
            weakSelf.curComment= [weakSelf.commentArrNotify objectAtIndex:0];
            if (weakSelf.curComment==nil) {
                [VNUtility showHUDText:@"该评论已被删除！" forView:weakSelf.view];
            }
            else
            {
                [self.inputTextView setText:[NSString stringWithFormat:@"回复@%@:", self.sender_name]];
                //[self.inputTextField becomeFirstResponder];
            }
            //NSLog(@"%@",_curComment);
           // [self.commentTableView reloadData];
        }
    }];
    //NSLog(@"%@",self.view);
}

#pragma mark - UIKeyboardNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    
    isKeyboardShowing = YES;
    
    if (self.moviePlayer && isPlaying) {
        [self.moviePlayer pause];
        [self.playBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.playBtn addTarget:self action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
        isPlaying = NO;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         
                         CGRect frame = self.commentTableView.frame;
                         frame.size.height += keyboardHeight;
                         frame.size.height -= keyboardRect.size.height;
                         self.commentTableView.frame = frame;
                         
                         frame = self.inputBar.frame;
                         frame.origin.y += keyboardHeight;
                         frame.origin.y -= keyboardRect.size.height;
                         self.inputBar.frame = frame;
                         
                         self.inputBarBottomLC.constant -=keyboardHeight;
                         self.inputBarBottomLC.constant +=keyboardRect.size.height;
                         NSLog(@"%f", self.inputBarBottomLC.constant);
                         keyboardHeight = keyboardRect.size.height;
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.3 animations:^{
                             self.dismissTapView.hidden = NO;
                         }];
                     }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView animateWithDuration:animationDuration
                     animations:^{
                         CGRect frame = self.commentTableView.frame;
                         frame.size.height += keyboardHeight;
                         self.commentTableView.frame = frame;
                         
                         frame = self.inputBar.frame;
                         frame.origin.y += keyboardHeight;
                         self.inputBar.frame = frame;
                         
                         self.inputBarBottomLC.constant -=keyboardHeight;
                         keyboardHeight = 0;
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.3 animations:^{
                             self.dismissTapView.hidden = YES;
                         }];
                     }];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (_deleteAlert ==alertView) {
        if (buttonIndex==1) {
            NSString *mineUid = [[[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser] objectForKey:@"openid"];
            NSString *user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
            if (mineUid && user_token) {
                [VNHTTPRequestManager deleteNews:_news.nid userID:mineUid userToken:user_token completion:^(BOOL succeed,int news_count,NSError *error)
                 {
                     if (error) {
                         NSLog(@"%@", error.localizedDescription);
                     }
                     else if(succeed)
                     {
                         [self deleteCellAndPop:1];
                     }
                     else
                     {
                         [VNUtility showHUDText:@"删除视频失败" forView:self.view];
                     }
                 }];
            }
        }
        else
        {return;}
        return;
    }
    if (buttonIndex == 0) {
        return;
    }
    else if (buttonIndex == 1) {
        VNLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNLoginViewController"];
        [self presentViewController:loginViewController animated:YES completion:nil];
    }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [self updateHeightOfInputBar];
}

#pragma mark - AGEmojiKeyboardViewDelegate

- (void)emojiKeyBoardView:(AGEmojiKeyboardView *)emojiKeyBoardView didUseEmoji:(NSString *)emoji {
    self.inputTextView.text = [self.inputTextView.text stringByAppendingString:emoji];
    [self updateHeightOfInputBar];
}

- (void)emojiKeyBoardViewDidPressBackSpace:(AGEmojiKeyboardView *)emojiKeyBoardView {
    NSString *newStr = nil;
    if (self.inputTextView.text.length>0) {
        if (self.inputTextView.text.length > 1 && [[[self.emojiKeyboardView emojis] objectForKey:@"People"] containsObject:[self.inputTextView.text substringFromIndex:self.inputTextView.text.length-2]]) {
            newStr=[self.inputTextView.text substringToIndex:self.inputTextView.text.length-2];
        }
        else {
            newStr=[self.inputTextView.text substringToIndex:self.inputTextView.text.length-1];
        }
        self.inputTextView.text=newStr;
    }
    [self updateHeightOfInputBar];
}

#pragma mark - AGEmojiKeyboardViewDataSource

- (AGEmojiKeyboardViewCategoryImage)defaultCategoryForEmojiKeyboardView:(AGEmojiKeyboardView *)emojiKeyboardView {
    return AGEmojiKeyboardViewCategoryImageFace;
}

- (UIImage *)backSpaceButtonImageForEmojiKeyboardView:(AGEmojiKeyboardView *)emojiKeyboardView {
    return [UIImage imageNamed:@"60-60Delete"];
}

@end
