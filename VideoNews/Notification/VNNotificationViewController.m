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

#import "UIImageView+AFNetworking.h"
#import "UIButton+AFNetworking.h"

#import "SVPullToRefresh.h"

#import "VNUserViewController.h"

#import "VNHTTPRequestManager.h"
#import "AFNetworking.h"
////上传相关
#import "OSSClient.h"
//OSS Bucket的基址，可以是自定义域名或者OSS默认域名
//#define OSS_BUCKET_BASE_URL     "http://jwx-ios.oss-cn-hangzhou.aliyuncs.com/"
#define OSS_BUCKET_BASE_URL     "http://oss-cn-beijing.aliyuncs.com/"
//用于计算签名的服务端接口服务
//#define OSS_SIGN_CALC_SERVICE   "http://10.32.179.161:8080/ossFileApi/sign.json"
#define OSS_SIGN_CALC_SERVICE   "http://182.92.103.134:8080/engine/signature.php"

//#import "VNNotificationTableViewController.h"

@interface VNNotificationViewController ()

@property (weak, nonatomic) IBOutlet UITableView *messageTableView;

@property (strong, nonatomic) NSMutableArray *messageArr;

@property (strong,nonatomic)VNMessage *curMessage;

@end

@implementation VNNotificationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

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
    [self uploadImage:@"/image/test.txt" Bucket:@"fashion-test"];
    [self.messageTableView registerNib:[UINib nibWithNibName:@"VNNotificationReplyTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNNotificationReplyTableViewCellIdentifier"];
    [self.messageTableView registerNib:[UINib nibWithNibName:@"VNNotificationUserTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNNotificationUserTableViewCellIdentifier"];
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

    [VNHTTPRequestManager messageListForUser:authUser.openid userToken:user_token timestamp:[VNHTTPRequestManager timestamp] completion:^(NSArray *messageArr, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            [weakSelf.messageArr addObjectsFromArray:messageArr];
            [weakSelf.messageTableView reloadData];
        }
    }];
    
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


-(void)uploadImage:(NSString *)filePath Bucket:(NSString *)bucket
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *path=[NSString stringWithFormat:@"%@%@",bucket,filePath];
    //NSData *postData = [path dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    //NSLog(@"%@",path);
    //path=@"fashion-test/image/test.txt";
    NSDictionary *parameters =@{@"method":@"PUT",@"path":path};
    //@"fashion-test/image/test.txt"
    //,@"policy":@"value2",@"Signature":@"value"@"OSSAccessKeyId":@"bmJjNn9pYaftA46d",
    //NSDictionary *parameters =@{@"uid":@"/thumbnail/150-150QQ.png"};
    //NSData *imageData = UIImageJPEGRepresentation([UIImage imageNamed:@"150-150QQ.png"], 1.0);//fashion-test.oss-cn-beijing.aliyuncs.com
    
    NSString *URLStr = [VNHost stringByAppendingString:@"signature.php"];
    //NSString *URLStr=@"fashion-test.oss-cn-beijing.aliyuncs.com";
    [manager POST:URLStr parameters:parameters
          success:^(AFHTTPRequestOperation *operation,id responseObject) {
        NSLog(@"Success: %@", responseObject);
              //获得签名信息
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSString *(^signCalculatorBlock)(OSSMethod ,NSString *,NSMutableDictionary *)=^(OSSMethod method,NSString *ossFilePath,NSMutableDictionary *options){
                NSLog(@"GET SIGN FROM SERVER");
                //return @"OSS bmJjNn9pYaftA46d:yh55h8wESbuoC0nET7BJt0qTHps=";
                //return getSignFromServer(method,ossFilePath,options);
                return [responseObject objectForKey:@"signature"];
            };

            
            OSSClient *ossClient=[[OSSClient alloc] initWithBucketBaseUrl:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@",@OSS_BUCKET_BASE_URL,bucket]]
                                                         bucketPermission:PRIVATE
                                                           signCalculator:signCalculatorBlock];
            NSData *data=[@"HELLO OBJECTIVE C - FROM IOS\n" dataUsingEncoding:NSASCIIStringEncoding];
            
            OSSMethodResult *result=nil;
            //NSMutableDictionary *options=nil;
            
            result=[ossClient putFile:filePath data:data options:nil];
            if (result.error==nil && result.statusCode==200) {
                NSLog(@"PUT OK");
            }

        }
    } failure:^(AFHTTPRequestOperation *operation,NSError *error) {
        //NSLog(@"%@",operation.request.URL.absoluteString);
        //NSLog(@"%@",operation);
        NSLog(@"Error: %@", error);
        
        
    }];
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
    NSLog(@"array count:%d",self.messageArr.count);
    return self.messageArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
    
    if ([message.type isEqualToString: @"user"]) {
        VNNotificationReplyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNNotificationUserTableViewCellIdentifier"];
        [cell.thumbnail setImageForState:UIControlStateNormal withURL:[NSURL URLWithString:message.sender.avatar] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
        [cell.thumbnail.layer setCornerRadius:CGRectGetHeight([cell.thumbnail bounds]) / 2];
        cell.thumbnail.layer.masksToBounds = YES;
        cell.nameLabel.text=message.sender.name;
        //NSString *text=[NSString stringWithFormat:@"@%@关注了你",message.sender.name];
        cell.contentLabel.text=@"关注了你";
        cell.timeLabel.text=message.time;
        return cell;
    }
    else if ([message.type isEqualToString:@"comment"])
    {
        VNNotificationReplyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNNotificationReplyTableViewCellIdentifier"];
        [cell.thumbnail setImageForState:UIControlStateNormal withURL:[NSURL URLWithString:message.sender.avatar] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
        [cell.thumbnail.layer setCornerRadius:CGRectGetHeight([cell.thumbnail bounds]) / 2];
        cell.thumbnail.layer.masksToBounds = YES;
        cell.nameLabel.text=message.sender.name;
        NSString *text=[NSString stringWithFormat:@"在\"%@\"中回复了你的评论：\n\"%@\"",message.news.title,message.text];
        cell.contentLabel.text=text;
        cell.timeLabel.text=message.time;
        //cell.contentLabel.numberOfLines=0;
        NSDictionary *attribute = @{NSFontAttributeName:cell.contentLabel.font};
        CGRect rect = [cell.contentLabel.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.contentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        //    NSLog(@"%@", NSStringFromCGRect(rect));
        CGRect titleLabelframe = cell.contentLabel.frame;
        titleLabelframe.size.height = CGRectGetHeight(rect);
        //    NSLog(@"%@", NSStringFromCGRect(titleLabelframe));
        cell.contentLabel.frame = titleLabelframe;
        
        
        //text=[NSString stringWithFormat:@"在\"%@\"中回复了你的评论：\n\"%@\"",message.news.title,message.text];
        cell.replyContentLabel.text=message.reply_text;
        //cell.replyContentLabel.numberOfLines=0;
        //cell.timeLabel.text=message.time;
        
        attribute = @{NSFontAttributeName:cell.replyContentLabel.font};
        rect = [cell.replyContentLabel.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.replyContentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        //    NSLog(@"%@", NSStringFromCGRect(rect));
        titleLabelframe = cell.replyContentLabel.frame;
        titleLabelframe.size.height = CGRectGetHeight(rect);
        //    NSLog(@"%@", NSStringFromCGRect(titleLabelframe));
        cell.replyContentLabel.frame = titleLabelframe;
        return cell;
    }
        VNNotificationReplyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"VNNotificationReplyTableViewCellIdentifier"];
        [cell.thumbnail setImageForState:UIControlStateNormal withURL:[NSURL URLWithString:message.sender.avatar] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
        [cell.thumbnail.layer setCornerRadius:CGRectGetHeight([cell.thumbnail bounds]) / 2];
        cell.thumbnail.layer.masksToBounds = YES;
        
        cell.nameLabel.text=message.sender.name;
        NSString *text=[NSString stringWithFormat:@"在你的大作\"%@\"中评论了你",message.news.title];
        
        //cell.contentLabel.numberOfLines=0;
        cell.timeLabel.text=message.time;
        
        NSDictionary *attribute = @{NSFontAttributeName:cell.contentLabel.font};
        CGRect rect = [text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.contentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
          // NSLog(@"%@", NSStringFromCGRect(rect));
        CGRect titleLabelframe = cell.contentLabel.frame;
        titleLabelframe.size.height = CGRectGetHeight(rect);
        //NSLog(@"%f", titleLabelframe.size.height);
        //NSLog(@"%f",cell.contentLabel.frame.size.height);
        cell.contentLabel.frame = titleLabelframe;
        //NSLog(@"%f",cell.contentLabel.frame.size.height);
        cell.contentLabel.text=text;
        //cell.contentLabel.backgroundColor=[UIColor blackColor];
        
        cell.replyContentLabel.text=message.reply_text;
        //cell.replyContentLabel.numberOfLines=0;
        attribute = @{NSFontAttributeName:cell.replyContentLabel.font};
        rect = [cell.replyContentLabel.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.replyContentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        //    NSLog(@"%@", NSStringFromCGRect(rect));
        titleLabelframe = cell.replyContentLabel.frame;
        titleLabelframe.size.height = CGRectGetHeight(rect);
        //    NSLog(@"%@", NSStringFromCGRect(titleLabelframe));
        cell.replyContentLabel.frame = titleLabelframe;
        return cell;
    //}
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
    CGFloat diff = 0;
    VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
    //    NSString *testString = @"沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了";
    VNNotificationReplyTableViewCell *cell = loadXib(@"VNNotificationReplyTableViewCell");
    
    if ([message.type isEqualToString:@"comment"]) {
        NSDictionary *attribute = @{NSFontAttributeName:cell.contentLabel.font};
        NSString *text=[NSString stringWithFormat:@"在\"%@\"中回复了你的评论：\n\"%@\"",message.news.title,message.text];
        CGRect rect = [text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.contentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        //    NSLog(@"%@", NSStringFromCGRect(rect));
        if (CGRectGetHeight(rect) > 15) {
            diff = CGRectGetHeight(rect)-15;
        }
        attribute = @{NSFontAttributeName:cell.replyContentLabel.font};
        rect = [message.reply_text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.replyContentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        if (CGRectGetHeight(rect)>15) {
            diff=diff+CGRectGetHeight(rect)-15;
        }
        return diff+80;
    }
    else if ([message.type isEqualToString:@"news"])
    {
        NSDictionary *attribute = @{NSFontAttributeName:cell.contentLabel.font};
        NSString *text=[NSString stringWithFormat:@"在你的大作\"%@\"中评论了你",message.news.title];
        CGRect rect = [text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.contentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        //    NSLog(@"%@", NSStringFromCGRect(rect));
        if (CGRectGetHeight(rect) > 15) {
            diff = CGRectGetHeight(rect)-15;
        }
        attribute = @{NSFontAttributeName:cell.replyContentLabel.font};
        rect = [message.reply_text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.replyContentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
        if (CGRectGetHeight(rect)>15) {
            diff=diff+CGRectGetHeight(rect)-15;
        }
        return 80+diff;
    }
    //NSLog(@"%f",diff);
        return 50;
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
