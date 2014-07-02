//
//  VNNewsDetailViewController.m
//  VideoNews
//
//  Created by liuyi on 14-6-30.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNNewsDetailViewController.h"
#import "VNDetailHeaderView.h"
#import "UIImageView+AFNetworking.h"
#import "UIButton+AFNetworking.h"

#import "SVPullToRefresh.h"
#import "VNCommentTableViewCell.h"

@interface VNNewsDetailViewController () {
    BOOL isKeyboardShowing;
    CGFloat keyboardHeight;
}

@property (weak, nonatomic) IBOutlet UITableView *commentTableView;
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;
@property (weak, nonatomic) IBOutlet UIToolbar *inputBar;
@property (strong, nonatomic) NSMutableArray *commentArr;

- (IBAction)popBack:(id)sender;
- (IBAction)like:(id)sender;
- (IBAction)share:(id)sender;
- (IBAction)sendComment:(id)sender;
- (IBAction)switchEmoji:(id)sender;

@end

@implementation VNNewsDetailViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _commentArr = [NSMutableArray arrayWithCapacity:0];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    VNDetailHeaderView *headerView = loadXib(@"VNDetailHeaderView");
    
    [headerView.thumbnailImageView setImageWithURL:[NSURL URLWithString:self.news.author.avatar] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    [headerView.thumbnailImageView.layer setCornerRadius:CGRectGetHeight([headerView.thumbnailImageView bounds]) / 2];
    headerView.thumbnailImageView.layer.masksToBounds = YES;
    headerView.nameLabel.text = self.news.author.name;
    
    [self.news.mediaArr enumerateObjectsUsingBlock:^(VNMedia *obj, NSUInteger idx, BOOL *stop){
        if ([obj.type rangeOfString:@"image"].location != NSNotFound) {
            self.media = obj;
            *stop = YES;
        }
    }];
    [headerView.newsImageView setImageWithURL:[NSURL URLWithString:self.media.url] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    
    CGFloat diff = 0;
    headerView.titleLabel.text = self.news.title;
    NSDictionary *attribute = @{NSFontAttributeName:headerView.titleLabel.font};
    CGRect rect = [headerView.titleLabel.text boundingRectWithSize:CGSizeMake(headerView.titleLabel.bounds.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    CGRect titleLabelframe = headerView.titleLabel.frame;
    titleLabelframe.size.height += CGRectGetHeight(rect);
    diff = CGRectGetHeight(rect);
    headerView.titleLabel.frame = titleLabelframe;
    
    CGRect headerFrame = headerView.bounds;
    headerFrame.size.height += diff;
    headerView.bounds = headerFrame;
    
    headerView.timeLabel.text = self.news.date;
    headerView.tagLabel.text = self.news.tags;
    headerView.commentLabel.text = [NSString stringWithFormat:@"%d", self.news.comment_count];
    headerView.likeNumLabel.text = [NSString stringWithFormat:@"%d", self.news.like_count];
    
    self.commentTableView.tableHeaderView = headerView;
    [self.commentTableView registerNib:[UINib nibWithNibName:@"VNCommentTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNCommentTableViewCellIdentifier"];
    self.commentTableView.layer.cornerRadius = 5.0;
    self.commentTableView.layer.masksToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [VNHTTPRequestManager commentListForNews:self.news.nid timestamp:[VNHTTPRequestManager timestamp] completion:^(NSArray *commemtArr, NSError *error) {
        if (error) {
            NSLog(@"%@", error.localizedDescription);
        }
        else {
            [self.commentArr addObjectsFromArray:commemtArr];
            [self.commentTableView reloadData];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.navigationBarHidden = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
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
    return self.commentArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"VNCommentTableViewCellIdentifier";
    VNCommentTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    VNComment *comment = [self.commentArr objectAtIndex:indexPath.row];
    [cell.thumbnail setImageForState:UIControlStateNormal withURL:[NSURL URLWithString:comment.author.avatar] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    [cell.thumbnail.layer setCornerRadius:CGRectGetHeight([cell.thumbnail bounds]) / 2];
    cell.thumbnail.layer.masksToBounds = YES;
    cell.nameLabel.text = comment.author.name;
    
    cell.commentLabel.text = comment.content;
//    NSString *testString = @"沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了";
//    cell.commentLabel.text = testString;
    NSDictionary *attribute = @{NSFontAttributeName:cell.commentLabel.font};
    CGRect rect = [cell.commentLabel.text boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.commentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
//    NSLog(@"%@", NSStringFromCGRect(rect));
    CGRect titleLabelframe = cell.commentLabel.frame;
    titleLabelframe.size.height = CGRectGetHeight(rect);
    NSLog(@"%@", NSStringFromCGRect(titleLabelframe));
    cell.commentLabel.frame = titleLabelframe;
    
    cell.timeLabel.text = [comment.date substringToIndex:10];
    
    return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat diff = 0;
    VNComment *comment = [self.commentArr objectAtIndex:indexPath.row];
//    NSString *testString = @"沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了沃尔夫就撒旦法离开撒娇地方；啊家发了";
    VNCommentTableViewCell *cell = loadXib(@"VNCommentTableViewCell");
    NSDictionary *attribute = @{NSFontAttributeName:cell.commentLabel.font};
    CGRect rect = [comment.content boundingRectWithSize:CGSizeMake(CGRectGetWidth(cell.commentLabel.bounds), CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
//    NSLog(@"%@", NSStringFromCGRect(rect));
    if (CGRectGetHeight(rect) > 15) {
        diff = CGRectGetHeight(rect)-15;
    }
    return 60.0+diff;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if ([self.inputTextField isFirstResponder]) {
        [self.inputTextField resignFirstResponder];
    }
}

#pragma mark - SEL

- (IBAction)popBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)like:(id)sender {
}

- (IBAction)share:(id)sender {
}

- (IBAction)sendComment:(id)sender {
}

- (IBAction)switchEmoji:(id)sender {
}

#pragma mark - UIKeyboardNotification

- (void)keyboardWillShow:(NSNotification *)notification {
    
    isKeyboardShowing = YES;
    
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
                         
                         keyboardHeight = keyboardRect.size.height;
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
                         
                         keyboardHeight = 0;
                     }];
}

@end
