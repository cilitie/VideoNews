//
//  VNNotificationViewController.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-7-10.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNNotificationViewController.h"
#import "VNNotificationReplyTableViewCell.h"
#import "VNNotificationUserTableViewCell.h"
//#import "VNNotificationNewUserTableViewCell.h"
#import "VNNewsDetailViewController.h"
#import "SVPullToRefresh.h"
#import "VNProfileViewController.h"

//#import "VNHTTPRequestManager.h"
//#import "AFNetworking.h"
//////上传相关
//#import "OSSClient.h"

////OSS Bucket的基址，可以是自定义域名或者OSS默认域名
////#define OSS_BUCKET_BASE_URL     "http://jwx-ios.oss-cn-hangzhou.aliyuncs.com/"
//#define OSS_BUCKET_BASE_URL     "http://fashion-test.oss-cn-beijing.aliyuncs.com/"
////#define OSS_BUCKET_BASE_URL     "http://oss-cn-beijing.aliyuncs.com/"
////用于计算签名的服务端接口服务
////#define OSS_SIGN_CALC_SERVICE   "http://10.32.179.161:8080/ossFileApi/sign.json"
//#define OSS_SIGN_CALC_SERVICE   "http://182.92.103.134:8080/engine/signature.php"

//qiniu上传相关

@interface VNNotificationViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate> {
    BOOL userScrolling;
    CGPoint initialScrollOffset;
    CGPoint previousScrollOffset;
    BOOL isToBottom;
    BOOL isTabBarHidden;
    BOOL firstLoad;
}

@property (weak, nonatomic) IBOutlet UITableView *messageTableView;

@property (strong, nonatomic) NSMutableArray *messageArr;

@property (strong,nonatomic)VNMessage *curMessage;

@property (strong,nonatomic)NSString *openUid;

@property (strong,nonatomic)NSString *user_token;

@property (strong,nonatomic)UILabel *label;

- (IBAction)clearMessage:(id)sender;
@end

@implementation VNNotificationViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _messageArr = [NSMutableArray arrayWithCapacity:0];
        isTabBarHidden = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    firstLoad=YES;
    // Do any additional setup after loading the VNNotificationTableViewCell.xib
    //[self uploadImage:@"/image/test.txt" Bucket:@"fashion-test"];
    _messageTableView.showsVerticalScrollIndicator=NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeCellForNewsDeleted:) name:VNNotificationCellDeleteNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userReLogin:) name:VNLoginNotification object:nil];
    [self removeBadgeValue];

    [self.messageTableView registerNib:[UINib nibWithNibName:@"VNNotificationReplyTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNNotificationReplyTableViewCellIdentifier"];
    //[self.messageTableView registerNib:[UINib nibWithNibName:@"VNNotificationUserTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNNotificationUserTableViewCellIdentifier"];
    [self.messageTableView registerNib:[UINib nibWithNibName:@"VNNotificationUserTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNNotificationUserTableViewCellIdentifier"];
    

  //zmy add
    VNAuthUser *authUser = nil;
    NSString *user_token = @"";
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:isLogin] boolValue]) {
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        if (userInfo.count) {
            authUser = [[VNAuthUser alloc] initWithDict:userInfo];
        }
        user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
        _openUid=authUser.openid;
        _user_token=user_token;
    }
    else {
        return;
    }
    //
    __weak typeof(self) weakSelf = self;
    _label = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 218, 300, 20)];
//    _openUid=authUser.openid;
//    _user_token=user_token;
//
//    [VNHTTPRequestManager messageListForUser:authUser.openid userToken:user_token timestamp:[VNHTTPRequestManager timestamp] completion:^(NSArray *messageArr, NSError *error) {
//        if (error) {
//            NSLog(@"%@", error.localizedDescription);
//        }
//        else {
//            [weakSelf.messageArr addObjectsFromArray:messageArr];
//            [weakSelf.messageTableView reloadData];
//        }
//    }];
    
    [self.messageTableView addPullToRefreshWithActionHandler:^{
        // FIXME: Hard code
        //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //zmy add
            /*VNAuthUser *authUser = nil;
            NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
            if (userInfo.count) {
                authUser = [[VNAuthUser alloc] initWithDict:userInfo];
            }
           NSString * user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];*/
            //
            NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
            [VNHTTPRequestManager messageListForUser:_openUid userToken:_user_token timestamp:refreshTimeStamp completion:^(NSArray *messageArr, NSError *error) {
                if (error) {
                    NSLog(@"error:%@", error.localizedDescription);
                }
                else {
                    
                    [weakSelf.messageArr removeAllObjects];
                    [weakSelf.messageArr addObjectsFromArray:messageArr];
                    [weakSelf.messageTableView reloadData];
                    [self removeBadgeValue];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (messageArr.count==0) {
                        weakSelf.label.text=@"你尚无任何通知";
                    }
                    [weakSelf.messageTableView.pullToRefreshView stopAnimating];
                });
            }];
        });
    }];
    
    [self.messageTableView addInfiniteScrollingWithActionHandler:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *moreTimeStamp = nil;
        if (weakSelf.messageArr.count) {
            VNMessage *lastMessage = [weakSelf.messageArr lastObject];
            //            NSLog(@"%@", lastComent.insert_time);
            moreTimeStamp = lastMessage.time;
        }
        else {
            moreTimeStamp = [VNHTTPRequestManager timestamp];
        }
        
        [VNHTTPRequestManager messageListForUser:_openUid userToken:_user_token timestamp:moreTimeStamp completion:^(NSArray *commemtArr, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else {
                [weakSelf.messageArr addObjectsFromArray:commemtArr];
                [weakSelf.messageTableView reloadData];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.messageTableView.infiniteScrollingView stopAnimating];
            });
        }];
        });
    }];
    [self.messageTableView triggerPullToRefresh];
    
    [self.messageTableView setTableFooterView:[[UIView alloc] init]];
}

-(void)removeBadgeValue
{
    UITabBarController *tabBarViewController = self.tabBarController;
    UITabBarItem *item=[tabBarViewController.tabBar.items objectAtIndex:3];
    if (item.badgeValue!=nil)
    {
        item.badgeValue=nil;
    }
    [[UIApplication sharedApplication ] setApplicationIconBadgeNumber:0];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
//    if (isTabBarHidden) {
//        [self showTabBar];
//    }
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (firstLoad) {
        firstLoad=NO;
        return;
    }
    //[self.messageTableView triggerPullToRefresh];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //zmy add
        VNAuthUser *authUser = nil;
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        if (userInfo.count) {
            authUser = [[VNAuthUser alloc] initWithDict:userInfo];
        }
        NSString * user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
        //
        NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
        [VNHTTPRequestManager messageListForUser:authUser.openid userToken:user_token timestamp:refreshTimeStamp completion:^(NSArray *messageArr, NSError *error) {
            if (error) {
                NSLog(@"error:%@", error.localizedDescription);
            }
            else {
                
                [self removeBadgeValue];
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (messageArr.count==0) {
                        weakSelf.label.text=@"你尚无任何通知";
                    }
                    else
                    {
                        [weakSelf.messageArr removeAllObjects];
                        [weakSelf.messageArr addObjectsFromArray:messageArr];
                        [weakSelf.messageTableView reloadData];
                    }
                });
            }
        }];
    });

    [self removeBadgeValue];
}

//-(void)uploadImage:(NSString *)filePath Bucket:(NSString *)bucket
//{
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    NSString *path=[NSString stringWithFormat:@"%@%@",bucket,filePath];
//    
//    NSDictionary *parameters =@{@"method":@"PUT",@"path":path};
//        NSString *URLStr = [VNHost stringByAppendingString:@"signature.php"];
//    //NSString *URLStr=@"fashion-test.oss-cn-beijing.aliyuncs.com";
//    [manager POST:URLStr parameters:parameters
//          success:^(AFHTTPRequestOperation *operation,id responseObject) {
//        //NSLog(@"Success: %@", responseObject);
//              //获得签名信息
//        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
//            NSString *(^signCalculatorBlock)(OSSMethod ,NSString *,NSMutableDictionary *)=^(OSSMethod method,NSString *ossFilePath,NSMutableDictionary *options){
//                NSLog(@"GET SIGN FROM SERVER");
//                //return @"OSS bmJjNn9pYaftA46d:yh55h8wESbuoC0nET7BJt0qTHps=";
//                //return getSignFromServer(method,ossFilePath,options);
//                return [responseObject objectForKey:@"signature"];
//            };
//
//            
//            OSSClient *ossClient=[[OSSClient alloc] initWithBucketBaseUrl:[NSURL URLWithString:@OSS_BUCKET_BASE_URL]
//                                                         bucketPermission:PRIVATE
//                                                           signCalculator:signCalculatorBlock
//                                                                     Date:[responseObject objectForKey:@"date"]
//                                  ];
//            
//            NSData *data=[@"HELLO OBJECTIVE C - FROM IOS\n" dataUsingEncoding:NSASCIIStringEncoding];
//            
//            OSSMethodResult *result=nil;
//            //NSMutableDictionary *options=nil;
//            
//            result=[ossClient putFile:filePath data:data options:nil];
//            //NSLog(@"%@",result.headers);
//            //NSLog(@"%@",result.error);
//            //NSLog(@"%@",result.data);
//            if (result.error==nil && result.statusCode==200) {
//                NSLog(@"PUT OK");
//            }
//
//        }
//    } failure:^(AFHTTPRequestOperation *operation,NSError *error) {
//        //NSLog(@"%@",operation.request.URL.absoluteString);
//        //NSLog(@"%@",operation);
//        NSLog(@"Error: %@", error);
//        
//        
//    }];
//}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:VNNotificationCellDeleteNotification object:nil ];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:VNLoginNotification object:nil ];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
   // NSLog(@"array count:%d",self.messageArr.count);
    return self.messageArr.count ? self.messageArr.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.messageArr.count) {
        VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
        NSString *cellIdentifier = @"VNNotificationUserTableViewCellIdentifier";
        if ([message.type isEqualToString:@"comment"] || [message.type isEqualToString:@"news"]) {
            cellIdentifier = @"VNNotificationReplyTableViewCellIdentifier";
        }
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
        __weak typeof (self)weakSelf=self;
        if (cell) {
            if ([message.type isEqualToString: @"user"]) {
                VNNotificationUserTableViewCell *userCell = (VNNotificationUserTableViewCell *)cell;
                //VNNotificationNewUserTableViewCell *userCell=(VNNotificationNewUserTableViewCell *)cell;
                userCell.message = message;
                __weak typeof(userCell) weakUserCell = userCell;
                userCell.tapHandler = ^(){
                    VNProfileViewController *profileViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
                    VNUser *user = weakUserCell.message.sender;
                    profileViewController.uid = user.uid;
                    [weakSelf.navigationController pushViewController:profileViewController animated:YES];
                };
                [userCell reload];
            }
            else if ([message.type isEqualToString:@"comment"] || [message.type isEqualToString:@"news"]) {
                VNNotificationReplyTableViewCell *replyCell = (VNNotificationReplyTableViewCell *)cell;
                __weak typeof(replyCell) weakReplyCell = replyCell;
                replyCell.tapHandler = ^(){
                    VNProfileViewController *profileViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
                    VNUser *user = weakReplyCell.message.sender;
                    profileViewController.uid = user.uid;
                    [weakSelf.navigationController pushViewController:profileViewController animated:YES];
                };
                replyCell.message = message;
                [replyCell reload];
            }
        }
        return cell;
    }
    else {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        
        _label.font = [UIFont systemFontOfSize:15.0];
        _label.text = @"加载中...";
        _label.textColor = [UIColor colorWithRGBValue:0x474747];
        _label.textAlignment = NSTextAlignmentCenter;
        [cell addSubview:_label];
        return cell;
    }
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.messageArr.count) {
        VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
        _curMessage=message;
        if ([message.type isEqualToString:@"user"]) {
            NSLog(@"uid:%@",message.sender.uid);
            VNProfileViewController *profileViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNProfileViewController"];
            VNUser *user = message.sender;
            profileViewController.uid = user.uid;
            [self.navigationController pushViewController:profileViewController animated:YES];
        }
        else if([message.type isEqualToString:@"comment"]||[message.type isEqualToString:@"news"]) {
            VNNewsDetailViewController *newsDetailViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNNewsDetailViewController"];
            newsDetailViewController.news = _curMessage.news;
            newsDetailViewController.indexPath=indexPath;
            newsDetailViewController.pid=[NSNumber numberWithInt:_curMessage.reply_pid];
            newsDetailViewController.sender_id=_curMessage.sender.uid;
            newsDetailViewController.sender_name=_curMessage.sender.name;
            newsDetailViewController.hidesBottomBarWhenPushed = YES;
            newsDetailViewController.controllerType = SourceViewControllerTypeNotification;
            [self.navigationController pushViewController:newsDetailViewController animated:YES];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.messageArr.count) {
        VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
        if ([message.type isEqualToString:@"comment"] || [message.type isEqualToString:@"news"]) {
            return [self cellHeightFor:message];
        }
        else {
            return 80;
        }
    }
    else {
        return 456;
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_messageArr.count==0) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self)weakSelf=self;
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (self.messageArr.count) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                VNMessage *message = [weakSelf.messageArr objectAtIndex:indexPath.row];
                [VNHTTPRequestManager deleteMessage:[NSString stringWithFormat:@"%d", message.mid] completion:^(BOOL succeed, NSError *error) {
                    
                    if (error) {
                        NSLog(@"%@", error.localizedDescription);
                    }
                }];
                dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.messageArr removeObjectAtIndex:indexPath.row];
                if (indexPath.row == 0) {
                    [weakSelf.messageTableView reloadData];
                }
                else {
                    [weakSelf.messageTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
                }
                });
            });
        }
    }
}

#pragma mark - SEL

- (void)removeCellForNewsDeleted:(NSNotification *)notification {
    //int newsNid = [notification.object integerValue];
    NSIndexPath *index=notification.object;
    //NSLog(@"%d",index.row);
    [_messageArr removeObjectAtIndex:index.row];
    if (index.row == 0) {
        [self.messageTableView reloadData];
    }
    else {
        [self.messageTableView deleteRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationLeft];
    }
}

-(void)userReLogin:(NSNotification *)notification
{
    VNAuthUser *authUser = nil;
    NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    if (userInfo.count) {
        authUser = [[VNAuthUser alloc] initWithDict:userInfo];
    }
    _openUid=authUser.openid;
    _user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
    [_messageArr removeAllObjects];
    [_messageTableView reloadData];
}


- (CGFloat)cellHeightFor:(VNMessage *)message {
    __block CGFloat cellHeight = 120.0;
    
    NSDictionary *attribute = @{NSFontAttributeName:[UIFont systemFontOfSize:15.0]};
    CGRect rect = [message.reply_text boundingRectWithSize:CGSizeMake(260.0, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    cellHeight += CGRectGetHeight(rect);
    NSLog(@"%f", cellHeight);
    
    if ([message.type isEqualToString:@"comment"]) {
        NSString *text = [NSString stringWithFormat:@"在\"%@\"中回复了你的评论：\n\"%@\"", message.news.title, message.text];
        rect = [text boundingRectWithSize:CGSizeMake(260.0, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        cellHeight += CGRectGetHeight(rect);
        NSLog(@"%f", cellHeight);
    }
    else if ([message.type isEqualToString:@"news"]) {
        NSString *text = [NSString stringWithFormat:@"在你的大作\"%@\"中评论了你",message.news.title];
        rect = [text boundingRectWithSize:CGSizeMake(260.0, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        cellHeight += CGRectGetHeight(rect);
        NSLog(@"%f", cellHeight);
    }
    
    return cellHeight;
}

#pragma mark - SEL

- (IBAction)clearMessage:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"确定清空全部消息?" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
    [alert show];
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
    
    if (contentOffset >= 0 && (scrollView.contentOffset.y + self.messageTableView.frame.size.height < scrollView.contentSize.height) && scrollView.contentOffset.y > 24) {
        [self hideTabBar];
    }
    
    //scroll to bottom, quit fullScreen
    if (scrollView.contentOffset.y + self.messageTableView.frame.size.height >= scrollView.contentSize.height+49) {
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
        __weak typeof(self)weakSelf=self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)),dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [VNHTTPRequestManager deleteMessage:@"" completion:^(BOOL succeed, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else if (succeed) {
                [VNUtility showHUDText:@"清空成功!" forView:weakSelf.view];
                [weakSelf.messageArr removeAllObjects];
                [weakSelf.messageTableView reloadData];
            }
        }];
        });
    }
}

@end
