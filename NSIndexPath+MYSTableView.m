//
//  NSIndexPath+BTRAdditions.m
//  Butter
//
//  Created by Adam Kirk on 10/31/13.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import "NSIndexPath+MYSTableView.h"

@implementation NSIndexPath (MYSTableView)

- (NSInteger)section
{
    if ([self length] > 0) {
        return [self indexAtPosition:0];
    }
    return 0;
}

- (NSInteger)row
{
    if ([self length] > 1) {
        return [self indexAtPosition:1];
    }
    return 0;
}

+ indexPathForRow:(NSInteger)row inSection:(NSInteger)section
{
    NSUInteger indexes[] = { section, row };
    return [NSIndexPath indexPathWithIndexes:indexes length:2];
}

@end
