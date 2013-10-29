#import "COCommandUndeletePersistentRoot.h"
#import "COCommandDeletePersistentRoot.h"

#import "COEditingContext.h"
#import "COPersistentRoot.h"
#import "COBranch.h"

static NSString * const kCOCommandInitialRevisionID = @"COCommandInitialRevisionID";

@implementation COCommandDeletePersistentRoot

- (id) initWithPropertyList: (id)plist
{
    self = [super initWithPropertyList: plist];
	if (self == nil)
		return nil;

	id serializedRevID = plist[kCOCommandInitialRevisionID];

	if (serializedRevID != nil)
	{
   		_initialRevisionID = [ETUUID UUIDWithString: serializedRevID];
	}
    return self;
}

- (id) propertyList
{
    NSMutableDictionary *result = [super propertyList];

	if (_initialRevisionID != nil)
	{
    	[result setObject: [_initialRevisionID stringValue] forKey: kCOCommandInitialRevisionID];
	}
    return result;
}

- (COCommand *) inverse
{
	Class inverseClass = [COCommandUndeletePersistentRoot class];
	BOOL isCreateInverse = (_initialRevisionID != nil);

	if (isCreateInverse)
	{
		inverseClass = [COCommandCreatePersistentRoot class];
	}

    COCommandUndeletePersistentRoot *inverse = [[inverseClass alloc] init];
    inverse.storeUUID = _storeUUID;
    inverse.persistentRootUUID = _persistentRootUUID;

	if (isCreateInverse)
	{
		[(COCommandCreatePersistentRoot *)inverse setInitialRevisionID: _initialRevisionID];
	}

    return inverse;
}

- (BOOL) canApplyToContext: (COEditingContext *)aContext
{
	NILARG_EXCEPTION_TEST(aContext);
    if (nil == [aContext persistentRootForUUID: _persistentRootUUID])
    {
        return NO;
    }
    return YES;
}

- (void) applyToContext: (COEditingContext *)aContext
{
	NILARG_EXCEPTION_TEST(aContext);
    [[aContext persistentRootForUUID: _persistentRootUUID] setDeleted: YES];
}

- (NSString *)kind
{
	return _(@"Persistent Root Deletion");
}


@end
