//
//  MYSTableView.h
//  Butter
//
//  Created by Adam Kirk on 10/30/13.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSIndexPath+MYSTableView.h"


@protocol MYSTableViewDataSource;
@protocol MYSTableViewDelegate;


@interface MYSTableView : NSTableView


@property (nonatomic, weak) id<MYSTableViewDataSource> MYS_dataSource;


@property (nonatomic, weak) id<MYSTableViewDelegate> MYS_delegate;

/**
 *  If `tableView:heightForHeaderInSection:` is not implemented, this value is used for the height of section headers.
 */
@property (nonatomic, assign) CGFloat sectionHeaderHeight;

/**
 *  default is YES. Controls whether rows can be selected when not in editing mode.
 */
@property (nonatomic, assign) BOOL allowsSelection;

/**
 *  default is the standard separator gray
 */
@property (nonatomic, strong) NSColor *separatorColor;

/**
 *  Scrolling padding around the table view content.
 */
@property (nonatomic, assign) NSEdgeInsets edgeInsets;

/**
 *  accessory view for above row content. default is nil. not to be confused with section header.
 */
@property (nonatomic, strong) NSTableHeaderView *tableHeaderView;


@property (nonatomic, assign) BOOL floatingSectionHeaders;


/**
 *  Converts a row index from the NSTableView into an index path that represents the row.
 *
 *  @param rowIndex The absolute row index of the table (including header rows)..
 *
 *  @return Returns the corresponding index path for the row or `nil` if the rowIndex is a section header.
 */
- (NSIndexPath *)indexPathForRowIndex:(NSInteger)rowIndex;

/**
 *  Converts an index path into an aboslute NSTableView row index.i
 *
 *  @param indexPath The index path you want to get a row index for.
 *
 *  @return Returns the NSTableView absolute row index. This will never be a section header row because index paths
 *          cannot represent header rows.
 */
- (NSInteger)rowIndexForIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;

- (CGRect)rectForSection:(NSInteger)section;
- (CGRect)rectForHeaderInSection:(NSInteger)section;
- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point;
- (NSIndexPath *)indexPathForCell:(id)cell;
- (NSArray *)indexPathsForRowsInRect:(CGRect)rect;

- (void)endUpdatesWithCompletion:(void (^)(void))completion;

- (id)cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)visibleCells;
- (NSArray *)indexPathsForVisibleRows;
- (id)headerViewForSection:(NSInteger)section;

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(NSTableViewAnimationOptions)animation;
- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(NSTableViewAnimationOptions)animation;
- (void)reloadSections:(NSIndexSet *)sections;

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(NSTableViewAnimationOptions)animation;
- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(NSTableViewAnimationOptions)animation;
- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths;
- (void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

- (NSIndexPath *)indexPathForSelectedRow;
- (NSArray *)indexPathsForSelectedRows;

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath;

/**
 As opposed to selecting the row, this just highlights it and does not propogate the action of selecting it.
 */
- (void)highlightRowAtIndexPath:(NSIndexPath *)indexPath;

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath;

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier;
- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;
- (id)dequeueReusableHeaderViewWithIdentifier:(NSString *)identifier;

- (void)registerNib:(NSNib *)nib forCellReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(NSNib *)nib forHeaderViewReuseIdentifier:(NSString *)identifier;

@end




@protocol MYSTableViewDataSource <NSTableViewDataSource>

- (NSInteger)tableView:(MYSTableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSView *)tableView:(MYSTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional
- (NSInteger)numberOfSectionsInTableView:(MYSTableView *)tableView;
- (NSString *)tableView:(MYSTableView *)tableView titleForHeaderInSection:(NSInteger)section;

@end




@protocol MYSTableViewDelegate <NSTableViewDelegate>
@optional

- (void)tableView:(MYSTableView *)tableView willDisplayCell:(NSView *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(MYSTableView *)tableView willDisplayHeaderView:(NSView *)view forSection:(NSInteger)section;

- (CGFloat)tableView:(MYSTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(MYSTableView *)tableView heightForHeaderInSection:(NSInteger)section;


- (NSView *)tableView:(MYSTableView *)tableView viewForHeaderInSection:(NSInteger)section;

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRowAtIndexPath:(NSIndexPath *)indexPath;

- (BOOL)tableView:(MYSTableView *)tableView shouldSelectRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSArray *)tableView:(MYSTableView *)tableView willSelectRowsAtIndexPaths:(NSArray *)indexPaths;
- (NSArray *)tableView:(MYSTableView *)tableView willDeselectRowsAtIndexPaths:(NSArray *)indexPaths;

- (void)tableView:(MYSTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(MYSTableView *)tableView didSelectRowsAtIndexPaths:(NSArray *)indexPaths;
- (void)tableView:(MYSTableView *)tableView didDeselectRowsAtIndexPaths:(NSArray *)indexPaths;

- (void)tableView:(MYSTableView *)tableView didPressEnterOnRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event;
- (void)tableView:(MYSTableView *)tableView didClickRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event;
- (void)tableView:(MYSTableView *)tableView didRightClickOnRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event;
- (NSMenu *)tableView:(MYSTableView *)tableView menuForRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event;

@required
/**
 *  You must implement this if you want `tableView:viewForHeaderInSection:` to ever be called. Default implementation
 *  returns NO;
 */
- (BOOL)tableView:(MYSTableView *)tableView hasHeaderInSection:(NSInteger)section;

@end





@interface MYSScrollViewAnimation : NSAnimation
@property (retain) NSScrollView *scrollView;
@property NSPoint originPoint;
@property NSPoint targetPoint;
+ (void)animatedScrollPointToCenter:(NSPoint)targetPoint inScrollView:(NSScrollView *)scrollView duration:(NSTimeInterval)duration;
+ (void)animatedScrollToPoint:(NSPoint)targetPoint inScrollView:(NSScrollView *)scrollView duration:(NSTimeInterval)duration;
@end


