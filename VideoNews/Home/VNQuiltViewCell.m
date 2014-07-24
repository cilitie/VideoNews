//
//  VNQuiltViewCell.m
//  VideoNews
//
//  Created by liuyi on 14-6-27.
//  Copyright (c) 2014年 Manyu Zhu. All rights reserved.
//

#import "VNQuiltViewCell.h"

@interface VNQuiltViewCell ()

@property (nonatomic,strong) UIImageView *newsImageView;
@property (strong, nonatomic) UIImageView * thumbnailImageView;
@property (strong, nonatomic) UIImageView * mask;
@property (nonatomic,strong) VNMedia *imageMedia;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UILabel *nameLabel;
@property (nonatomic,strong) UIView *line;
@property (nonatomic,strong) UIView *userView;

@end

CGFloat const cellMargin = 5.0;
CGFloat const thumbnailHeight = 30.0;
static CGFloat totleWidth = 145.0;

@implementation VNQuiltViewCell

- (id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        
        _titleLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:12.0];
        _titleLabel.textColor=[UIColor colorWithRGBValue:0x808285];
        [_titleLabel setNumberOfLines:1000];
        
        _newsImageView = [[UIImageView alloc]initWithFrame:CGRectZero];
        UITapGestureRecognizer * tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageViewTapped:)];
        [_newsImageView addGestureRecognizer:tapGestureRecognizer];
        //[tapGestureRecognizer release];
        [_newsImageView setUserInteractionEnabled:YES];
        
        _thumbnailImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 30.0, 30.0)];
        _thumbnailImageView.contentMode=UIViewContentModeScaleAspectFill;
        _thumbnailImageView.clipsToBounds = YES;
        [self addSubview:_thumbnailImageView];
        
        _mask=[[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 30.0, 30.0)];
        _mask.image=[UIImage imageNamed:@"profile@2x"];
        [self addSubview:_mask];
        //[self.thumbnailImageView.layer setCornerRadius:CGRectGetHeight([self.thumbnailImageView bounds]) / 2];
        //self.thumbnailImageView.layer.masksToBounds = YES;
        
        
        _nameLabel = [[UILabel alloc]initWithFrame:CGRectZero];
        _nameLabel.font = [UIFont systemFontOfSize:10.0];
        _nameLabel.textColor=[UIColor colorWithRGBValue:0x808285];
        [_nameLabel setNumberOfLines:2];
        
        _line = [[UIView alloc] initWithFrame:CGRectZero];
        [_line setBackgroundColor:[UIColor colorWithRGBValue:0xced5d6]];
        
        _userView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 135, 33)];
        _userView.backgroundColor=[UIColor clearColor];
        UITapGestureRecognizer * tapGestureRecognizer1 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userViewTapped:)];
        [_userView addGestureRecognizer:tapGestureRecognizer1];
        
        [_userView setUserInteractionEnabled:YES];
        
        
        [self addSubview:_titleLabel];
        [self addSubview:_newsImageView];
        
        [self addSubview:_nameLabel];
        [self addSubview:_line];
        [self addSubview:_userView];
    }
    return self;
}

- (void)setNews:(VNNews *)news
{
    if (news) {
        _news = news;
        //_titleLabel.text = news.title;
        
        //self.status = BMMovieItemStatusNormal;
        [_news.mediaArr enumerateObjectsUsingBlock:^(VNMedia *obj, NSUInteger idx, BOOL *stop){
            if ([obj.type rangeOfString:@"image"].location != NSNotFound) {
                self.imageMedia = obj;
                *stop = YES;
            }
        }];
    }
}

- (void)imageViewTapped:(UIGestureRecognizer *)recognizer {
    
    if ([recognizer state] != UIGestureRecognizerStateEnded) {
        return;
    }
    //CGPoint tapPoint = [recognizer locationInView:self];
    if ([self.delegate respondsToSelector:@selector(TapImageView:)]) {
        [self.delegate TapImageView:_news];
    }
    
}

- (void)userViewTapped:(UIGestureRecognizer *)recognizer {
    
    if ([recognizer state] != UIGestureRecognizerStateEnded) {
        return;
    }
    //CGPoint tapPoint = [recognizer locationInView:self];
    if ([self.delegate respondsToSelector:@selector(TapUserView:)]) {
        [self.delegate TapUserView:_news];
    }
    
}

- (void)reloadCell {
    //FIXME: Hard Code
    _newsImageView.frame=CGRectMake(0.0, 0.0, totleWidth, self.imageMedia.height);
    [_newsImageView setImageWithURL:[NSURL URLWithString:self.imageMedia.url] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    
    _titleLabel.frame=CGRectMake(cellMargin, CGRectGetMaxY(_newsImageView.frame)+5, totleWidth-cellMargin*2, cellMargin*2);
    [_titleLabel setText:_news.title];
    NSDictionary *attribute = @{NSFontAttributeName:_titleLabel.font};
    CGRect rect = [_titleLabel.text boundingRectWithSize:CGSizeMake(_titleLabel.bounds.size.width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attribute context:nil];
    CGRect titleLabelframe = _titleLabel.frame;
    titleLabelframe.size.height += CGRectGetHeight(rect);
    _titleLabel.frame = titleLabelframe;
    
    _line.frame = CGRectMake(0, CGRectGetMaxY(_titleLabel.frame)+cellMargin, totleWidth, 1.0);
    
    _userView.frame=CGRectMake(5, CGRectGetMaxY(_titleLabel.frame)+cellMargin+1, 135, 33);
    
    _thumbnailImageView.frame=CGRectMake(cellMargin, CGRectGetMaxY(_line.frame)+cellMargin, thumbnailHeight, thumbnailHeight);
    _mask.frame=CGRectMake(cellMargin, CGRectGetMaxY(_line.frame)+cellMargin, thumbnailHeight, thumbnailHeight);
    [_thumbnailImageView setImageWithURL:[NSURL URLWithString:_news.author.avatar] placeholderImage:[UIImage imageNamed:@"placeHolder"]];
    //[_thumbnailImageView addSubview:[UIImage imageNamed:@"profile@2x.png"]];
    NSLog(@"%@", _news.author.avatar);
    
    _nameLabel.frame=CGRectMake(CGRectGetMaxX(_thumbnailImageView.frame)+cellMargin, CGRectGetMaxY(_line.frame)+cellMargin, totleWidth-CGRectGetWidth(_thumbnailImageView.frame)-cellMargin*2, thumbnailHeight);
    [_nameLabel setText:_news.author.name];
    NSLog(@"%@", _news.author.name);
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
