/*
    Copyright (C) 2013 Eric Wasylishen

    Author:  Eric Wasylishen <ewasylishen@gmail.com>, 
             Quentin Mathe <quentin.mathe@gmail.com>
    Date:  September 2013
    License:  MIT  (see COPYING)
 */

#import "COCommandSetBranchMetadata.h"

#import "COEditingContext.h"
#import "COPersistentRoot.h"
#import "COBranch.h"

static NSString * const kCOCommandBranchUUID = @"COCommandBranchUUID";
static NSString * const kCOCommandOldMetadata = @"COCommandOldMetadata";
static NSString * const kCOCommandNewMetadata = @"COCommandNewMetadata";

@implementation COCommandSetBranchMetadata 

@synthesize branchUUID = _branchUUID;
@synthesize oldMetadata = _oldMetadata;
@synthesize metadata = _newMetadata;

- (id) initWithPropertyList: (id)plist
{
    self = [super initWithPropertyList: plist];
    self.branchUUID = [ETUUID UUIDWithString: [plist objectForKey: kCOCommandBranchUUID]];
    self.oldMetadata = [plist objectForKey: kCOCommandOldMetadata];
    self.metadata = [plist objectForKey: kCOCommandNewMetadata];
    return self;
}

- (id) propertyList
{
    NSMutableDictionary *result = [super propertyList];
    [result setObject: [_branchUUID stringValue] forKey: kCOCommandBranchUUID];
    if (_oldMetadata != nil)
    {
        [result setObject: _oldMetadata forKey: kCOCommandOldMetadata];
    }
    if (_newMetadata != nil)
    {
        [result setObject: _newMetadata forKey: kCOCommandNewMetadata];
    }
    return result;
}

- (COCommand *) inverse
{
    COCommandSetBranchMetadata *inverse = [[COCommandSetBranchMetadata alloc] init];
    inverse.storeUUID = _storeUUID;
    inverse.persistentRootUUID = _persistentRootUUID;
    
    inverse.branchUUID = _branchUUID;
    inverse.oldMetadata = _newMetadata;
    inverse.metadata = _oldMetadata;
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

    [branch setMetadata: _newMetadata];
}

- (NSString *)kind
{
	return _(@"Branch Metadata Update");
}

@end
