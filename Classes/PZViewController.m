/*
 PhotoZoom by Brennan Stehling
 https://alpha.app.net/smallsharptools
 
 Copyright (c) 2013 SmallSharpTools LLC.
 All rights reserved.
 
 Redistribution and use in source and binary forms are permitted
 provided that the above copyright notice and this paragraph are
 duplicated in all such forms and that any documentation,
 advertising materials, and other materials related to such
 distribution and use acknowledge that the software was developed
 by the <organization>.  The name of the
 <organization> may not be used to endorse or promote products derived
 from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 
 */
//
//  PZViewController.m
//  PhotoZoom
//
//  Created by Brennan Stehling on 10/27/12.
//  Copyright (c) 2012 SmallSharptools LLC. All rights reserved.
//
//  Adjust By CodeEagle

#import "PZViewController.h"
#import <CoreGraphics/CoreGraphics.h>
#import <UIImageView+WebCache.h>
#import "PZPhotoView.h"
#import <Masonry.h>


@interface PZViewController () <PZPagingScrollViewDelegate, PZPhotoViewDelegate, UIScrollViewDelegate>{
     BOOL reverse;
}
@property (strong, nonatomic)  PZPagingScrollView *pagingScrollView;

@property (strong, nonatomic)  UIToolbar *toolsBar;
@property (strong, nonatomic)  UIToolbar *topBg;
@property (strong, nonatomic)  UIProgressView *progressView;
@property (strong, nonatomic)  UIImageView *loader;
@property (strong, nonatomic)  UIView *bg;
@property (readonly) NSArray *customToolbarItems;
@property (strong, nonatomic)  UIPageControl *pageControl;
//@property (strong, nonatomic) PZPhotosDataSource *photosDataSource;


@end

@implementation PZViewController

#pragma mark - View Lifecycle
#pragma mark -
- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}
- (void)initLayout{
    
    UIColor *themeColor = [UIColor colorWithRed:0.621 green:1.000 blue:0.224 alpha:0.6];
    UIView *superview = self.view;
    
    _bg = [[UIView alloc]initWithFrame:self.view.bounds];
    [_bg setBackgroundColor:[UIColor whiteColor]];
    [_bg setAlpha:0];
    [self.view addSubview:_bg];
    
    [_bg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(superview);
        make.right.equalTo(superview);
        make.top.equalTo(superview);
        make.size.equalTo(superview);
    }];
    
    
    
    _pagingScrollView = [[PZPagingScrollView alloc]initWithFrame:self.view.bounds];
    [_pagingScrollView setPagingViewDelegate:self];
    [_pagingScrollView setAlpha:0];
    [self.view addSubview:_pagingScrollView];
    [_pagingScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(superview);
        make.right.equalTo(superview);
        make.top.equalTo(superview);
        make.size.equalTo(superview);
    }];

    CGFloat y = self.view.frame.size.height - 44;
    _toolsBar = [[UIToolbar alloc]initWithFrame:CGRectMake(0, y, self.view.frame.size.width, 44)];
    [_toolsBar setTranslucent : TRUE];
    [_toolsBar setTintColor : [UIColor grayColor] ];
    [_toolsBar setItems:self.customToolbarItems animated:YES];
    [self.view addSubview:_toolsBar];
    [_toolsBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.height.equalTo(@44);
    }];

    
    
    _pageControl = [[UIPageControl alloc]initWithFrame:CGRectMake(0, y-37, self.view.frame.size.width, 37)];
    [self.view addSubview:_pageControl];
    [_pageControl setNumberOfPages:_imgs.count];
    [_pageControl setCurrentPage:_startIndex];
    [_pageControl setCurrentPageIndicatorTintColor:themeColor];
    [_pageControl setPageIndicatorTintColor:[UIColor colorWithWhite:0.0 alpha:.5]];
    [_pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(_toolsBar.mas_top);
    }];
    
    
    _topBg = [[UIToolbar alloc]initWithFrame:CGRectMake(0, -24, self.view.frame.size.width, 44)];
    [_topBg setTranslucent : TRUE];
    [_topBg setTintColor : [UIColor grayColor] ];
    [self.view addSubview:_topBg];
    [_topBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.top.equalTo(self.view.mas_top).offset(-24);
        make.height.equalTo(@44);
    }];
    
    
    _progressView = [[UIProgressView alloc]initWithFrame:CGRectMake(0, 20, self.view.frame.size.width, 2)];
    [_progressView setTintColor:themeColor];
    [self.view addSubview:_progressView];
    [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_topBg.mas_bottom);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
    }];
    
    
    _loader = [[UIImageView alloc]initWithFrame:CGRectZero];
    [self.view addSubview:_loader];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    [self initLayout];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    self.topBg.translucent = TRUE;
    self.topBg.tintColor = [UIColor grayColor];

    
    

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        self.pagingScrollView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    });
//    [self toggleFullScreen];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // resetDisplay will set the content size and position the frames (not ideal to do it this way)
    [self.pagingScrollView resetDisplay];
    [self.pagingScrollView displayPagingViewAtIndex:_startIndex?_startIndex:0];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    // suspend tiling while rotating
    self.pagingScrollView.suspendTiling = TRUE;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    
    self.pagingScrollView.suspendTiling = FALSE;
    [self.pagingScrollView resetDisplay];
}

#pragma mark - User Actions
#pragma mark -

- (NSArray *)customToolbarItems {
    UIBarButtonItem *flexItem1 = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                   target:self
                                   action:nil];
    UIBarButtonItem *flexItem2 = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                   target:self
                                  action:nil];
    UIBarButtonItem *flexItem3 = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                  target:self
                                  action:nil];
    UIBarButtonItem *flexItem4 = [[UIBarButtonItem alloc]
                                  initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                  target:self
                                  action:nil];
    
    UIBarButtonItem *maximumButton = [[UIBarButtonItem alloc]
                                    initWithTitle:@"Maximum"
                                    style:UIBarButtonItemStyleBordered
                                    target:self
                                   action:@selector(showMaximumSize:)];
    
    UIBarButtonItem *mediumButton = [[UIBarButtonItem alloc]
                                  initWithTitle:@"Save"
                                  style:UIBarButtonItemStyleBordered
                                  target:self
                                  action:@selector(saveImage)];
    
    UIBarButtonItem *minimumButton = [[UIBarButtonItem alloc]
                                   initWithTitle:@"Hide"
                                   style:UIBarButtonItemStyleBordered
                                   target:self
                                  action:@selector(hide)];
    return @[flexItem1, maximumButton, flexItem2, mediumButton, flexItem3, minimumButton, flexItem4];
}

- (void)showMaximumSize:(id)sender {
    PZPhotoView *photoView = (PZPhotoView *)self.pagingScrollView.visiblePageView;
    [photoView updateZoomScale:photoView.maximumZoomScale];
}

- (void)showMediumSize:(id)sender {
    PZPhotoView *photoView  = (PZPhotoView *)self.pagingScrollView.visiblePageView;
    float newScale = (photoView.minimumZoomScale + photoView.maximumZoomScale) / 2.0;
    [photoView updateZoomScale:newScale];
}

- (void)showMinimumSize:(id)sender {
    PZPhotoView *photoView  = (PZPhotoView *)self.pagingScrollView.visiblePageView;
    [photoView updateZoomScale:photoView.minimumZoomScale];
}
- (void)showTools{

    [UIView animateWithDuration:0.2 animations:^{
        [[UIApplication sharedApplication] setStatusBarHidden:FALSE withAnimation:UIStatusBarAnimationNone];
        self.bg.layer.backgroundColor =[UIColor whiteColor].CGColor;
        self.toolsBar.alpha = 1.0;
        self.topBg.alpha = 1.0;
        self.progressView.alpha = 1.0;
        self.pageControl.alpha = 1.0;
    } completion:^(BOOL finished) {
    }];
}
- (void)hideTools:(void(^)(void))done{
    [UIView animateWithDuration:0.2 animations:^{
        [[UIApplication sharedApplication] setStatusBarHidden:TRUE withAnimation:UIStatusBarAnimationFade];
        self.bg.layer.backgroundColor =[UIColor blackColor].CGColor;
        self.toolsBar.alpha = 0.0;
        self.topBg.alpha = 0.0;
        self.progressView.alpha = 0.0;
        self.pageControl.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            if (done) {
                done();
            }
        }
    }];
}
- (void)toggleFullScreen {
    if (self.toolsBar.alpha == 0.0) {
        // fade in navigation
        [self showTools];
        
    }
    else {
        // fade out navigation
        [self hideTools:nil];
       
    }
}


#pragma mark - Orientation
#pragma mark -

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}

- (BOOL)shouldAutorotate {
    return TRUE;
}

#pragma mark - PZPagingScrollViewDelegate
#pragma mark -

- (Class)pagingScrollView:(PZPagingScrollView *)pagingScrollView classForIndex:(NSUInteger)index {
    // all page views are photo views
    return [PZPhotoView class];
}

- (NSUInteger)pagingScrollViewPagingViewCount:(PZPagingScrollView *)pagingScrollView {
    return self.imgs.count;
}

- (UIView *)pagingScrollView:(PZPagingScrollView *)pagingScrollView pageViewForIndex:(NSUInteger)index {
    PZPhotoView *photoView = [[PZPhotoView alloc] initWithFrame:self.view.bounds];
    photoView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    photoView.photoViewDelegate = self;
    
    return photoView;
}

- (void)pagingScrollView:(PZPagingScrollView *)pagingScrollView preparePageViewForDisplay:(UIView *)pageView forIndex:(NSUInteger)index {
    NSAssert([pageView isKindOfClass:[PZPhotoView class]], @"Invalid State");
    NSAssert(index < self.imgs.count, @"Invalid State");
    
    PZPhotoView *photoView = (PZPhotoView *)pageView;
    [photoView startWaiting];
    [self photoForIndex:index withCompletionBlock:^(UIImage *photo, NSError *error) {
        [photoView stopWaiting];
        if (error != nil) {
            
        }
        else {
            [photoView displayImage:photo];
        }
    }];
}

- (void)pagingScrollView:(PZPagingScrollView *)pagingScrollView didScrollToIndex:(NSUInteger)index{
    [_pageControl setCurrentPage:index];
}
#pragma mark - PZPhotoViewDelegate
#pragma mark -

- (void)photoViewDidSingleTap:(PZPhotoView *)photoView {
    [self toggleFullScreen];
}

- (void)photoViewDidDoubleTap:(PZPhotoView *)photoView {
    // do nothing
}

- (void)photoViewDidTwoFingerTap:(PZPhotoView *)photoView {
    // do nothing
}

- (void)photoViewDidDoubleTwoFingerTap:(PZPhotoView *)photoView {
    
}
#pragma mark -

- (void)photoForIndex:(NSUInteger)index withCompletionBlock:(void (^)(UIImage *, NSError *))completionBlock {
    // prevent a range exception
    if (self.imgs.count == 0 || index > self.imgs.count - 1) {
        NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey : @"Index is out of range."};
        NSError *error = [[NSError alloc] initWithDomain:@"Photos" code:100 userInfo:userInfo];
        completionBlock(nil, error);
    }
    

    UIImageView *imgv = self.imgs[index];
    
    __block BOOL needRefresh = NO;
    UIImage *img = imgv.image;
    __weak PZViewController *weakself = self;
    __weak UIImageView *weakloader = _loader;
    NSURL *ll = [NSURL URLWithString:imgv.userInfo[@"url"]];
    
    [_loader setImageWithURL:ll placeholderImage:nil options:SDWebImageHighPriority progress:^(NSInteger receivedSize, NSInteger expectedSize) {
        if (!needRefresh) {
            needRefresh = YES;
            [weakself.progressView setHidden:NO];
            [weakself showTools];
            if (completionBlock) {
                completionBlock(img, nil);
            }
        }
        CGFloat f = receivedSize/(expectedSize*1.0f);
        [weakself.progressView setProgress:f];
    } completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        [weakloader setImage:nil];
        @autoreleasepool {
            dispatch_async( dispatch_get_main_queue(), ^{
                [weakself.progressView setHidden:YES];
                if (completionBlock) {
                    completionBlock(image, nil);
                }
            });
        }
    }];
}
#pragma mark -
- (void)saveImage{
    PZPhotoView *photoView  = (PZPhotoView *)self.pagingScrollView.visiblePageView;
    [photoView saveImage];
}

#pragma mark -
- (void)show{
    [UIView animateWithDuration:.2 animations:^{
        [self.bg setAlpha:1];
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:.2 animations:^{
            [self.pagingScrollView setAlpha:1];
        }];
    }];
}
- (void)hide{
    [UIView animateWithDuration:.2 animations:^{
        [self.view setAlpha:0];
        self.view.transform = CGAffineTransformMakeScale(1.3, 1.3);
    }completion:^(BOOL finished) {
        if (finished) {
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
        }
    }];
   
}
@end
