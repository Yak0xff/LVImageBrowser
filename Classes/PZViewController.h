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
//  PZViewController.h
//  PhotoZoom
//
//  Created by Brennan Stehling on 10/27/12.
//  Copyright (c) 2012 SmallSharptools LLC. All rights reserved.
//
//  Adjust By CodeEagle

#import <UIKit/UIKit.h>
#import <LVUtils.h>
#import "PZPagingScrollView.h"

@interface PZViewController : UIViewController
@property (nonatomic,weak) NSArray *imgs;
@property (nonatomic) NSUInteger startIndex;

- (void)show;
- (void)hide;
@end
