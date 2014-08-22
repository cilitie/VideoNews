//
//  VNCheckOutViewController.m
//  VideoNews
//
//  Created by 曼瑜 朱 on 14-8-20.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNCheckOutViewController.h"
#import "VNCheckOutTableViewCell.h"

@interface VNCheckOutViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *checkoutTableWiew;
@property (weak, nonatomic) IBOutlet UILabel *submitLabel;

@end

@implementation VNCheckOutViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _submitLabel.layer.cornerRadius=5;
    _submitLabel.layer.masksToBounds=YES;
    self.checkoutTableWiew.delegate=self;
    [self.checkoutTableWiew registerNib:[UINib nibWithNibName:@"VNCheckOutTableViewCell" bundle:[NSBundle mainBundle]] forCellReuseIdentifier:@"VNCheckoutCellIdentifier"];
    self.checkoutTableWiew.backgroundColor = [UIColor colorWithRGBValue:0xE1E1E1];
   /* _label1.layer.borderWidth=1;
    _label1.layer.borderColor=[[UIColor lightGrayColor]CGColor];
    _label2.layer.borderWidth=1;
    _label2.layer.borderColor=[[UIColor lightGrayColor]CGColor];*/
    _Button.layer.borderWidth=2;
    _Button.layer.borderColor=[[UIColor lightGrayColor]CGColor];
    [_Button.layer setCornerRadius:CGRectGetHeight([_Button bounds]) / 2];
    _Button.layer.masksToBounds = YES;
    UIImageView *line=[[UIImageView alloc]initWithFrame:CGRectMake(10, 39, 280, 1)];
    line.backgroundColor=[UIColor lightGrayColor];
    [_label1 addSubview:line];
    UIImageView *line1=[[UIImageView alloc]initWithFrame:CGRectMake(10, 59, 280, 1)];
    line1.backgroundColor=[UIColor lightGrayColor];
    [_label2 addSubview:line1];
    //[self.checkoutTableWiew setTableFooterView:[[UIView alloc] init]];

    // Do any additional setup after loading the view.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"VNCheckoutCellIdentifier";
    VNCheckOutTableViewCell *cell = (VNCheckOutTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
   // UITableViewCell *cell1 = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    //if (cell) {
        //cell=loadXib(@"VNCheckOutTableViewCell");
    //}
   // VNCheckOutTableViewCell *cell=(VNCheckOutTableViewCell *)cell1;
    cell.backgroundColor=[UIColor colorWithRGBValue:0xE1E1E1];
    if (indexPath.row==0) {
        cell.imageView.hidden=YES;
        cell.label.frame=CGRectMake(10, 10, 100, 20);
        cell.label.text=@"支付方式:";
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else if (indexPath.row==1)
    {
        cell.imageView.image=[UIImage imageNamed:@"wechat"];
        cell.label.text=@"微信支付";
        
    }
    else
    {
        cell.imageView.image=[UIImage imageNamed:@"yinlian"];
        cell.label.text=@"银联支付";
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row==0) {
        return 40;
    }
    else 
    {
        return 60;
    }
    return 80;
    
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

@end
