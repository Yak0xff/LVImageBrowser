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
//  PZPagingScrollView.h
//  PhotoZoom
//
//  Created by Brennan Stehling on 11/9/12.
//  Copyright (c) 2012 SmallSharptools LLC. All rights reserved.
//
//  Adjust By CodeEagle

#import <UIKit/UIKit.h>

@protocol PZPagingScrollViewDelegate;

@interface PZPagingScrollView : UIScrollView

@property (assign, nonatomic) IBOutlet id<PZPagingScrollViewDelegate>pagingViewDelegate;
@property (readonly) UIView *visiblePageView;
@property (assign) BOOL suspendTiling;

- (void)displayPagingViewAtIndex:(NSUInteger)index;
- (void)resetDisplay;
@end

@protocol PZPagingScrollViewDelegate <NSObject>

@required

- (Class)pagingScrollView:(PZPagingScrollView *)pagingScrollView classForIndex:(NSUInteger)index;
- (NSUInteger)pagingScrollViewPagingViewCount:(PZPagingScrollView *)pagingScrollView;
- (UIView *)pagingScrollView:(PZPagingScrollView *)pagingScrollView pageViewForIndex:(NSUInteger)index;
- (void)pagingScrollView:(PZPagingScrollView *)pagingScrollView preparePageViewForDisplay:(UIView *)pageView forIndex:(NSUInteger)index;
- (void)pagingScrollView:(PZPagingScrollView *)pagingScrollView didScrollToIndex:(NSUInteger)index;

@end
