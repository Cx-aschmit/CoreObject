#import "TestCommon.h"

@interface TestAttributedStringCommon : TestCase

- (COAttributedStringAttribute *) makeAttr: (NSString *)htmlCode inCtx: (COObjectGraphContext *)ctx;

- (COObjectGraphContext *) makeAttributedString;

- (void) appendString: (NSString *)string htmlCode: (NSString *)aCode toAttributedString: (COAttributedString *)dest;

@end