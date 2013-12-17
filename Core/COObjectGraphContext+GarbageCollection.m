/*
	Copyright (C) 2013 Eric Wasylishen, Quentin Mathe

	Date:  October 2013
	License:  MIT  (see COPYING)

 */

#import "COObjectGraphContext+GarbageCollection.h"
#import "COObject.h"

@implementation COObjectGraphContext (COGarbageCollection)

/**
 * Given a COObject, returns an array of all of the COObjects directly reachable
 * from that COObject.
 */
static NSArray *DirectlyReachableObjectsFromObject(COObject *anObject, COObjectGraphContext *restrictToObjectGraph)
{
	NSMutableArray *result = [NSMutableArray array];
	for (ETPropertyDescription *propDesc in [[anObject entityDescription] allPropertyDescriptions])
	{
		if (![propDesc isPersistent])
		{
			continue;
		}
		
		NSString *propertyName = [propDesc name];
		id value = [anObject valueForKey: propertyName];
        
        if ([propDesc isMultivalued])
        {
			if ([propDesc isKeyed])
			{
				assert([value isKindOfClass: [NSDictionary class]]);
			}
			else
			{
				assert([value isKindOfClass: [NSArray class]] || [value isKindOfClass: [NSSet class]]);
				
			}
			
			/* We use -objectEnumerator, because subvalue can be a  CODictionary
			 or a NSDictionary (if a getter exists to expose the CODictionary
			 as a NSDictionary for UI editing) */
            for (id subvalue in [value objectEnumerator])
            {
                if ([subvalue isKindOfClass: [COObject class]]
					&& [subvalue objectGraphContext] == restrictToObjectGraph)
                {
                    [result addObject: subvalue];
                }
            }
        }
        else
        {
            if ([value isKindOfClass: [COObject class]]
				&& [value objectGraphContext] == restrictToObjectGraph)
            {
                [result addObject: value];
            }
            // Ignore non-COObject objects
        }
	}
	return result;
}

static void FindReachableObjectsFromObject(COObject *anObject, NSMutableSet *collectedUUIDSet, COObjectGraphContext *restrictToObjectGraph)
{
    ETUUID *uuid = [anObject UUID];
    if ([collectedUUIDSet containsObject: uuid])
    {
        return;
    }
    [collectedUUIDSet addObject: uuid];
    
    // Call recursively on all composite and referenced objects
    for (COObject *obj in DirectlyReachableObjectsFromObject(anObject, restrictToObjectGraph))
    {
        FindReachableObjectsFromObject(obj, collectedUUIDSet, restrictToObjectGraph);
    }
}

- (NSSet *) allReachableObjectUUIDs
{
	NSParameterAssert([self rootObject] != nil);
	
	NSMutableSet *result = [[NSMutableSet alloc] initWithCapacity: [_loadedObjects count]];
	FindReachableObjectsFromObject([self rootObject], result, self);
	return result;
}

#pragma mark - cycle detection

/**
 * Given a COObject, returns an array of all of the COObjects directly reachable
 * from that COObject.
 */
static NSArray *CompositeReachableObjectsFromObject(COObject *anObject)
{
	NSMutableArray *result = [NSMutableArray array];
	for (ETPropertyDescription *propDesc in [[anObject entityDescription] allPropertyDescriptions])
	{
		if (!([propDesc isPersistent] && [propDesc isComposite]))
			continue;
		
		NSString *propertyName = [propDesc name];
		id value = [anObject valueForKey: propertyName];
        
        if ([propDesc isMultivalued])
        {
			/* We use -objectEnumerator, because subvalue can be a  CODictionary
			 or a NSDictionary (if a getter exists to expose the CODictionary
			 as a NSDictionary for UI editing) */
            for (id subvalue in [value objectEnumerator])
            {
				[result addObject: subvalue];
            }
        }
        else
        {
			[result addObject: value];
		}
	}
	return result;
}

static void FindCyclesInCompositeRelationshipsFromObject(COObject *anObject, NSMutableSet *collectedUUIDSet)
{
    ETUUID *uuid = [anObject UUID];
    if ([collectedUUIDSet containsObject: uuid])
    {
        [NSException raise: NSGenericException format: @"Cycle detected"];
    }
    [collectedUUIDSet addObject: uuid];
    
    // Call recursively on all composite and referenced objects
    for (COObject *obj in CompositeReachableObjectsFromObject(anObject))
    {
        FindCyclesInCompositeRelationshipsFromObject(obj, collectedUUIDSet);
    }
}

- (void) checkForCyclesInCompositeRelationshipsFromObject: (COObject*)anObject
{
	NSMutableSet *result = [[NSMutableSet alloc] initWithCapacity: [_loadedObjects count]];
	FindCyclesInCompositeRelationshipsFromObject(anObject, result);
}

@end
