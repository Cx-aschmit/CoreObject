/*
	Copyright (C) 2013 Eric Wasylishen

	Author:  Eric Wasylishen <ewasylishen@gmail.com>
	Date:  August 2013
	License:  MIT  (see COPYING)
 */

#import <Foundation/Foundation.h>

@class COUndoTrack;
@class FMDatabase;
@class ETUUID;

extern NSString * const kCOUndoStack;
extern NSString * const kCORedoStack;

/**
 * Simple persistent store of named pairs of stacks of NSDictionary (undo and redo stacks).
 * The NSDictionary's are property list representations of COCommand objects
 */
@interface COUndoStackStore : NSObject
{
    FMDatabase *_db;
}

+ (COUndoStackStore *) defaultStore;

/** @taskunit Framework Private */

- (NSSet *) stackNames;

- (BOOL) beginTransaction;
- (BOOL) commitTransaction;

- (NSArray *) stackContents: (NSString *)aTable forName: (NSString *)aStack;
- (void) clearStack: (NSString *)aTable forName: (NSString *)aStack;
- (void) clearStacksForName: (NSString *)aStack;

- (void) popStack: (NSString *)aTable forName: (NSString *)aStack;
- (NSDictionary *) peekStack: (NSString *)aTable forName: (NSString *)aStack;
- (NSString *) peekStackName: (NSString *)aTable forName: (NSString *)aStack;
- (void) pushAction: (NSDictionary *)anAction stack: (NSString *)aTable forName: (NSString *)aStack;
- (void) popActionWithUUID: (ETUUID *)aUUID stack: (NSString *)aTable forName: (NSString *)aStack;
- (NSString *) peekStackName: (NSString *)aTable forActionWithUUID: (ETUUID *)aUUID forName: (NSString *)aStack;

@end
