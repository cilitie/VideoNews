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
    //NSLog(@"%d",self.messageArr.count);
    return self.messageArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    //VNNotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    //VNNotificationTableViewCell *cell=[[VNNotificationTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"VNNotificationTableViewCellIdentifier"];
    
    /*if (cell==nil) {
        cell=[[VNNotificationTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"VNNotificationTableViewCellIdentifier"];
    }*/
    
    VNMessage *message = [self.messageArr objectAtIndex:indexPath.row];
    
    if ([message.type isEqualToString: @"user"]) {
        static NSString *cellIdentifier = @"VNNotificationUserTableViewCellIdentifier";
        VNNotificationUserTableViewCell *cell=loadXib(@"VNNotificationUserTableViewCell");
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
        static NSString *cellIdentifier = @"VNNotificationReplyTableViewCellIdentifier";
        VNNotificationReplyTableViewCell *cell = loadXib(@"VNNotificationReplyTableViewCell");
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
    //else if ([message.type isEqualToString:@"news"])
    //{
        static NSString *cellIdentifier = @"VNNotificationReplyTableViewCellIdentifier";
        VNNotificationReplyTableViewCell *cell = loadXib(@"VNNotificationReplyTableViewCell");
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
        [[NSNotificationCenter defaultCenter] postNotificationName:@"replyCommentFromNotification" object:nil];
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
