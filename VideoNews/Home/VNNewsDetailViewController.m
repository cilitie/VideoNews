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

@interface VNNewsDetailViewController ()

@property (weak, nonatomic) IBOutlet UITableView *commentTableView;

- (IBAction)popBack:(id)sender;
- (IBAction)like:(id)sender;
- (IBAction)share:(id)sender;

@end

@implementation VNNewsDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    VNDetailHeaderView *headerView = loadXib(@"VNDetailHeaderView");
    
    [headerView.thumbnailImageView setImageWithURL:[NSURL URLWithString:self.news.author.avatar] placeholderImage:[UIImage imageNamed:@"Profile"]];
    headerView.nameLabel.text = self.news.author.name;
    
    [self.news.mediaArr enumerateObjectsUsingBlock:^(VNMedia *obj, NSUInteger idx, BOOL *stop){
        if ([obj.type rangeOfString:@"image"].location != NSNotFound) {
            self.media = obj;
            *stop = YES;
        }
    }];
    [headerView.newsImageView setImageWithURL:[NSURL URLWithString:self.media.url] placeholderImage:[UIImage imageNamed:@"Profile"]];
    
    headerView.titleLabel.text = self.news.title;
    headerView.timeLabel.text = self.news.date;
    headerView.tagLabel.text = self.news.tags;
    headerView.commentLabel.text = [NSString stringWithFormat:@"%d", self.news.comment_count];
    headerView.likeNumLabel.text = [NSString stringWithFormat:@"%d", self.news.like_count];
    
    self.commentTableView.tableHeaderView = headerView;
    self.commentTableView.layer.cornerRadius = 5.0;
    self.commentTableView.layer.masksToBounds = YES;
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
    return 10;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Cell %d", indexPath.row];
    
    return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
}

- (IBAction)popBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)like:(id)sender {
}

- (IBAction)share:(id)sender {
}
@end
