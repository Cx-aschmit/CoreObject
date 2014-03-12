/*
	Copyright (C) 2014 Eric Wasylishen
 
	Date:  February 2014
	License:  MIT  (see COPYING)
 */

#import <Cocoa/Cocoa.h>
#import "EWTypewriterWindowController.h"
#import "EWDocument.h"
#import "EWAppDelegate.h"
#import "TypewriterDocument.h"
#import "EWTagListDataSource.h"
#import "EWNoteListDataSource.h"
#import "PrioritySplitViewDelegate.h"
#import "EWHistoryWindowController.h"

@implementation EWTypewriterWindowController

/**
 * Pasteboard item property list is an NSString persistent root UUID
 */
NSString * EWNoteDragType = @"org.etoile.Typewriter.Note";
NSString * EWTagDragType = @"org.etoile.Typewriter.Tag";

#pragma mark - properties

@synthesize notesTable = notesTable;
@synthesize undoTrack = undoTrack;
@synthesize textStorage = textStorage;

- (COEditingContext *) editingContext
{
	return [(EWDocument *)[self document] editingContext];
}

- (NSArray *) arrangedNotePersistentRoots
{
	NSMutableArray *results = [NSMutableArray new];
	
	NSSet *set = [self.editingContext.persistentRoots filteredSetUsingPredicate:
				  [NSPredicate predicateWithBlock: ^(id object, NSDictionary *bindings) {
					COPersistentRoot *persistentRoot = object;
					return [[persistentRoot rootObject] isKindOfClass: [TypewriterDocument class]];
				  }]];
	
	[results setArray: [set allObjects]];
	[results sortUsingDescriptors: @[[NSSortDescriptor sortDescriptorWithKey: @"modificationDate" ascending: NO]]];
	
	// Filter by tag
	
	COTagGroup *selectedTagGroup = [self tagGroupOfSelectedRow];
	COTag *selectedTag = [self selectedTag];
	
	[results filterUsingPredicate:
	 [NSPredicate predicateWithBlock: ^(id object, NSDictionary *bindings) {
		COObject *rootObject = [object rootObject];
		if (selectedTag == nil)
		{
			if (selectedTagGroup == nil)
				return YES;
			else
			{
				for (COTag *tagOfObject in [rootObject tags])
				{
					if ([[selectedTagGroup content] containsObject: tagOfObject])
						return YES;
				}
				return NO;
			}
		}
		else
		{
			NSArray *tagContents = [selectedTag content];
			return [tagContents containsObject: rootObject];
		}
	}]];
	
	// Filter by search query
	// Very slow
	
	NSString *searchQuery = [searchfield stringValue];
	[results filterUsingPredicate:
	 [NSPredicate predicateWithBlock: ^(id object, NSDictionary *bindings) {
		if ([searchQuery length] == 0)
		{
			return YES;
		}
		else
		{
			TypewriterDocument *doc = [object rootObject];
			COAttributedStringWrapper *as = [[COAttributedStringWrapper alloc] initWithBacking: doc.attrString];
			NSString *docString = [as string];
			
			NSRange range = [docString rangeOfString: searchQuery];
			return (BOOL)(range.location != NSNotFound);
		}
	}]];
	
	return results;
}

- (NSArray *) selectedNotePersistentRoots
{
	NSInteger selectedRow = [notesTable clickedRow];
	if (selectedRow == -1)
		selectedRow = [notesTable selectedRow];
	
	if (selectedRow == -1)
		return @[];
	
	return @[[[self arrangedNotePersistentRoots] objectAtIndex: selectedRow]];
}

- (NSTreeNode *) tagsOutlineClickedOrSelectedTreeNode
{
	NSInteger selectedRow = [tagsOutline clickedRow];
	if (selectedRow == -1)
		selectedRow = [tagsOutline selectedRow];
	
	if (selectedRow == -1)
		return nil;
	
	NSTreeNode *node = [tagsOutline itemAtRow: selectedRow];
	return node;
}

- (COTag *) clickedOrSelectedTag
{
	NSTreeNode * object = [self tagsOutlineClickedOrSelectedTreeNode];
	if ([[object representedObject] isTag])
	{
		return [object representedObject];
	}
	return nil;
}

- (NSTreeNode *) tagsOutlineSelectedTreeNode
{
	NSInteger selectedRow = [tagsOutline selectedRow];
	
	if (selectedRow == -1)
		return nil;
	
	NSTreeNode *node = [tagsOutline itemAtRow: selectedRow];
	return node;
}


- (COTag *) selectedTag
{
	NSTreeNode * object = [self tagsOutlineSelectedTreeNode];
	if ([[object representedObject] isTag])
	{
		return [object representedObject];
	}
	return nil;
}

- (COTagGroup *) tagGroupOfSelectedRow
{
	NSTreeNode * object = [self tagsOutlineClickedOrSelectedTreeNode];
	if ([[object representedObject] isKindOfClass: [COTagGroup class]])
	{
		return [object representedObject];
	}
	else if ([[object representedObject] isKindOfClass: [COTag class]])
	{
		COTagGroup *tagGroup = [[object parentNode] representedObject];
		return tagGroup;
	}
	return nil;
}

- (void) dealloc
{
	[textStorage setDelegate: nil];
	[tagsOutline setDelegate: nil];
	[notesTable setDelegate: nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - NSWindowController overrides

- (void)windowDidLoad
{
	// Disable AppKit's automatic restoration; we implement our own in
	// -[EWAppDelegate applicationDidFinishLaunching:]
	[[self window] setRestorable: NO];
	
	undoManagerBridge = [[EWUndoManager alloc] init];
	[undoManagerBridge setDelegate: self];
	
	undoTrack = [COUndoTrack trackForName: @"typewriter" withEditingContext: self.editingContext];
	
	ETAssert(tagsOutline != nil);
	tagListDataSource = [EWTagListDataSource new];
	tagListDataSource.owner = self;
	tagListDataSource.outlineView = tagsOutline;
	[tagsOutline setDataSource: tagListDataSource];
	[tagsOutline setDelegate: tagListDataSource];
	[tagListDataSource cacheSelection];
	[tagListDataSource reloadData];

	ETAssert(notesTable != nil);
	noteListDataSource = [EWNoteListDataSource new];
	noteListDataSource.owner = self;
	noteListDataSource.tableView = notesTable;
	[notesTable setDataSource: noteListDataSource];
	[notesTable setDelegate: noteListDataSource];
	[noteListDataSource cacheSelection];
	
	// Drag & drop
	
	[tagsOutline registerForDraggedTypes: @[EWNoteDragType, EWTagDragType]];
	
	// Text view setup
	
	[textView setDelegate: self];
	
	// Set initial text view contents
	
	if ([[self selectedNotePersistentRoots] count] > 0)
	{
		[self selectNote: [self selectedNotePersistentRoots][0]];
	}
	else
	{
		[self selectNote: nil];
	}
	
	// Observe editing context changes
	
	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(editingContextChanged:)
												 name: COEditingContextDidChangeNotification
											   object: self.editingContext];
	
	// Setup split view resizing behaviour
	splitViewDelegate = [[PrioritySplitViewDelegate alloc] init];
	[splitViewDelegate setPriority: 2 forViewAtIndex: 0];
	[splitViewDelegate setPriority: 1 forViewAtIndex: 1];
	[splitViewDelegate setPriority: 0 forViewAtIndex: 2];
	[splitView setDelegate: splitViewDelegate];
}

#pragma mark - Notification methods

- (void) editingContextChanged: (NSNotification *)notif
{
	// TODO: Should check modified persistent root UUIDs and only update the
	// tags list if the project was modified, or the notes list if the project
	// or one of the notes was modified.
	[tagListDataSource reloadData];
	[noteListDataSource reloadData];
}

#pragma mark - IBActions

- (IBAction) addTag:(id)sender
{
	COTagGroup *targetTagGroup = [self tagGroupOfSelectedRow];
	if (targetTagGroup == nil)
		targetTagGroup = [self defaultTagGroup];
		
	COTag *newTag = [[COTag alloc] initWithObjectGraphContext: [[self tagLibrary] objectGraphContext]];
	newTag.name = @"New Tag";
	[targetTagGroup addObject: newTag];
	
	[self commitWithIdentifier: @"add-tag" descriptionArguments: @[]];
	[tagListDataSource setNextSelection: [[EWTagGroupTagPair alloc] initWithTagGroup: targetTagGroup.UUID tag:newTag.UUID]];
	[tagListDataSource reloadData];
}

- (IBAction) addTagGroup:(id)sender
{
	COTagGroup *newTagGroup = [[COTagGroup alloc] initWithObjectGraphContext: [[self tagLibrary] objectGraphContext]];
	newTagGroup.name = @"New Tag Group";
	[[[self tagLibrary] mutableArrayValueForKey: @"tagGroups"] addObject: newTagGroup];
	
	[self commitWithIdentifier: @"add-tag-group" descriptionArguments: @[]];
	[tagListDataSource setNextSelection: [[EWTagGroupTagPair alloc] initWithTagGroup: newTagGroup.UUID tag:nil]];
	[tagListDataSource reloadData];
}

- (IBAction) addNote:(id)sender
{
	COPersistentRoot *newNote = [self.editingContext insertNewPersistentRootWithEntityName: @"TypewriterDocument"];
	NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary: newNote.metadata];
	[md addEntriesFromDictionary: @{ @"label" : @"Untitled Note" }];
	newNote.metadata = md;
	
	COTag *currentTag = [self clickedOrSelectedTag];
	if (currentTag != nil)
	{
		[currentTag addObject: [newNote rootObject]];
	}
	
	[self commitWithIdentifier: @"add-note" descriptionArguments: @[]];
	[noteListDataSource setNextSelection: newNote.UUID];
	[noteListDataSource reloadData];
}

- (IBAction) duplicate:(id)sender
{
	if ([[self window] firstResponder] == notesTable)
	{
		NSArray *selections = [self selectedNotePersistentRoots];
		if ([selections count] == 0)
			return;
		
		COPersistentRoot *selectedPersistentRoot = selections[0];
		COPersistentRoot *copyOfSelection = [selectedPersistentRoot.currentBranch makePersistentRootCopy];

		NSString *sourceLabel = selectedPersistentRoot.metadata[@"label"];
		
		NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary: copyOfSelection.metadata];
		[md addEntriesFromDictionary: @{ @"label" : [NSString stringWithFormat: @"Copy of %@", sourceLabel] }];
		copyOfSelection.metadata = md;
		
		// Also give it the selected tag
		COTag *selectedTag = [self clickedOrSelectedTag];
		if (selectedTag != nil)
		{
			[selectedTag addObject: [copyOfSelection rootObject]];
		}
		
		[self commitWithIdentifier: @"duplicate-note" descriptionArguments: @[sourceLabel]];
		[noteListDataSource setNextSelection: copyOfSelection.UUID];
		[noteListDataSource reloadData];
	}
}

- (IBAction)showDocumentHistory:(id)sender
{
	NSArray *notes = [self selectedNotePersistentRoots];
	if ([notes count] == 1)
	{
		COPersistentRoot *note = notes[0];
		EWHistoryWindowController *historyWindow = [[EWHistoryWindowController alloc] initWithInspectedPersistentRoot: note undoTrack: undoTrack];
		[[self document] addWindowController: historyWindow];
		[historyWindow showWindow: nil];
	}
}

- (IBAction) removeTagFromNote:(id)sender
{
	NSArray *notes = [self selectedNotePersistentRoots];
	if ([notes count] == 1)
	{
		COPersistentRoot *note = notes[0];
		TypewriterDocument *noteRootObject = [note rootObject];
		
		COTag *tag = [(NSMenuItem *)sender representedObject];
		
		NSLog(@"remove %@ from %@", tag, note);
		
		ETAssert([tag containsObject: noteRootObject]);
		[tag removeObject: noteRootObject];
		
		[self commitWithIdentifier: @"untag-note" descriptionArguments: @[[tag name], note.metadata[@"label"]]];
	}
}

- (void)saveDocument:(id)sender
{
	NSArray *notes = [self selectedNotePersistentRoots];
	if ([notes count] == 1)
	{
		COPersistentRoot *note = notes[0];
		note.currentBranch.shouldMakeEmptyCommit = YES;
		[note commitWithIdentifier: @"org.etoile.CoreObject.checkpoint"
						  metadata: @{}
						 undoTrack: nil
							 error: NULL];
	}
}

#pragma mark - EWUndoManagerDelegate

- (void) undo
{
	[undoTrack undo];
}
- (void) redo
{
	[undoTrack redo];
}

- (BOOL) canUndo
{
	return [undoTrack canUndo];
}

- (BOOL) canRedo
{
	return [undoTrack canRedo];
}

- (NSString *) undoMenuItemTitle
{
	return [undoTrack undoMenuItemTitle];
}
- (NSString *) redoMenuItemTitle
{
	return [undoTrack redoMenuItemTitle];
}

#pragma mark - NSWindowDelegate

-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
	NSLog(@"asked for undo manager");
	return (NSUndoManager *)undoManagerBridge;
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	changedByUser = YES;
	
	NSLog(@"should add %@", replacementString);
	
	// These are just used to provide commit metadata
	
	if (affectedText == nil)
		affectedText = @"";
	
	if (replacementText == nil)
		replacementText = @"";
	
	// This is a complete hack (just append together the modified regions and replacement
	// text of possibly disjoint edits) but it produces commit descriptions that are usually helpful
	
	if (affectedCharRange.length > 0)
		affectedText = [affectedText stringByAppendingString:
						[[[aTextView textStorage] string] substringWithRange: affectedCharRange]];
	
	if ([replacementString length] > 0)
		replacementText = [replacementText stringByAppendingString: replacementString];
	
	return YES;
}

static const unichar ElipsisChar = 0x2026;

static NSString *Trim(NSString *text)
{
	if ([text length] > 30)
		return [[text substringToIndex: 30] stringByAppendingFormat: @"%C", ElipsisChar];
	
	text = [text stringByReplacingOccurrencesOfString: @"\n" withString: @""];
	
	return text;
}

#pragma mark - NSTextStorageDelegate

- (void)textStorageDidProcessEditing:(NSNotification *)notification
{
	NSString *editedText = [[textStorage string] substringWithRange: [textStorage editedRange]];
	
	NSLog(@"Text storage did process editing. %@ edited range: %@ = %@", notification.userInfo, NSStringFromRange([textStorage editedRange]), editedText);
	[textView setNeedsDisplay: YES];
	
	if (changedByUser)
	{
		changedByUser = NO;
	}
	else if ([selectedNote.objectGraphContext hasChanges])
	{
		NSLog(@"Processing editing with changes, but it wasn't the user's changes, ignoring");
		return;
	}
	
	if ([selectedNote.objectGraphContext hasChanges])
	{
		[self commitTextChangesAsCheckpoint: NO];
		
		if (coalescingTimer != nil)
		{
			[coalescingTimer invalidate];
		}
		coalescingTimer = [NSTimer scheduledTimerWithTimeInterval: 2 target: self selector: @selector(coalescingTimer:) userInfo: nil repeats: NO];
	}
	else
	{
		NSLog(@"No changes, not committing");
	}
}

- (void) commitTextChangesAsCheckpoint: (BOOL)isCheckpoint
{
	if (isCheckpoint)
	{
		selectedNote.currentBranch.shouldMakeEmptyCommit = YES;
	}
	
	if (replacementText == nil && [affectedText length] > 0)
	{
		[self commitWithIdentifier: @"modify-text" descriptionArguments: @[Trim(affectedText)] coalesce: YES isMinorTextEdit: !isCheckpoint];
	}
	else if ([replacementText isEqualToString: @""] && [affectedText length] > 0)
	{
		[self commitWithIdentifier: @"delete-text" descriptionArguments: @[Trim(affectedText)] coalesce: YES isMinorTextEdit: !isCheckpoint];
	}
	else if ([replacementText length] > 0 && [affectedText isEqualToString: @""])
	{
		[self commitWithIdentifier: @"insert-text" descriptionArguments: @[Trim(replacementText)] coalesce: YES isMinorTextEdit: !isCheckpoint];
	}
	else if ([replacementText length] > 0 && [affectedText length] > 0)
	{
		[self commitWithIdentifier: @"replace-text" descriptionArguments: @[Trim(affectedText), Trim(replacementText)] coalesce: YES isMinorTextEdit: !isCheckpoint];
	}
	else
	{
		NSLog(@"%@: got -textStorageDidProcessEditing:, but it wasn't caused by us.. ignoring", self);
	}
}

- (void) coalescingTimer: (NSTimer *)timer
{
	if ([[self undoTrack] isCoalescing])
	{
		NSLog(@"Breaking coalescing...");
		
		[self commitTextChangesAsCheckpoint: YES];
		
		[[self undoTrack] endCoalescing];

		[coalescingTimer invalidate];
		coalescingTimer = nil;
		affectedText = nil;
		replacementText = nil;
	}
}


#pragma mark - NSResponder

/**
 * The "delete" menu item is connected to this action
 */
- (void)delete: (id)sender
{
	if ([[self window] firstResponder] == notesTable)
	{
		NSMutableString *label = [NSMutableString new];
		for (COPersistentRoot *selectedPersistentRoot in [self selectedNotePersistentRoots])
		{
			selectedPersistentRoot.deleted = YES;
			if (selectedPersistentRoot.metadata[@"label"] != nil)
			{
				[label appendFormat: @" %@", selectedPersistentRoot.metadata[@"label"]];
			}
		}
		
		[self commitWithIdentifier: @"delete-note" descriptionArguments: @[label]];
		[noteListDataSource reloadData];
	}
	else if ([[self window] firstResponder] == tagsOutline)
	{
		if ([self clickedOrSelectedTag] != nil)
		{
			COTag *tag = [self clickedOrSelectedTag];
			COTagGroup *tagGroup = [self tagGroupOfSelectedRow];
			[tagGroup removeObject: tag];

			[self commitWithIdentifier: @"delete-tag" descriptionArguments: @[tag.name != nil ? tag.name : @""]];
			[tagListDataSource reloadData];
		}
		else if ([self tagGroupOfSelectedRow] != nil)
		{
			COTagGroup *tagGroup = [self tagGroupOfSelectedRow];
			[[[self tagLibrary] mutableArrayValueForKey: @"tagGroups"] removeObject: tagGroup];
			[self commitWithIdentifier: @"delete-tag-group" descriptionArguments: @[tagGroup.name != nil ? tagGroup.name : @""]];
			[tagListDataSource reloadData];
		}
	}
}

#pragma mark - Private

- (void) selectNote: (COPersistentRoot *)aNote
{
	selectedNote = aNote;
	
	if (selectedNote == nil)
	{
		// Nothing selected
		NSLog(@"Nothing selected");
		[textView setEditable: NO];
		[textView setHidden: YES];
		return;
	}
	else
	{
		[textView setEditable: YES];
		[textView setHidden: NO];
	}
	
	TypewriterDocument *doc = [selectedNote rootObject];

	if ([doc attrString] != [textStorage backing])
	{
		NSLog(@"Select %@. Old text storage: %p", selectedNote, textStorage);

		textStorage = [[COAttributedStringWrapper alloc] initWithBacking: [doc attrString]];
		[textStorage setDelegate: self];
		
		[textView.layoutManager replaceTextStorage: textStorage];

		NSLog(@"TV's ts: %p, New Text storage; %p", [textView textStorage], textStorage);
	}
	else
	{
		NSLog(@"selectNote: the attributed string hasn't changed");
	}
	
	// Set window title
	if (selectedNote.metadata[@"label"] != nil)
	{
		[[self window] setTitle: selectedNote.metadata[@"label"]];
	}
	else
	{
		[[self window] setTitle: @"Typewriter"];
	}
}

/**
 * call with nil to indicate no selection
 */
- (void) selectTag: (COTag *)aTag
{
	NSLog(@"Selected tag %@", aTag);
	
	[noteListDataSource reloadData];
}

- (void) commitWithIdentifier: (NSString *)identifier descriptionArguments: (NSArray*)args
{
	[self commitWithIdentifier: identifier descriptionArguments: args coalesce: NO isMinorTextEdit: NO];
}

- (void) commitWithIdentifier: (NSString *)identifier descriptionArguments: (NSArray*)args coalesce: (BOOL)requestCoalescing isMinorTextEdit: (BOOL)isMinor
{
	identifier = [@"org.etoile.Typewriter." stringByAppendingString: identifier];
	
	NSMutableDictionary *metadata = [NSMutableDictionary new];
	if (args != nil)
		metadata[kCOCommitMetadataShortDescriptionArguments] = args;
		
	metadata[@"minorEdit"] = @(isMinor);
	
	if (requestCoalescing && ![[self undoTrack] isCoalescing])
	{
		[[self undoTrack] beginCoalescing];
	}
	else if (!requestCoalescing && [[self undoTrack] isCoalescing])
	{
		[[self undoTrack] endCoalescing];
	}
	
	[self.editingContext commitWithIdentifier: identifier
									 metadata: metadata
									undoTrack: undoTrack
										error: NULL];
}

- (COTagLibrary *)tagLibrary
{
	return [[[self document] libraryPersistentRoot] rootObject];
}

- (COTagGroup *)defaultTagGroup
{
	return [self tagLibrary].tagGroups[0];
}

#pragma mark - Search

- (void)search:(id)sender
{
	[noteListDataSource reloadData];
}

@end
