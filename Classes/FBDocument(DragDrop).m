//
//  FBDocument(DragDrop).m
//  FrameByFrame
//
//  Created by Philipp Brendel on 19.12.10.
//  Copyright 2010 BrendCorp. All rights reserved.
//

#import "FBDocument(DragDrop).h"


@implementation FBDocument (DragDrop)

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination
{
	NSArray *sourceURLs = [self urlsForImagesAtIndexes: self.reelNavigator.selectedIndexes];
	NSMutableArray *names = [NSMutableArray arrayWithCapacity: sourceURLs.count];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	for (NSURL *source in sourceURLs) {
		NSError *error = nil;
		NSString *name = source.lastPathComponent;
		NSURL *destination = [dropDestination URLByAppendingPathComponent: name];
		
		if ([fileManager copyItemAtURL: source toURL: destination error: &error]) {
			[names addObject: name];
		}
		else {
			NSLog(@"Error copying file from %@ to %@ : %@", source, destination, error);
		}
	}
	
	return names;
}

#pragma mark -
#pragma mark Drag Drop Buddy
- (NSArray *) namesOfFilesAtIndexes: (NSIndexSet *) indexes forDestination: (NSURL *) dropDestination
{
	NSArray *sourceURLs = [self urlsForImagesAtIndexes: indexes];
	NSMutableArray *names = [NSMutableArray arrayWithCapacity: sourceURLs.count];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	for (NSURL *source in sourceURLs) {
		NSError *error = nil;
		NSString *name = source.lastPathComponent;
		NSURL *destination = [dropDestination URLByAppendingPathComponent: name];
		
		if ([fileManager copyItemAtURL: source toURL: destination error: &error]) {
			[names addObject: name];
		}
		else {
			NSLog(@"Error copying file from %@ to %@ : %@", source, destination, error);
		}
	}
	
	return names;	
}

- (void) insertImages: (NSArray *) importedImages atIndex: (NSUInteger) index
{
	// TODO: Make this into a method of FBReel
	for (NSInteger i = 0; i < importedImages.count; ++i) {
		CIImage *ciImage = [importedImages objectAtIndex: importedImages.count - (i + 1)];
		
		[self.reel insertCellWithImage: ciImage atIndex: index];
	}
}

- (void) moveCellsAtIndexes: (NSIndexSet *) sourceIndexes toIndex: (NSUInteger) destinationIndex
{
	NSArray *cells = [self.reel cellsAtIndexes: sourceIndexes];
	int finalDestination = destinationIndex - [sourceIndexes countOfIndexesInRange: NSMakeRange(0, destinationIndex)];
	
	[self.reel removeCellsAtIndexes: sourceIndexes];
	[self.reel insertCells: cells atIndex: finalDestination];
	// TODO: Find out if reel navigator needs to be re-displayed
}

@end