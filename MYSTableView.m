//
//  MYSTableView.m
//  Butter
//
//  Created by Adam Kirk on 10/30/13.
//  Copyright (c) 2013 ButterKit. All rights reserved.
//

#import "MYSTableView.h"
#import <QuartzCore/QuartzCore.h>


@interface MYSTableViewSection : NSObject
@property (nonatomic, weak  ) MYSTableView *tableView;
@property (nonatomic, assign) NSUInteger   rowCount;
@property (nonatomic, assign) BOOL         hasHeader;
@property (nonatomic, strong) NSView       *headerView;
- (NSUInteger)totalRows;
@end


@interface MYSTableViewDataSourceStub : NSObject <MYSTableViewDataSource>
@end

@interface MYSTableViewDelegateStub : NSObject <MYSTableViewDelegate>
@end


@interface MYSTableViewDispatcher : NSObject <MYSTableViewDelegate, MYSTableViewDataSource>
@property (nonatomic, weak  ) MYSTableView               *tableView;
@property (nonatomic, strong) MYSTableViewDataSourceStub *dataSourceStub;
@property (nonatomic, strong) MYSTableViewDelegateStub   *delegateStub;
@end


@interface MYSTableView () <NSTableViewDelegate, NSTableViewDataSource>
@property (nonatomic, copy  ) NSArray                *sections;
@property (nonatomic, strong) MYSTableViewDispatcher *dispatcher;
@property (nonatomic, assign) BOOL                   updatesBeganExternally;
@property (nonatomic, strong) void                   (^updateCompletionBlock)(void);
@property (nonatomic, strong) NSArray                *selectingIndexPaths;
@property (nonatomic, strong) NSArray                *deselectingIndexPaths;
@property (nonatomic, assign) BOOL                   silenceSelection;
@end




@implementation MYSTableView

- (void)commonInit
{
    self.dispatcher             = [MYSTableViewDispatcher new];
    self.dispatcher.tableView   = self;
    self.sectionHeaderHeight    = 20;
    self.updatesBeganExternally = YES;
    self.updateCompletionBlock  = nil;
    self.edgeInsets             = NSEdgeInsetsMake(0, 0, 0, 0);
}

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}


#pragma mark (overrides)

- (void)reloadData
{
    [self rehash];
    [super reloadData];
}

- (void)setMYS_delegate:(id<MYSTableViewDelegate>)MYS_delegate
{
    _MYS_delegate   = MYS_delegate;
    self.sections   = nil;
    [super setDelegate:self];
}

- (void)setMYS_dataSource:(id<MYSTableViewDataSource>)MYS_dataSource
{
    _MYS_dataSource = MYS_dataSource;
    self.sections   = nil;
    [super setDataSource:self];
}

- (void)setDelegate:(id<NSTableViewDelegate>)delegate
{

}

- (void)setDataSource:(id<NSTableViewDataSource>)aSource
{

}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation invokeWithTarget:self.dispatcher];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [super respondsToSelector:aSelector] || [self.dispatcher respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [self.dispatcher methodSignatureForSelector:aSelector];
}

- (void)beginUpdates
{
    self.updatesBeganExternally = YES;
    [CATransaction begin];
    [super beginUpdates];
}

- (void)endUpdates
{
    [self endUpdatesWithCompletion:nil];
}

- (void)endUpdatesWithCompletion:(void (^)(void))completion
{
    self.updatesBeganExternally = NO;
    [self rehash];
    [CATransaction setCompletionBlock:^{
        if (completion) completion();
        [self rehash];
        [self reloadData];
    }];
    [super endUpdates];
    [CATransaction commit];
}




#pragma mark - Events

- (void)keyDown:(NSEvent *)theEvent
{
    if ([theEvent.characters isEqualToString:@"\r"]) {
        [self.dispatcher tableView:self didPressEnterOnRowAtIndexPath:[self indexPathForSelectedRow] withEvent:theEvent];
    }
    else {
        [super keyDown:theEvent];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    [self.dispatcher tableView:self didClickRowAtIndexPath:[self indexPathForSelectedRow] withEvent:theEvent];
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
    NSPoint pointInTableView = [self convertPoint:event.locationInWindow fromView:nil];
    NSIndexPath *ip = [self indexPathForRowAtPoint:pointInTableView];
    [self.dispatcher tableView:self didRightClickOnRowAtIndexPath:ip withEvent:event];
    NSMenu *menu = [self.dispatcher tableView:self menuForRowAtIndexPath:ip withEvent:event];
    return menu ?: [super menuForEvent:event];
}




#pragma mark - Public

- (NSIndexPath *)indexPathForRowIndex:(NSInteger)rowIndex
{
    // for debugging only
    if (![self hasValideIndexPathForRow:rowIndex]) {
        NSLog(@"MYS number of sections: %@", @([self.sections count]));
        NSLog(@"MYS delegate reporting number of sections: %@", @([self.dispatcher numberOfSectionsInTableView:self]));
        NSLog(@"delegate reporting number of rows: %@", @([self.dataSource numberOfRowsInTableView:self]));
        NSInteger sectionIndex = 0;
        for (MYSTableViewSection *section in self.sections) {
            NSLog(@"MYS number of rows for section %@: %@", @(sectionIndex), @([section totalRows]));
            NSLog(@"MYS delegate reporting number of rows for section %@: %@", @(sectionIndex), @([self.dispatcher tableView:self numberOfRowsInSection:sectionIndex]));
        }
        NSLog(@"tableview number of rows: %@", @([super numberOfRows]));
        NSLog(@"Invalid row index %@", @(rowIndex));
    }
    if (rowIndex < 0) return nil;
    NSInteger currentSectionIndex   = 0;
    NSInteger currentRowIndex       = rowIndex;
    for (MYSTableViewSection *section in self.sections) {
        NSInteger numberOfRowsInSection = [section totalRows];
        if (section.hasHeader && currentRowIndex == 0) {
            return nil;
        }
        else if (currentRowIndex < numberOfRowsInSection) {
            NSInteger row = section.hasHeader ? currentRowIndex - 1 : currentRowIndex;
            return [NSIndexPath indexPathForRow:row inSection:currentSectionIndex];
        }
        currentRowIndex -= numberOfRowsInSection;
        currentSectionIndex++;
    }
    NSAssert(NO, @"There is no valid index path for this row index: %@", @(rowIndex));
    return nil;
}

- (NSInteger)rowIndexForIndexPath:(NSIndexPath *)indexPath
{
    return [self rowIndexForSection:indexPath.section row:indexPath.row];
}

- (NSInteger)rowIndexForSection:(NSInteger)section row:(NSInteger)row
{
    NSInteger rowSum = 0;
    NSInteger currentSection = 0;
    for (MYSTableViewSection *s in self.sections) {
        if (currentSection++ == section) {
            return rowSum + (s.hasHeader ? row + 1 : row);
        }
        rowSum += [s totalRows];
    }
    // allow the row to be one out of bounds, so rows can be added to the end
    if (rowSum == [self shiftedNumberOfRows] + 1) return rowSum - 1;
    NSAssert(NO, @"indexPath is invalid.");
    return 0;
}

- (NSInteger)numberOfSections
{
    return [self.sections count];
}

- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
    if ([self.sections count] > section) {
        return [self.sections[section] rowCount];
    }
    return 0;
}

- (CGRect)rectForSection:(NSInteger)section
{
    NSAssert(section < [self.sections count], @"Invalid section");
    CGRect rect;
    NSInteger numberOfRowsInSection = [self.sections[section] rowCount];
    NSInteger firstRowIndex = [self rowIndexForSection:section row:0];
    NSInteger lastRowIndex = firstRowIndex + numberOfRowsInSection;
    for (NSInteger i = firstRowIndex; i < lastRowIndex; i++) {
        rect = CGRectUnion(rect, [self rectOfRow:i]);
    }
    return rect;
}

- (CGRect)rectForHeaderInSection:(NSInteger)section
{
    NSAssert(section < [self.sections count], @"`section` is out of bounds.");
    MYSTableViewSection *s = self.sections[section];
    return s.headerView.frame;
}

- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger rowIndex = [self rowIndexForIndexPath:indexPath];
    return [self rectOfRow:rowIndex];
}

- (NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point
{
    NSUInteger rowIndex = [self unshiftedRow:[self rowAtPoint:point]];
    return [self indexPathForRowIndex:rowIndex];
}

- (NSIndexPath *)indexPathForCell:(id)cell
{
    NSUInteger rowIndex = [self unshiftedRow:[self rowForView:[cell superview]]];
    return [self indexPathForRowIndex:rowIndex];
}

- (NSArray *)indexPathsForRowsInRect:(CGRect)rect
{
    if ([self numberOfContentRows] == 0) return nil;
    NSRange range = [self rowsInRect:rect];
    if (self.edgeInsets.top > 0) {
        range.length--;
    }
    if (self.edgeInsets.bottom > 0) {
        range.length--;
    }
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSUInteger i = range.location; i < range.location + range.length; i++) {
        NSIndexPath *ip = [self indexPathForRowIndex:i];
        if (ip) [indexPaths addObject:ip];
    }
    return indexPaths;
}

- (id)cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > [self numberOfRowsInSection:indexPath.section] - 1) return nil;
    NSUInteger rowIndex = [self rowIndexForIndexPath:indexPath];
    return [self viewAtColumn:0 row:rowIndex makeIfNecessary:YES];
}

- (NSArray *)visibleCells
{
    NSMutableArray *cells = [NSMutableArray new];
    [self enumerateAvailableRowViewsUsingBlock:^(NSTableRowView *rowView, NSInteger row) {
        [cells addObject:[rowView viewAtColumn:0]];
    }];
    return cells;
}

- (NSArray *)indexPathsForVisibleRows
{
    return [self indexPathsForRowsInRect:[[self enclosingScrollView] contentView].bounds];
}

- (id)headerViewForSection:(NSInteger)aSection
{
    MYSTableViewSection *section = self.sections[aSection];
    return section.headerView;
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    NSUInteger rowIndex = [self rowIndexForIndexPath:indexPath];
    if (animated) {
        CGRect rowRect = [self rectForRowAtIndexPath:indexPath];
        [MYSScrollViewAnimation animatedScrollPointToCenter:rowRect.origin inScrollView:[self enclosingScrollView] duration:0.5];
    }
    else {
        [self scrollRowToVisible:rowIndex];
    }
}

- (void)insertSections:(NSIndexSet *)sections withRowAnimation:(NSTableViewAnimationOptions)animation
{
    NSIndexSet *rowIndexes = [self rowIndexesInSections:sections includeHeaders:YES];
    [self beginInternalUpdates];
    [self insertRowsAtIndexes:rowIndexes withAnimation:animation];
    [self endInternalUpdates];
    [self rehash];
}

- (void)deleteSections:(NSIndexSet *)sections withRowAnimation:(NSTableViewAnimationOptions)animation
{
    NSIndexSet *rowIndexes = [self rowIndexesInSections:sections includeHeaders:YES];
    [self beginInternalUpdates];
    [self removeRowsAtIndexes:rowIndexes withAnimation:animation];
    [self endInternalUpdates];
    [self rehash];
}

- (void)reloadSections:(NSIndexSet *)sections
{
    NSIndexSet *rowIndexes = [self rowIndexesInSections:sections includeHeaders:YES];
    [self reloadDataForRowIndexes:rowIndexes columnIndexes:0];
    [self rehash];
}

//- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection
//{
//    NSIndexSet *fromRowIndexes  = [self rowIndexesInSections:[NSIndexSet indexSetWithIndex:section] includeHeaders:YES];
//    NSIndexSet *toRowIndexes    = [self rowIndexesInSections:[NSIndexSet indexSetWithIndex:newSection] includeHeaders:YES];
//
//}

- (void)insertRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(NSTableViewAnimationOptions)animation
{
    NSIndexSet *rowIndexes = [self rowIndexesForIndexPaths:indexPaths];
    [self beginInternalUpdates];
    [self insertRowsAtIndexes:rowIndexes withAnimation:animation];
    [self endInternalUpdates];
    [self rehash];
}

- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths withRowAnimation:(NSTableViewAnimationOptions)animation
{
    NSIndexSet *rowIndexes = [self rowIndexesForIndexPaths:indexPaths];
    [self beginInternalUpdates];
    [self removeRowsAtIndexes:rowIndexes withAnimation:animation];
    [self endInternalUpdates];
    [self rehash];
}

- (void)reloadRowsAtIndexPaths:(NSArray *)indexPaths
{
    NSIndexSet *rowIndexes = [self rowIndexesForIndexPaths:indexPaths];
    [self reloadDataForRowIndexes:rowIndexes columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    [self rehash];
}

- (void)moveRowAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    NSInteger fromRowIndex = [self rowIndexForIndexPath:indexPath];
    NSInteger toRowIndex = [self rowIndexForIndexPath:newIndexPath];
    [self beginInternalUpdates];
    [self moveRowAtIndex:fromRowIndex toIndex:toRowIndex];
    [self endInternalUpdates];
    [self rehash];
}

- (NSIndexPath *)indexPathForSelectedRow
{
    NSInteger selectedRowIndex = [self unshiftedRow:[self selectedRow]];
    return [self indexPathForRowIndex:selectedRowIndex];
}

- (NSArray *)indexPathsForSelectedRows
{
    NSIndexSet *selectedIndexes = [self unshiftedRowIndexes:[self selectedRowIndexes]];
    return [self indexPathsForRowIndexes:selectedIndexes];
}

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger rowIndex = [self rowIndexForIndexPath:indexPath];
    _selectingIndexPaths = @[indexPath];
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:[self shiftedRow:rowIndex]] byExtendingSelection:NO];
}

- (void)highlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.silenceSelection = YES;
    [self selectRowAtIndexPath:indexPath];
    self.silenceSelection = NO;
}

- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger rowIndex = [self rowIndexForIndexPath:indexPath];
    [self deselectRow:[self shiftedRow:rowIndex]];
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier
{
    return [self makeViewWithIdentifier:identifier owner:nil];
}

- (id)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath
{
    return [self makeViewWithIdentifier:identifier owner:nil];
}

- (id)dequeueReusableHeaderViewWithIdentifier:(NSString *)identifier
{
    return [self makeViewWithIdentifier:identifier owner:nil];
}

- (void)registerNib:(NSNib *)nib forCellReuseIdentifier:(NSString *)identifier
{
    [self registerNib:nib forIdentifier:identifier];
}

//- (void)registerClass:(Class)cellClass forCellReuseIdentifier:(NSString *)identifier
//{
//}

- (void)registerNib:(NSNib *)nib forHeaderViewReuseIdentifier:(NSString *)identifier
{
    NSString *headerIdentifier = [NSString stringWithFormat:@"MYSHeader.%@", identifier];
    [self registerNib:nib forIdentifier:headerIdentifier];
}

//- (void)registerClass:(Class)aClass forHeaderViewReuseIdentifier:(NSString *)identifier
//{
//}


#pragma mark (properties)

- (void)setSeparatorColor:(NSColor *)separatorColor
{
    [self setGridColor:separatorColor];
}

- (void)setTableHeaderView:(NSTableHeaderView *)tableHeaderView
{
    [self setHeaderView:tableHeaderView];
}

- (void)setFloatingSectionHeaders:(BOOL)floatingSectionHeaders
{
    self.floatsGroupRows = floatingSectionHeaders;
}

- (BOOL)floatingSectionHeaders
{
    return self.floatsGroupRows;
}




#pragma mark - DATASOURCE table view

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    [self rehash];
    NSInteger numberOfRows = 0;
    for (MYSTableViewSection *section in self.sections) {
        numberOfRows += [section totalRows];
    }
    if (self.edgeInsets.top > 0) {
        numberOfRows++;
    }
    if (self.edgeInsets.bottom > 0) {
        numberOfRows++;
    }
    return numberOfRows;
}




#pragma mark - DELEGATE table view

- (id)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    [self rehash];
    if (self.edgeInsets.bottom > 0) {
        if ( row == [tableView numberOfRows] - 1) {
            return [NSView new];
        }
    }

    if (self.edgeInsets.top > 0) {
        if (row == 0) {
            return [NSView new];
        }
        row--;
    }

    if ([self isHeaderRowIndex:row]) {
        NSInteger sectionIndex = [self sectionIndexForRowIndex:row];
        NSString *headerText = [self.dispatcher tableView:self titleForHeaderInSection:sectionIndex];
        if ([headerText length] > 0) {
            NSTextField *textField = [NSTextField new];
            [textField setEditable:NO];
            textField.stringValue = headerText;
            [textField setBezeled:NO];
            [textField setDrawsBackground:NO];
            return textField;
        }
        else {
            id cell = [self.dispatcher tableView:self viewForHeaderInSection:sectionIndex];
            [self.dispatcher tableView:self willDisplayHeaderView:cell forSection:sectionIndex];
            return cell;
        }
    }
    else {
        NSIndexPath *ip = [self indexPathForRowIndex:row];
        id cell = [self.dispatcher tableView:self cellForRowAtIndexPath:ip];
        [self.dispatcher tableView:self willDisplayCell:cell forRowAtIndexPath:ip];
        return cell;
    }
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    [self rehash];
    if (self.edgeInsets.bottom > 0) {
        if ( row == [tableView numberOfRows] - 1) {
            return;
        }
    }

    if (self.edgeInsets.top > 0) {
        if (row == 0) {
            return;
        }
        row++;
    }

    if ([self isHeaderRowIndex:row]) {
        NSInteger sectionIndex = [self sectionIndexForRowIndex:row];
        return [self.dispatcher tableView:self willDisplayHeaderView:cell forSection:sectionIndex];
    }
    else {
        NSIndexPath *ip = [self indexPathForRowIndex:row];
        [self.dispatcher tableView:self willDisplayCell:cell forRowAtIndexPath:ip];
    }
}

- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
    [self rehash];
    NSMutableIndexSet *mutableProposedIndexes = [proposedSelectionIndexes mutableCopy];
    [proposedSelectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (self.edgeInsets.top > 0 && idx == 0) {
            [mutableProposedIndexes removeIndex:idx];
        }
        if (self.edgeInsets.bottom > 0 && idx == [tableView numberOfRows] - 1) {
            [mutableProposedIndexes removeIndex:idx];
        }
    }];

    if (self.silenceSelection) return mutableProposedIndexes;

    NSArray *currentIndexPaths  = [self indexPathsForRowIndexes:[self selectedRowIndexes]];
    NSArray *proposedIndexPaths = [self indexPathsForRowIndexes:mutableProposedIndexes];
    NSArray *actualIndexPaths   = [self.dispatcher tableView:self willSelectRowsAtIndexPaths:proposedIndexPaths];

    // report cells being selected
    NSMutableSet *addedSet = [NSMutableSet setWithArray:actualIndexPaths];
    [addedSet minusSet:[NSSet setWithArray:currentIndexPaths]];
    _selectingIndexPaths = [addedSet allObjects];
    if ([_selectingIndexPaths count] > 0)  {
        [self.dispatcher tableView:self willSelectRowsAtIndexPaths:[addedSet allObjects]];
    }

    // report cells being deselected
    NSMutableSet *removedSet = [NSMutableSet setWithArray:currentIndexPaths];
    [removedSet minusSet:[NSSet setWithArray:actualIndexPaths]];
    _deselectingIndexPaths = [removedSet allObjects];
    if ([_deselectingIndexPaths count] > 0) {
        [self.dispatcher tableView:self willDeselectRowsAtIndexPaths:[removedSet allObjects]];
    }

    NSMutableIndexSet *actualSelectionIndexes = [NSMutableIndexSet new];
    for (NSIndexPath *ip in actualIndexPaths) {
        NSUInteger idx = [self rowIndexForIndexPath:ip];
        [actualSelectionIndexes addIndex:idx];
    }
    return actualSelectionIndexes;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    [self rehash];
    if (self.edgeInsets.bottom > 0) {
        if (row == [tableView numberOfRows] - 1) {
            return self.edgeInsets.bottom;
        }
    }

    if (self.edgeInsets.top > 0) {
        if (row == 0) {
            return self.edgeInsets.top;
        }
        row--;
    }

    if ([self isHeaderRowIndex:row]) {
        NSInteger sectionIndex = [self sectionIndexForRowIndex:row];
        CGFloat height = [self.dispatcher tableView:self heightForHeaderInSection:sectionIndex];
        return height ?: self.sectionHeaderHeight;
    }
    else {
        NSIndexPath *ip = [self indexPathForRowIndex:row];
        return [self.dispatcher tableView:self heightForRowAtIndexPath:ip];
    }
}

- (BOOL)tableView:(NSTableView *)tableView isGroupRow:(NSInteger)row
{
    [self rehash];
    if (self.edgeInsets.bottom > 0) {
        if (row == [tableView numberOfRows] - 1) {
            return NO;
        }
    }
    if (self.edgeInsets.top > 0) {
        if (row == 0) {
            return NO;
        }
        row--;
    }
    if ([self hasValideIndexPathForRow:row]) {
        return [self isHeaderRowIndex:row];
    }
    else {
        return NO;
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    [self rehash];
    if (self.silenceSelection) return;

    if ([_selectingIndexPaths count] > 0) {
        NSArray *indexPaths = _selectingIndexPaths;
        _selectingIndexPaths = nil;
        if ([self unshiftedRow:[self selectedRow]] >= 0) {
            NSIndexPath *indexPath = [self indexPathForRowIndex:[self unshiftedRow:[self selectedRow]]];
            [self.dispatcher tableView:self didSelectRowAtIndexPath:indexPath];
        }
        [self.dispatcher tableView:self didSelectRowsAtIndexPaths:indexPaths];
    }

    if ([_deselectingIndexPaths count] > 0) {
        NSArray *indexPaths = _deselectingIndexPaths;
        _deselectingIndexPaths = nil;
        [self.dispatcher tableView:self didSelectRowsAtIndexPaths:indexPaths];
    }

    for (NSView *cell in [self visibleCells]) {
        [[cell superview] setNeedsDisplay:YES];
    }
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    [self rehash];
    if (self.edgeInsets.bottom > 0) {
        if (row == [tableView numberOfRows] - 1) {
            return [NSTableRowView new];
        }
    }
    if (self.edgeInsets.top > 0) {
        if (row == 0) {
            return [NSTableRowView new];
        }
        row--;
    }

    if ([self isHeaderRowIndex:row]) {
        return [NSTableRowView new];
    }
    else {
        NSIndexPath *ip = [self indexPathForRowIndex:row];
        return [self.dispatcher tableView:self rowViewForRowAtIndexPath:ip];
    }
}




#pragma mark - Private

- (void)rehash
{
    self.sections = nil;
    [self sections];
}

- (NSArray *)sections
{
    if (!_sections) {
        NSMutableArray *sections = [NSMutableArray new];
        for (NSUInteger i = 0; i < [self.dispatcher numberOfSectionsInTableView:self]; i++) {
            MYSTableViewSection *section    = [MYSTableViewSection new];
            section.tableView               = self;
            section.rowCount                = [self.dispatcher tableView:self numberOfRowsInSection:i];
            section.hasHeader               = [self.dispatcher tableView:self hasHeaderInSection:i];
            [sections addObject:section];
        }
        self.sections = sections;
    }
    return _sections;
}

- (NSInteger)sectionIndexForRowIndex:(NSUInteger)row
{
    __block NSUInteger currentRow = 0;
    __block NSInteger index = 0;
    [self.sections enumerateObjectsUsingBlock:^(MYSTableViewSection *section, NSUInteger idx, BOOL *stop) {
        currentRow += [section totalRows];
        if (row < currentRow) {
            index = idx;
            *stop = YES;
        }
    }];
    return index;
}

- (NSArray *)indexPathsForRowIndexes:(NSIndexSet *)indexSet
{
    NSMutableArray *indexPaths = [NSMutableArray new];
    [[self shiftedRowIndexes:indexSet] enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        if (idx < [self shiftedNumberOfRows]) {
            NSIndexPath *ip = [self indexPathForRowIndex:idx];
            if (ip) [indexPaths addObject:ip];
        }
    }];
    return indexPaths;
}

- (NSIndexSet *)rowIndexesForIndexPaths:(NSArray *)indexPaths
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
    for (NSIndexPath *ip in indexPaths) {
        if (ip.section < [self numberOfSections] && ip.row <= [self numberOfRowsInSection:ip.section]) {
            NSInteger rowIndex = [self rowIndexForIndexPath:ip];
            [indexSet addIndex:rowIndex];
        }
    }
    return [self unshiftedRowIndexes:indexSet];
}

- (NSIndexSet *)rowIndexesInSections:(NSIndexSet *)sections includeHeaders:(BOOL)includeHeaders
{
    NSMutableIndexSet *rowIndexes = [NSMutableIndexSet new];
    __block NSInteger rowSum = 0;
    [self.sections enumerateObjectsUsingBlock:^(MYSTableViewSection *section, NSUInteger idx, BOOL *stop) {
        if ([sections containsIndex:idx]) {
            for (NSInteger i = rowSum; i < rowSum + [section totalRows]; i++) {
                if (!includeHeaders && section.hasHeader && i == rowSum) {
                    continue;
                }
                [rowIndexes addIndex:i];
            }
        }
        rowSum += [section totalRows];
    }];
    return [self unshiftedRowIndexes:rowIndexes];
}

- (BOOL)isHeaderRowIndex:(NSInteger)rowIndex
{
    NSIndexPath *ip = [self indexPathForRowIndex:rowIndex];
    return ip == nil;
}

- (BOOL)hasValideIndexPathForRow:(NSInteger)rowIndex
{
    if (rowIndex < 0) return YES;
    NSInteger currentSectionIndex   = 0;
    NSInteger currentRowIndex       = rowIndex;
    for (MYSTableViewSection *section in self.sections) {
        NSInteger numberOfRowsInSection = [section totalRows];
        if (section.hasHeader && currentRowIndex == 0) {
            return YES;
        }
        else if (currentRowIndex < numberOfRowsInSection) {
            return YES;
        }
        currentRowIndex -= numberOfRowsInSection;
        currentSectionIndex++;
    }
    return NO;
}

- (void)beginInternalUpdates
{
    if (!self.updatesBeganExternally) {
        [CATransaction begin];
        [super beginUpdates];
    }
}

- (void)endInternalUpdates
{
    if (!self.updatesBeganExternally) [self endUpdates];
}


#pragma mark (row inset shifting)

- (NSInteger)shiftedNumberOfRows
{
    NSInteger count = [self numberOfRows];
    if (self.edgeInsets.top > 0) count--;
    if (self.edgeInsets.bottom > 0) count--;
    return count;
}

- (NSInteger)shiftedRow:(NSInteger)row
{
    if (self.edgeInsets.top > 0) {
        row++;
    }
    return row;
}

- (NSIndexSet *)shiftedRowIndexes:(NSIndexSet *)rowIndexes
{
    if (self.edgeInsets.top > 0) {
        NSMutableIndexSet *newRowIndexes = [NSMutableIndexSet new];
        [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [newRowIndexes addIndex:idx + 1];
        }];
        return newRowIndexes;
    }
    else {
        return rowIndexes;
    }
}

- (NSInteger)unshiftedRow:(NSInteger)row
{
    if (self.edgeInsets.top > 0) {
        row--;
    }
    return row;
}

- (NSIndexSet *)unshiftedRowIndexes:(NSIndexSet *)rowIndexes
{
    if (self.edgeInsets.top > 0) {
        NSMutableIndexSet *newRowIndexes = [NSMutableIndexSet new];
        [rowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [newRowIndexes addIndex:idx - 1];
        }];
        return newRowIndexes;
    }
    else {
        return rowIndexes;
    }
}

- (NSInteger)numberOfContentRows
{
    NSInteger numberOfRows = 0;
    for (MYSTableViewSection *section in self.sections) {
        numberOfRows += [section totalRows];
    }
    return numberOfRows;
}

@end





@implementation MYSTableViewSection

- (NSUInteger)totalRows
{
    return self.rowCount + (self.hasHeader ? 1 : 0);
}

- (NSView *)headerView
{
    if (!_headerView) {
        NSInteger sectionIndex = [self.tableView.sections indexOfObject:self];
        _headerView = [self.tableView.dispatcher tableView:self.tableView viewForHeaderInSection:sectionIndex];
    }
    return _headerView;
}

@end






#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"

@implementation MYSTableViewDispatcher

- (id)init
{
    self = [super init];
    if (self) {
        _dataSourceStub = [MYSTableViewDataSourceStub new];
        _delegateStub   = [MYSTableViewDelegateStub new];
    }
    return self;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([self.tableView.MYS_dataSource respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:self.tableView.MYS_dataSource];
    }
    else if ([self.tableView.MYS_delegate respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:self.tableView.MYS_delegate];
    }
    else if ([self.dataSourceStub respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:self.dataSourceStub];
    }
    else if ([self.delegateStub respondsToSelector:[anInvocation selector]]) {
        [anInvocation invokeWithTarget:self.delegateStub];
    }
    else
        [super forwardInvocation:anInvocation];
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return ([self.tableView.MYS_dataSource respondsToSelector:aSelector] ||
            [self.tableView.MYS_delegate respondsToSelector:aSelector] ||
            [self.dataSourceStub respondsToSelector:aSelector] ||
            [self.delegateStub respondsToSelector:aSelector] ||
            [super respondsToSelector:aSelector]);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *signature = [(NSObject *)self.tableView.MYS_dataSource methodSignatureForSelector:aSelector];
    if (signature) {
        return signature;
    }

    signature = [(NSObject *)self.tableView.MYS_delegate methodSignatureForSelector:aSelector];
    if (signature) {
        return signature;
    }

    signature = [self.dataSourceStub methodSignatureForSelector:aSelector];
    if (signature) {
        return signature;
    }

    signature = [self.delegateStub methodSignatureForSelector:aSelector];
    if (signature) {
        return signature;
    }

    signature = [super methodSignatureForSelector:aSelector];
    if (signature) {
        return signature;
    }

    return nil;
}

@end

#pragma clang diagnostic pop




@implementation MYSTableViewDataSourceStub

- (NSInteger)numberOfSectionsInTableView:(MYSTableView *)tableView { return 1; }

- (NSInteger)tableView:(MYSTableView *)tableView numberOfRowsInSection:(NSInteger)section { return 0; }

- (NSView *)tableView:(MYSTableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath { return nil; }

- (NSString *)tableView:(MYSTableView *)tableView titleForHeaderInSection:(NSInteger)section { return nil; }

@end


@implementation MYSTableViewDelegateStub

- (void)tableView:(MYSTableView *)tableView willDisplayCell:(NSView *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {}

- (void)tableView:(MYSTableView *)tableView willDisplayHeaderView:(NSView *)view forSection:(NSInteger)section {}

- (void)tableView:(MYSTableView *)tableView didEndDisplayingCell:(NSView *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {}

- (void)tableView:(MYSTableView *)tableView didEndDisplayingHeaderView:(NSView *)view forSection:(NSInteger)section {}

- (CGFloat)tableView:(MYSTableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath { return 44; }

- (CGFloat)tableView:(MYSTableView *)tableView heightForHeaderInSection:(NSInteger)section { return 20; }

- (BOOL)tableView:(MYSTableView *)tableView hasHeaderInSection:(NSInteger)section { return NO; }

- (NSView *)tableView:(MYSTableView *)tableView viewForHeaderInSection:(NSInteger)section { return nil; }

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRowAtIndexPath:(NSIndexPath *)indexPath { return  nil; }

- (BOOL)tableView:(MYSTableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath { return YES; }

- (void)tableView:(MYSTableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath {}

- (void)tableView:(MYSTableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath {}

- (NSArray *)tableView:(MYSTableView *)tableView willSelectRowsAtIndexPaths:(NSArray *)indexPaths { return indexPaths; }

- (NSArray *)tableView:(MYSTableView *)tableView willDeselectRowsAtIndexPaths:(NSArray *)indexPaths { return indexPaths; }

- (void)tableView:(MYSTableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {}

- (void)tableView:(MYSTableView *)tableView didSelectRowsAtIndexPaths:(NSArray *)indexPath {}

- (void)tableView:(MYSTableView *)tableView didDeselectRowsAtIndexPaths:(NSArray *)indexPath {}

- (void)tableView:(MYSTableView *)tableView didPressEnterOnRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event {}

- (void)tableView:(MYSTableView *)tableView didClickRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event {}

- (void)tableView:(MYSTableView *)tableView didRightClickOnRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event {}

- (NSMenu *)tableView:(MYSTableView *)tableView menuForRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event { return nil; }

@end



@implementation MYSScrollViewAnimation

+ (void)animatedScrollPointToCenter:(NSPoint)targetPoint inScrollView:(NSScrollView *)scrollView duration:(NSTimeInterval)duration
{
    NSRect visibleRect = scrollView.documentVisibleRect;
    targetPoint = NSMakePoint(targetPoint.x - (NSWidth(visibleRect) / 2), targetPoint.y - (NSHeight(visibleRect) / 2));
    [self animatedScrollToPoint:targetPoint inScrollView:scrollView duration:duration];
}

+ (void)animatedScrollToPoint:(NSPoint)targetPoint inScrollView:(NSScrollView *)scrollView duration:(NSTimeInterval)duration
{
    MYSScrollViewAnimation *animation = [[MYSScrollViewAnimation alloc] initWithDuration:duration
                                                                          animationCurve:NSAnimationEaseInOut];
    animation.scrollView = scrollView;
    animation.originPoint = scrollView.documentVisibleRect.origin;
    animation.targetPoint = targetPoint;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [animation startAnimation];
    });
}

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
    typedef float (^MyAnimationCurveBlock)(float, float, float);
    MyAnimationCurveBlock cubicEaseInOut = ^ float (float t, float start, float end) {
        t *= 2.;
        if (t < 1.) return end/2 * t * t * t + start - 1.f;
        t -= 2;
        return end/2*(t * t * t + 2) + start - 1.f;
    };

    dispatch_sync(dispatch_get_main_queue(), ^{

        NSPoint progressPoint = self.originPoint;
        progressPoint.x += cubicEaseInOut(progress, 0, self.targetPoint.x - self.originPoint.x);
        progressPoint.y += cubicEaseInOut(progress, 0, self.targetPoint.y - self.originPoint.y);

        [self.scrollView.documentView scrollPoint:progressPoint];
        [self.scrollView displayIfNeeded];
    });
}



@end

