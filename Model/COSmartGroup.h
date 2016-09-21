/**
	Copyright (C) 2010 Eric Wasylishen, Quentin Mathe

	Date:  November 2010
	License:  MIT  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/EtoileFoundation.h>
#import <CoreObject/COCollection.h>

typedef NSArray *(^COContentBlock)(void);

/**
 * @group Object Collection and Organization
 * @abstract A custom group class whose content is provided a query or a code 
 * block.
 *
 * COSmartGroup is an immutable, ordered, weak (an object can be in any number 
 * of collections) collection class.
 *
 * Because it is an immutable collection, it isn't a COCollection subclass.
 */
@interface COSmartGroup : COObject <ETCollection>
{
	@private
	id <ETCollection> targetCollection;
	COQuery *query;
	COContentBlock contentBlock;
	NSArray *content;
}


/** @taskunit Controlling the Content */


/**
 * The target collection used to compute the smart group content.
 *
 * If a content block is provided, the target collection is not used.
 *
 * If a query is provided at the same time and the target collection supports 
 * COObjectMatching protocol, then -objectsMatchingQuery: provides the smart 
 * group content, otherwise the target collection is filtered as an array using 
 * the query predicate.
 *
 * If no content block or query are set, the target collection is used as is as 
 * the smart group content.
 *
 * See -query and -contentBlock.
 */
@property (nonatomic, readwrite, strong) id <ETCollection> targetCollection;
/**
 * The query used to compute the smart group content.
 *
 * If a content block is provided, the query is not used.
 *
 * If no target collection is set, the query is evaluated directly against the 
 * store (e.g. as a SQL query) rather than again the object graph in memory.
 *
 * If a target collection is provided, see -targetCollection to know how the 
 * query is evaluated.
 *
 * See -targetCollection and -contentBlock.
 */
@property (nonatomic, readwrite, strong) COQuery *query;
/**
 * The content block used to compute the smart group content.
 *
 * If a content block is set, both the target collection and query are not used.
 *
 * See -targetCollection and -query.
 */
@property (nonatomic, readwrite, copy) COContentBlock contentBlock;


/** @taskunit Accessing the Content */


/**
 * Returns the last computed smart group content.
 *
 * See -[ETCollection content].
 */
@property (nonatomic, readonly, strong) id content;


/** @taskunit Updating */


/**
 * Forces the receiver content to be recreated by evaluating the query or 
 * content block.
 *
 * See also -query and -contentBlock.
 */
- (void)refresh;


/** @taskunit Object Matching */


/**
 * Returns the first object whose identifier matches.
 *
 * The search is shallow, in other words limited to the objects in the receiver 
 * content.
 *
 * See -[COObject identifier].
 */
- (id)objectForIdentifier: (NSString *)anId;
/**
 * See -[COObjectMatching objectsMatchingQuery:].
 *
 * Object graph traversal implementation for COObjectMatching protocol.
 */
- (NSArray *)objectsMatchingQuery: (COQuery *)aQuery;

@end
