//
//  LVViewController.m
//  ImageBrowser
//
//  Created by LawLincoln on 14-4-23.
//  Copyright (c) 2014年 SelfStudio. All rights reserved.
//

#import "LVViewController.h"
#import "PZViewController.h"
#define INSTANTIATE_VIEW_CONTROLLER_PAD(_IDENTIFIER_) ([[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:_IDENTIFIER_])
#pragma mark - Categories

@interface LVViewController ()
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *images;
@property (strong, nonatomic) UIImageView *mask;
@property (strong, nonatomic) NSArray *urls;

@end

@implementation LVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    _urls = @[
              @"http://www.showparty.com.tw/attachment/201104/8/7466771_13022270335Is9.jpg",
              @"http://images-cdn.digu.com/d20c44d273b74947aa59ccb72e88dfa10001.jpg",
              @"http://www.aomy.com/attach/2012-08/1344681100fyhK.jpg",
              @"http://cdn.duitang.com/uploads/item/201304/14/20130414134820_YQdVN.jpeg",
              @"http://photos.orzzso.com/img/photo/1/1444.jpg",
              @"http://pic.4j4j.cn/upload/pic/20130529/9d2c4522f3.jpg",
              @"http://i679.photobucket.com/albums/vv152/shingck_photos/315.jpg",
              @"http://fs0.139js.com/file/s_jpg_6b715ec6gw1e1f4kelumej.jpg"];
}
-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    UITapGestureRecognizer *tap = nil;
    NSUInteger idx = 0;
    for (UIImageView *imgV in _images) {
        tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(showImage:)];
        tap.numberOfTouchesRequired = 1;
        tap.numberOfTapsRequired = 1;
        [imgV setUserInteractionEnabled:YES];
        [imgV addGestureRecognizer:tap];
        if (idx>=_urls.count) {
            idx = 0;
        }
        NSString *url = _urls[idx];
        imgV.userInfo = @{@"url":url};
        idx++;
        
    }
}
- (void)showImage:(UITapGestureRecognizer*)tap{
    PZViewController *pz = [[PZViewController alloc]init];
    NSUInteger idx = [_images indexOfObject:tap.view];
    if (idx == NSNotFound) {
        idx = 0;
    }
    pz.imgs = _images;
    pz.startIndex = idx;
    [self addChildViewController:pz];
    [pz.view setFrame:self.view.bounds];
    [self.view addSubview:pz.view];
    [pz show];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
