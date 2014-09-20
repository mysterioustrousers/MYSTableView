//
//  NSIndexPath+BTRAdditions.h
//  Butter
//
//  Created by Adam Kirk on 10/31/13.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexPath (MYSTableView)
@property (nonatomic, assign, readonly) NSInteger section;
@property (nonatomic, assign, readonly) NSInteger row;
+ indexPathForRow:(NSInteger)row inSection:(NSInteger)section;
@end
