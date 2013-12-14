/*
	Copyright (C) 2013 Eric Wasylishen

	Author:  Eric Wasylishen <ewasylishen@gmail.com>, 
	         Quentin Mathe <quentin.mathe@gmail.com>
	Date:  September 2013
	License:  MIT  (see COPYING)
 */

#import "COCommandUndeleteBranch.h"
#import "COCommandDeleteBranch.h"

#import "COEditingContext.h"
#import "COPersistentRoot.h"
#import "COBranch.h"

static NSString * const kCOCommandBranchUUID = @"COCommandBranchUUID";

@implementation COCommandUndeleteBranch

@synthesize branchUUID = _branchUUID;

- (id) initWithPropertyList: (id)plist
{
    self = [super initWithPropertyList: plist];
    self.branchUUID = [ETUUID UUIDWithString: [plist objectForKey: kCOCommandBranchUUID]];
    return self;
}

- (id) propertyList
{
    NSMutableDictionary *result = [super propertyList];
    [result setObject: [_branchUUID stringValue] forKey: kCOCommandBranchUUID];
    return result;
}

- (COCommand *) inverse
{
    COCommandDeleteBranch *inverse = [[COCommandDeleteBranch alloc] init];
    inverse.storeUUID = _storeUUID;
    inverse.persistentRootUUID = _persistentRootUUID;
    
    inverse.branchUUID = _branchUUID;
    return inverse;
}

- (BOOL) canApplyToContext: (COEditingContext *)aContext
{
	NILARG_EXCEPTION_TEST(aContext);
    return YES;
}

- (void) applyToContext: (COEditingContext *)aContext
{
	NILARG_EXCEPTION_TEST(aContext);

    COPersistentRoot *proot = [aContext persistentRootForUUID: _persistentRootUUID];
    COBranch *branch = [proot branchForUUID: _branchUUID];
	ETAssert(branch != nil);
    
    [branch setDeleted: NO];
}

- (NSString *)kind
{
	return _(@"Branch Undeletion");
}

@end
