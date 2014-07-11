//
//  VNSearchWordViewController.m
//  VideoNews
//
//  Created by liuyi on 14-7-3.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNSearchWordViewController.h"
#import "VNSearchField.h"
#import "VNSearchTabHeaderView.h"
#import "VNSearchResultTableViewCell.h"
#import "VNResultViewController.h"
#import "VNUserResultViewController.h"

@interface VNSearchWordViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UIButton *cancelBtn;
@property (weak, nonatomic) IBOutlet UITableView *resultTableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *resultTableViewBottonLC;
@property (strong, nonatomic) VNSearchField *searchField;
@property (strong, nonatomic) NSMutableArray *historyWordArr;
@property (assign, nonatomic) SearchType searchType;


- (IBAction)cancelSearch:(id)sender;

@end

@implementation VNSearchWordViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _historyWordArr = [NSMutableArray array];
        _searchType = SearchTypeVideo;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeSearchType:) name:VNSearchTypeDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [self.resultTableView registerNib:[UINib nibWithNibName:@"VNSearchResultTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNSearchResultTableViewCellIdentifier"];
    
    self.searchField = [[VNSearchField alloc] init];
    self.searchField.returnKeyType = UIReturnKeySearch;
    self.searchField.delegate = self;
    self.searchField.frame = CGRectMake(10, 20+(CGRectGetHeight(self.navBar.bounds)-20-30)/2, CGRectGetMinX(self.cancelBtn.frame)-10*2, 30);
    NSLog(@"%@", NSStringFromCGRect(self.searchField.frame));
    [self.navBar addSubview:self.searchField];
    
    self.cancelBtn.layer.cornerRadius = 5;
    self.cancelBtn.layer.masksToBounds = YES;
    
    [self.searchField becomeFirstResponder];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [VNCacheDataManager historyDataWithCompletion:^(NSArray *queryHistoryArr) {
        if (self.historyWordArr.count) {
            [self.historyWordArr removeAllObjects];
        }
        [self.historyWordArr addObjectsFromArray:queryHistoryArr];
        [self.resultTableView reloadData];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:VNSearchTypeDidChangeNotification object:nil];
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

#pragma mark - SEL

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    CGRect frame = [[notification userInfo][UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (frame.origin.x == [UIApplication sharedApplication].keyWindow.bounds.size.width) {
        self.resultTableViewBottonLC.constant = 0;
    } else {
        [UIView animateWithDuration:[[notification userInfo][UIKeyboardAnimationDurationUserInfoKey] doubleValue] animations:^{
            NSLog(@"%f", frame.size.width);
            self.resultTableViewBottonLC.constant = frame.size.height;
            [self.resultTableView layoutIfNeeded];
        }];
    }
}

- (void)changeSearchType:(NSNotification *)notification {
    self.searchType = [notification.object integerValue];
}

- (IBAction)cancelSearch:(id)sender {
    if ([self.searchField isFirstResponder]) {
        [self.searchField resignFirstResponder];
    }
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - UITableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.historyWordArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"VNSearchResultTableViewCellIdentifier";
    VNSearchResultTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    cell.searchItemLabel.text = [self.historyWordArr objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - UITableView Delegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *searchKey = [self.historyWordArr objectAtIndex:indexPath.row];
    [VNCacheDataManager addHistoryData:searchKey completion:^(BOOL succeeded) {
        if (succeeded) {
            NSLog(@"save search history success!");
        }
    }];
    if (self.searchType == SearchTypeVideo) {
        VNResultViewController *resultViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNResultViewController"];
        resultViewController.type = ResultTypeSerach;
        resultViewController.searchKey = searchKey;
        resultViewController.searchType = @"news";
        [self.navigationController pushViewController:resultViewController animated:YES];
    }
    else {
        VNUserResultViewController *userResultViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNUserResultViewController"];
        userResultViewController.searchKey = searchKey;
        [self.navigationController pushViewController:userResultViewController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 88.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    VNSearchTabHeaderView *headerView = loadXib(@"VNSearchTabHeaderView");
    return headerView;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSString *str = textField.text;
    NSMutableString *searchKey = [[NSMutableString alloc] init];
    [searchKey setString:str];
    CFStringTrimWhitespace((CFMutableStringRef)searchKey);
    
    if (!searchKey || [searchKey isEqualToString:@""]) {
        return NO;
    }
    else {
        [VNCacheDataManager addHistoryData:searchKey completion:^(BOOL succeeded) {
            if (succeeded) {
                NSLog(@"save search history success!");
            }
        }];
        if (self.searchType == SearchTypeVideo) {
            VNResultViewController *resultViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNResultViewController"];
            resultViewController.type = ResultTypeSerach;
            resultViewController.searchKey = searchKey;
            resultViewController.searchType = @"news";
            [self.navigationController pushViewController:resultViewController animated:YES];
        }
        else {
            VNUserResultViewController *userResultViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"VNUserResultViewController"];
            userResultViewController.searchKey = searchKey;
            [self.navigationController pushViewController:userResultViewController animated:YES];
        }
    }
    return YES;
}

@end
