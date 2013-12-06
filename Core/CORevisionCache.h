/*
	Copyright (C) 2013 Eric Wasylishen

	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  September 2013
	License:  Modified BSD  (see COPYING)
 */

#import <Foundation/Foundation.h>
#import <EtoileFoundation/ETUUID.h>

@class COSQLiteStore, CORevision;


@interface CORevisionCache : NSObject
{
	@private
    COSQLiteStore *_store;
    NSMutableDictionary *_revisionForRevisionID;
}

/** @taskunit Revision Access */

/**
 * Look up the requested revision in the cache. Returns nil if the revision is
 * not found.
 */
+ (CORevision *) revisionForRevisionUUID: (ETUUID *)aRevid
					  persistentRootUUID: (ETUUID *)aPersistentRoot
							   storeUUID: (ETUUID *)aStoreUUID;

/** @taskunit Subclassing */


- (id) initWithStore: (COSQLiteStore *)aStore;
- (CORevision *) revisionForRevisionUUID: (ETUUID *)aRevid
					  persistentRootUUID: (ETUUID *)aPersistentRoot;

@property (nonatomic, readonly, strong) COSQLiteStore *store;


/** @taskunit Framework Private */

+ (void) prepareCacheForStore: (COSQLiteStore *)aStore;
// TODO: Don't expose. It is a cache implementation detail.
+ (id)cacheForStoreUUID: (ETUUID *)aUUID;

@end
