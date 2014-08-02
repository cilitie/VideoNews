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

#import "VNNewsDetailViewController.h"

#import "SVPullToRefresh.h"

#import "VNUserViewController.h"

//#import "VNHTTPRequestManager.h"
//#import "AFNetworking.h"
//////上传相关
//#import "OSSClient.h"

#import "VNTabBarViewController.h"
////OSS Bucket的基址，可以是自定义域名或者OSS默认域名
////#define OSS_BUCKET_BASE_URL     "http://jwx-ios.oss-cn-hangzhou.aliyuncs.com/"
//#define OSS_BUCKET_BASE_URL     "http://fashion-test.oss-cn-beijing.aliyuncs.com/"
////#define OSS_BUCKET_BASE_URL     "http://oss-cn-beijing.aliyuncs.com/"
////用于计算签名的服务端接口服务
////#define OSS_SIGN_CALC_SERVICE   "http://10.32.179.161:8080/ossFileApi/sign.json"
//#define OSS_SIGN_CALC_SERVICE   "http://182.92.103.134:8080/engine/signature.php"

//qiniu上传相关

@interface VNNotificationViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *messageTableView;

@property (strong, nonatomic) NSMutableArray *messageArr;

@property (strong,nonatomic)VNMessage *curMessage;

@property (strong,nonatomic)NSString *openUid;

@property (strong,nonatomic)NSString *user_token;

@end

@implementation VNNotificationViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _messageArr = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the VNNotificationTableViewCell.xib
    //[self uploadImage:@"/image/test.txt" Bucket:@"fashion-test"];
    
    [self removeBadgeValue];

    [self.messageTableView registerNib:[UINib nibWithNibName:@"VNNotificationReplyTableViewCell" bundle:nil] forCellReuseIdentifier:@"VNNotificationReplyTableViewCellIdentifier"];
    [self.messageTableView registerNib:[UINib nibWithNibName:@"VNNotificationUserTableViewCell" bundle:nil] forCellReuseIdentifier:@"VNNotificationUserTableViewCellIdentifier"];
    
    VNAuthUser *authUser = nil;
    NSString *user_token = @"";
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:isLogin] boolValue]) {
        NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
        if (userInfo.count) {
            authUser = [[VNAuthUser alloc] initWithDict:userInfo];
        }
        user_token = [[NSUserDefaults standardUserDefaults] objectForKey:VNUserToken];
        //NSLog(@"uid:%@",authUser.openid);
    }
    else {
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"亲~~你还没有登录哦~~" message:nil delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"登录", nil];
        //[alert show];
        return;
    }
    //userToken:(NSString *)user_token
    __weak typeof(self) weakSelf = self;
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSString *refreshTimeStamp = [VNHTTPRequestManager timestamp];
            [VNHTTPRequestManager messageListForUser:authUser.openid userToken:user_token timestamp:refreshTimeStamp completion:^(NSArray *messageArr, NSError *error) {
                if (error) {
                    NSLog(@"error:%@", error.localizedDescription);
                }
                else {
                    [weakSelf.messageArr removeAllObjects];
                    [weakSelf.messageArr addObjectsFromArray:messageArr];
                    [weakSelf.messageTableView reloadData];
                    [self removeBadgeValue];
                }
                [weakSelf.messageTableView.pullToRefreshView stopAnimating];
            }];;
        });
    }];
    
    [self.messageTableView addInfiniteScrollingWithActionHandler:^{
        NSString *moreTimeStamp = nil;
        if (weakSelf.messageArr.count) {
            VNMessage *lastMessage = [weakSelf.messageArr lastObject];
            //            NSLog(@"%@", lastComent.insert_time);
            moreTimeStamp = lastMessage.time;
        }
        else {
            moreTimeStamp = [VNHTTPRequestManager timestamp];
        }
        
        [VNHTTPRequestManager messageListForUser:authUser.openid userToken:user_token timestamp:moreTimeStamp completion:^(NSArray *commemtArr, NSError *error) {
            if (error) {
                NSLog(@"%@", error.localizedDescription);
            }
            else {
                [weakSelf.messageArr addObjectsFromArray:commemtArr];
                [weakSelf.messageTableView reloadData];
            }
            [weakSelf.messageTableView.infiniteScrollingView stopAnimating];
        }];
    }];
    [self.messageTableView triggerPullToRefresh];
}

-(void)removeBadgeValue
{
    VNTabBarViewController *tabBarViewController=(VNTabBarViewController *)self.tabBarController;
    UITabBarItem *item=[tabBarViewController.tabBar.items objectAtIndex:3];
    if (item.badgeValue!=nil)
    {
        item.badgeValue=nil;
    }
    [[UIApplication sharedApplication ] setApplicationIconBadgeNumber:0];
}

-(void)viewWillAppear:(BOOL)animated
{
//    [self.messageTableView triggerPullToRefresh];
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
    NSLog(@"array count:%d",self.messageArr.count);
    return self.messageArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
    NSString *cellIdentifier = @"VNNotificationUserTableViewCellIdentifier";
    if ([message.type isEqualToString:@"comment"] || [message.type isEqualToString:@"news"]) {
        cellIdentifier = @"VNNotificationReplyTableViewCellIdentifier";
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (cell) {
        if ([message.type isEqualToString: @"user"]) {
            VNNotificationUserTableViewCell *userCell = (VNNotificationUserTableViewCell *)cell;
            userCell.message = message;
            [userCell reload];
        }
        else if ([message.type isEqualToString:@"comment"] || [message.type isEqualToString:@"news"])
        {
            VNNotificationReplyTableViewCell *replyCell = (VNNotificationReplyTableViewCell *)cell;
            replyCell.message = message;
            [replyCell reload];
        }
    }
        return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
    _curMessage=message;
    if ([message.type isEqualToString:@"user"]) {
        NSLog(@"uid:%@",message.sender.uid);
        [self performSegueWithIdentifier:@"pushVNUserViewControllerForNotification" sender:self];
    }
    else if([message.type isEqualToString:@"comment"]||[message.type isEqualToString:@"news"])
    {
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"replyCommentFromNotification" object:self];
        
        [self performSegueWithIdentifier:@"pushVNNewsDetailViewControllerForNotification" sender:self];
        
    }
    //UIActionSheet *actionSheet = nil;
    //NSDictionary *userInfo = [[NSUserDefaults standardUserDefaults] objectForKey:VNLoginUser];
    //NSString *mineID = [userInfo objectForKey:@"openid"];
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
    if ([message.type isEqualToString:@"comment"] || [message.type isEqualToString:@"news"]) {
        return [self cellHeightFor:message];
    }
    else {
        return 80;
    }
}

#pragma mark - SEL

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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"pushVNNewsDetailViewControllerForNotification"]) {
        VNNewsDetailViewController *newsDetailViewController = [segue destinationViewController];
        //newsDetailViewController.news = [self.categoryNewsArr objectAtIndex:selectedItemIndex];
        newsDetailViewController.news=_curMessage.news;
        
        newsDetailViewController.pid=[NSNumber numberWithInt:_curMessage.reply_pid];
        newsDetailViewController.sender_id=_curMessage.sender.uid;
        newsDetailViewController.sender_name=_curMessage.sender.name;
        //newsDetailViewController.pid=[NSNumber numberWithInt:_curMessage.pid];
        newsDetailViewController.controllerType = SourceViewControllerTypeNotification;
        newsDetailViewController.hidesBottomBarWhenPushed = YES;
    }
    if ([segue.identifier isEqualToString:@"pushVNUserViewControllerForNotification"]) {
        VNUserViewController *newsDetailViewController = [segue destinationViewController];
        newsDetailViewController.uid=_curMessage.sender.uid;
    }
    
}


@end
