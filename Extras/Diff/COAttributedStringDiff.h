/*
	Copyright (C) 2013 Eric Wasylishen
 
	Date:  December 2013
	License:  MIT  (see COPYING)
 */

#import <CoreObject/CoreObject.h>
#import "COAttributedString.h"
#import "COAttributedStringChunk.h"
#import "COAttributedStringAttribute.h"

/**
 * TODO: Don't use COAttributedString directly but work on the item representation (?)
 *
 * FIXME: One problem is, item graph A + diff(item graph A, item graph B) will
 * not given exactly item graph B. The chunk / attribute UUIDs will be different.
 */
@interface COAttributedStringDiff : NSObject <CODiffAlgorithm>
{
	NSMutableArray *_operations;
}

@property (nonatomic, readonly) NSMutableArray *operations;

- (id) initWithFirstAttributedString: (COAttributedString *)first
              secondAttributedString: (COAttributedString *)second
							  source: (id)source;

- (void) addOperationsFromDiff: (COAttributedStringDiff *)aDiff;

- (void) applyToAttributedString: (COAttributedString *)target;

/* @taskunit CODiffAlgorithm Protocol */

+ (instancetype) diffItemUUIDs: (NSArray *)uuids
					 fromGraph: (id <COItemGraph>)a
					   toGraph: (id <COItemGraph>)b
			  sourceIdentifier: (id)aSource;

- (id<CODiffAlgorithm>) itemTreeDiffByMergingWithDiff: (id<CODiffAlgorithm>)aDiff;

@end

@protocol COAttributedStringDiffOperation <NSObject>
@required
@property (nonatomic, readwrite, strong) ETUUID *attributedStringUUID;
@property (nonatomic, readwrite, assign) NSRange range;
@property (nonatomic, readwrite, strong) id source;
/**
 * Apply the operation.
 * Returns the number of characters added (if positive) or removed (if negative)
 * from the string.
 */
- (NSInteger) applyOperationToAttributedString: (COAttributedString *)target withOffset: (NSInteger)offset;
@end

@interface COAttributedStringDiffOperationInsertAttributedSubstring : NSObject <COAttributedStringDiffOperation>
@property (nonatomic, readwrite, strong) COItemGraph *attributedStringItemGraph;
@end

@interface COAttributedStringDiffOperationDeleteRange : NSObject <COAttributedStringDiffOperation>
@end

@interface COAttributedStringDiffOperationReplaceRange : NSObject <COAttributedStringDiffOperation>
@property (nonatomic, readwrite, strong) COItemGraph *attributedStringItemGraph;
@end

@interface COAttributedStringDiffOperationAddAttribute : NSObject <COAttributedStringDiffOperation>
@property (nonatomic, readwrite, strong) COItemGraph *attributeItemGraph;
@end

@interface COAttributedStringDiffOperationRemoveAttribute : NSObject <COAttributedStringDiffOperation>
@property (nonatomic, readwrite, strong) COItemGraph *attributeItemGraph;
@end
