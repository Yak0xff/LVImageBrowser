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
//  PZPhotoView.m
//  PhotoZoom
//
//  Created by Brennan Stehling on 10/27/12.
//  Copyright (c) 2012 SmallSharptools LLC. All rights reserved.
//
//  Adjust By CodeEagle

#import "PZPhotoView.h"
#import <NSTimer+Blocks.h>
#define kZoomStep 2

@interface PZPhotoView () <UIScrollViewDelegate,UIAlertViewDelegate>
{
    BOOL showingAlert;
}
@property (weak, nonatomic) UIImageView *imageView;
@property (weak, nonatomic) UIActivityIndicatorView *activityIndicator;

@end

@implementation PZPhotoView {
    CGPoint  _pointToCenterAfterResize;
    CGFloat  _scaleToRestoreAfterResize;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setupView];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupView];
}

- (void)setupView {
    self.delegate = self;
    self.imageView = nil;
    
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.bouncesZoom = TRUE;
    self.decelerationRate = UIScrollViewDecelerationRateFast;
    
    UITapGestureRecognizer *scrollViewDoubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleScrollViewDoubleTap:)];
    [scrollViewDoubleTap setNumberOfTapsRequired:2];
    [self addGestureRecognizer:scrollViewDoubleTap];
    
    UITapGestureRecognizer *scrollViewTwoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleScrollViewTwoFingerTap:)];
    [scrollViewTwoFingerTap setNumberOfTouchesRequired:2];
    [self addGestureRecognizer:scrollViewTwoFingerTap];
    
    UITapGestureRecognizer *scrollViewSingleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleScrollViewSingleTap:)];
    [scrollViewSingleTap requireGestureRecognizerToFail:scrollViewDoubleTap];
    [self addGestureRecognizer:scrollViewSingleTap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handleScrollViewLongPress:)];
    [self addGestureRecognizer:longPress];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.imageView) {
        // center the zoom view as it becomes smaller than the size of the screen
        CGSize boundsSize = self.bounds.size;
        CGRect frameToCenter = self.imageView.frame;

        // center horizontally
        if (frameToCenter.size.width < boundsSize.width)
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2;
        else
            frameToCenter.origin.x = 0;

        // center vertically
        if (frameToCenter.size.height < boundsSize.height)
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2;
        else
            frameToCenter.origin.y = 0;

        self.imageView.frame = frameToCenter;
        
        CGPoint contentOffset = self.contentOffset;
        
        // ensure horizontal offset is reasonable
        if (frameToCenter.origin.x != 0.0)
            contentOffset.x = 0.0;
        
        // ensure vertical offset is reasonable
        if (frameToCenter.origin.y != 0.0)
            contentOffset.y = 0.0;
        
        self.contentOffset = contentOffset;
        
        // ensure content insert is zeroed out using translucent navigation bars
        self.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    }
}

- (void)setFrame:(CGRect)frame {
    BOOL sizeChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    
    if (sizeChanging) {
        [self prepareToResize];
    }
    
    [super setFrame:frame];
    
    if (sizeChanging) {
        [self recoverFromResizing];
    }
}

#pragma mark - Public Implementation
#pragma mark -

- (void)prepareForReuse {
    // start by dropping any views and resetting the key properties
    if (self.imageView != nil) {
        for (UIGestureRecognizer *gestureRecognizer in self.imageView.gestureRecognizers) {
            [self.imageView removeGestureRecognizer:gestureRecognizer];
        }
    }
    
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    
    self.imageView = nil;
}

- (void)displayImage:(UIImage *)image {
    NSAssert(self.photoViewDelegate != nil, @"Invalid State");
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.userInteractionEnabled = TRUE;
    
    NSArray *ar = [self subviews];
    NSMutableArray *preone = [NSMutableArray array];
    for (id view  in  ar) {
        if ([view isKindOfClass:[UIImageView class]]) {
            [preone addObject:view];
        }
    }
    [imageView setAlpha:0];
    [self addSubview:imageView];
    self.imageView = imageView;
    
    // add gesture recognizers to the image view
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTwoFingerTap:)];
    UITapGestureRecognizer *doubleTwoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTwoFingerTap:)];
    
    [doubleTap setNumberOfTapsRequired:2];
    [twoFingerTap setNumberOfTouchesRequired:2];
    [doubleTwoFingerTap setNumberOfTapsRequired:2];
    [doubleTwoFingerTap setNumberOfTouchesRequired:2];
    
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [twoFingerTap requireGestureRecognizerToFail:doubleTwoFingerTap];
    
    [self.imageView addGestureRecognizer:singleTap];
    [self.imageView addGestureRecognizer:doubleTap];
    [self.imageView addGestureRecognizer:twoFingerTap];
    [self.imageView addGestureRecognizer:doubleTwoFingerTap];
    
    self.contentSize = self.imageView.frame.size;
    
    [self setMaxMinZoomScalesForCurrentBounds];
    [self setZoomScale:self.minimumZoomScale animated:FALSE];
    [UIView animateWithDuration:.2 animations:^{
        for (UIImageView *view in preone) {
            [view setAlpha:0];
        }
        [imageView setAlpha:1];
    }completion:^(BOOL finished) {
        if (finished) {
            for (UIImageView *view in preone) {
                [view removeFromSuperview];
            }
        }
        
    }];
    
}

- (void)startWaiting {
    if (!self.activityIndicator) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [self addSubview:activityIndicator];
        [self bringSubviewToFront:activityIndicator];
        [activityIndicator stopAnimating];
        self.activityIndicator = activityIndicator;
    }
    
    CGFloat xPos = (CGRectGetWidth(self.frame) / 2) - (CGRectGetWidth(self.activityIndicator.frame) / 2);
    CGFloat yPos = (CGRectGetHeight(self.frame) / 2) - (CGRectGetHeight(self.activityIndicator.frame) / 2);
    
    self.activityIndicator.center = CGPointMake(xPos, yPos);
    [self bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startAnimating];
}

- (void)stopWaiting {
    [self.activityIndicator stopAnimating];
}

#pragma mark - Gestures
#pragma mark -

- (void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
    if (self.photoViewDelegate != nil) {
        [self.photoViewDelegate photoViewDidSingleTap:self];
    }
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer {
    NSUInteger scale = [self formatFloat:self.zoomScale];
    NSUInteger maxscale = [self formatFloat:self.maximumZoomScale];
    
    if (scale== maxscale) {
        // jump back to minimum scale
        [self updateZoomScaleWithGesture:gestureRecognizer newScale:self.minimumZoomScale];
    }
    else {
        // double tap zooms in
        CGFloat newScale = MIN(self.zoomScale * kZoomStep, self.maximumZoomScale);
        [self updateZoomScaleWithGesture:gestureRecognizer newScale:newScale];
    }
    
    if (self.photoViewDelegate != nil) {
        [self.photoViewDelegate photoViewDidDoubleTap:self];
    }
}

- (void)handleTwoFingerTap:(UIGestureRecognizer *)gestureRecognizer {
    // two-finger tap zooms out
    CGFloat newScale = MAX([self zoomScale] / kZoomStep, self.minimumZoomScale);
    [self updateZoomScaleWithGesture:gestureRecognizer newScale:newScale];
    
    if (self.photoViewDelegate != nil) {
        [self.photoViewDelegate photoViewDidTwoFingerTap:self];
    }
}

- (void)handleDoubleTwoFingerTap:(UIGestureRecognizer *)gestureRecognizer {
    if (self.photoViewDelegate != nil) {
        [self.photoViewDelegate photoViewDidDoubleTwoFingerTap:self];
    }
}

- (void)handleScrollViewSingleTap:(UIGestureRecognizer *)gestureRecognizer {
    if (self.photoViewDelegate != nil) {
        [self.photoViewDelegate photoViewDidSingleTap:self];
    }
}

- (void)handleScrollViewDoubleTap:(UIGestureRecognizer *)gestureRecognizer {
    if (self.imageView.image == nil) return;
    CGPoint center =[self adjustPointIntoImageView:[gestureRecognizer locationInView:gestureRecognizer.view]];
    
    if (!CGPointEqualToPoint(center, CGPointZero)) {
        CGFloat newScale = MIN([self zoomScale] * kZoomStep, self.maximumZoomScale);
        [self updateZoomScale:newScale withCenter:center];
    }
}

- (void)handleScrollViewTwoFingerTap:(UIGestureRecognizer *)gestureRecognizer {
    if (self.imageView.image == nil) return;
    CGPoint center =[self adjustPointIntoImageView:[gestureRecognizer locationInView:gestureRecognizer.view]];
    
    if (!CGPointEqualToPoint(center, CGPointZero)) {
        CGFloat newScale = MAX([self zoomScale] / kZoomStep, self.minimumZoomScale);
        [self updateZoomScale:newScale withCenter:center];
    }
}

- (void)handleScrollViewLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (self.imageView.image != nil && !showingAlert) {
        showingAlert = YES;
        [self saveImage];
    }
}
#pragma mark -
- (void)saveImage{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Save Image" message:@"Save To Photo" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Save", nil];
    [alert show];
}
#pragma mark - Alert
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex) {
        showingAlert = NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
        });
    }
}
#pragma mark - Save Image
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    
    UIAlertView *alertView;
    
    if (error != NULL){
        alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Save Error",nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
        
    }else{
        alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Save Success", nil) message:NSLocalizedString(@"Image has Saved !",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
       [alertView show];
        [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
        } repeats:NO];
    });
}
#pragma mark -

- (CGPoint)adjustPointIntoImageView:(CGPoint)center {
    BOOL contains = CGRectContainsPoint(self.imageView.frame, center);
    
    if (!contains) {
        center.x = center.x / self.zoomScale;
        center.y = center.y / self.zoomScale;
        
        // adjust center with bounds and scale to be a point within the image view bounds
        CGRect imageViewBounds = self.imageView.bounds;
        
        center.x = MAX(center.x, imageViewBounds.origin.x);
        center.x = MIN(center.x, imageViewBounds.origin.x + imageViewBounds.size.height);
        
        center.y = MAX(center.y, imageViewBounds.origin.y);
        center.y = MIN(center.y, imageViewBounds.origin.y + imageViewBounds.size.width);
        
        return center;
    }
    
    return CGPointZero;
}

#pragma mark - Support Methods
#pragma mark -

- (void)updateZoomScale:(CGFloat)newScale {
    CGPoint center = CGPointMake(self.imageView.bounds.size.width/ 2.0, self.imageView.bounds.size.height / 2.0);
    [self updateZoomScale:newScale withCenter:center];
}

- (void)updateZoomScaleWithGesture:(UIGestureRecognizer *)gestureRecognizer newScale:(CGFloat)newScale {
    CGPoint center = [gestureRecognizer locationInView:gestureRecognizer.view];
    [self updateZoomScale:newScale withCenter:center];
}
- (NSUInteger)formatFloat:(CGFloat)f{
    NSUInteger ff = f*100;
    return ff;
}
- (void)updateZoomScale:(CGFloat)newScale withCenter:(CGPoint)center {
    
    NSUInteger scale = [self formatFloat:newScale];
    NSUInteger maxscale = [self formatFloat:self.maximumZoomScale];
    NSUInteger minscale = [self formatFloat:self.minimumZoomScale];
#pragma unused(maxscale)
#pragma unused(scale)
#pragma unused(minscale)
    NSAssert(scale >= minscale, @"Invalid State");
    NSAssert(scale <= maxscale, @"Invalid State");

    if (self.zoomScale != newScale) {
        CGRect zoomRect = [self zoomRectForScale:newScale withCenter:center];
        [self zoomToRect:zoomRect animated:YES];
    }
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    NSUInteger sscale = [self formatFloat:scale];
    NSUInteger maxscale = [self formatFloat:self.maximumZoomScale];
    NSUInteger minscale = [self formatFloat:self.minimumZoomScale];
#pragma unused(maxscale)
#pragma unused(sscale)
#pragma unused(minscale)
    NSAssert(sscale >= minscale, @"Invalid State");
    NSAssert(sscale <= maxscale, @"Invalid State");
    
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates.
    zoomRect.size.width = self.frame.size.width / scale;
    zoomRect.size.height = self.frame.size.height / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    // calculate minimum scale to perfectly fit image width, and begin at that scale
    CGSize boundsSize = self.bounds.size;
    
    CGFloat minScale = 0.25;
    
    if (self.imageView.bounds.size.width > 0.0 && self.imageView.bounds.size.height > 0.0) {
        // calculate min/max zoomscale
        CGFloat xScale = boundsSize.width  / self.imageView.bounds.size.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / self.imageView.bounds.size.height;   // the scale needed to perfectly fit the image height-wise
        
        minScale = MIN(xScale, yScale);
    }
    
    CGFloat maxScale = minScale * (kZoomStep * 2);
    
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
}

- (void)prepareToResize {
    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _pointToCenterAfterResize = [self convertPoint:boundsCenter toView:self.imageView];
    
    _scaleToRestoreAfterResize = self.zoomScale;
    
    // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
    // allowable scale when the scale is restored.
    if (_scaleToRestoreAfterResize <= self.minimumZoomScale + FLT_EPSILON)
        _scaleToRestoreAfterResize = 0;
}

- (void)recoverFromResizing {
    [self setMaxMinZoomScalesForCurrentBounds];
    
    // Step 1: restore zoom scale, first making sure it is within the allowable range.
    CGFloat maxZoomScale = MAX(self.minimumZoomScale, _scaleToRestoreAfterResize);
    self.zoomScale = MIN(self.maximumZoomScale, maxZoomScale);
    
    // Step 2: restore center point, first making sure it is within the allowable range.
    
    // 2a: convert our desired center point back to our own coordinate space
    CGPoint boundsCenter = [self convertPoint:_pointToCenterAfterResize fromView:self.imageView];
    
    // 2b: calculate the content offset that would yield that center point
    CGPoint offset = CGPointMake(boundsCenter.x - self.bounds.size.width / 2.0,
                                 boundsCenter.y - self.bounds.size.height / 2.0);
    
    // 2c: restore offset, adjusted to be within the allowable range
    CGPoint maxOffset = [self maximumContentOffset];
    CGPoint minOffset = [self minimumContentOffset];
    
    CGFloat realMaxOffset = MIN(maxOffset.x, offset.x);
    offset.x = MAX(minOffset.x, realMaxOffset);
    
    realMaxOffset = MIN(maxOffset.y, offset.y);
    offset.y = MAX(minOffset.y, realMaxOffset);
    
    self.contentOffset = offset;
}

- (CGPoint)maximumContentOffset {
    CGSize contentSize = self.contentSize;
    CGSize boundsSize = self.bounds.size;
    return CGPointMake(contentSize.width - boundsSize.width, contentSize.height - boundsSize.height);
}

- (CGPoint)minimumContentOffset {
    return CGPointZero;
}

#pragma mark - UIScrollViewDelegate Methods
#pragma mark -

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}


@end
