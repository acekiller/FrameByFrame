//
//  FBReelNavigator.m
//  TestApp-MyImageView
//
//  Created by Philipp Brendel on 08.01.08.
//  Copyright 2009 Philipp Brendel. All rights reserved.
//
/*
 This file is part of FrameByFrame.
 
 FrameByFrame is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 FrameByFrame is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with FrameByFrame.  If not, see <http://www.gnu.org/licenses/>.
 */


#import "FBReelNavigator.h"
#import "NSShadow(SingleLineShadows).h"

#pragma mark Reel Navigator Private Interface
@interface FBReelNavigator ()
@property (retain) NSDictionary *textAttributes;
@property (retain) NSShadow *selectionShadow;
@property (copy) NSString *secondUnitName;
@end

#pragma mark -
#pragma mark Reel Navigator Implementation
@implementation FBReelNavigator

@synthesize currentImage, selectionColor, highlightColor;
@synthesize dataSource, delegate;
@dynamic count, selectedIndexes, selectedIndex, selectedImage, framesPerSecond;

#pragma mark -
#pragma mark Key-Value Coding
+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	if ([key isEqualToString: @"selectedImage"])
		return [NSSet setWithObject: @"selectedIndexes"];
	else
		return [NSSet set];
}

#pragma mark -
#pragma mark Adding Representations to Images
+ (NSArray *) addTIFFRepresentations: (NSArray *) images
{
	for (NSImage *image in images) {
		NSData *tiff = [image TIFFRepresentation];
		NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData: tiff];
		
		[image addRepresentation: rep];
	}
	
	return images;
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)initWithFrame:(NSRect)frame 
{
    if ((self = [super initWithFrame:frame])) {
		selectedIndexes = [[NSMutableIndexSet alloc] init];
		
		selectionColor = [[[NSColor blueColor] colorWithAlphaComponent: 0.3] retain];
		highlightColor = [[NSColor colorWithDeviceRed: 0.6 green: 0.86 blue: 1 alpha: 0.3] retain];
		
		insertionMark = -1;
		
		// Initialize drawing tools
		NSFont *font = [NSFont systemFontOfSize: [NSFont systemFontSize] + 2];
		NSShadow *shadow = [NSShadow shadowWithOffset: NSMakeSize(-2, -2) blurRadius: 3 color: [NSColor blackColor]];
		NSColor *infoColor = [NSColor orangeColor];
		
		self.selectionShadow = shadow;
		self.textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
							   infoColor,	NSForegroundColorAttributeName,
							   shadow,		NSShadowAttributeName,
							   font,		NSFontAttributeName,
							   nil];
		self.secondUnitName = NSLocalizedString(FFSecondUnitName, @"sec.");
    }
	
    return self;
}

- (void) dealloc
{
	[currentImage release];
	currentImage = nil;
	delegate = nil; // Delegate will not be retained upon assignment
	
	self.selectionShadow = nil;
	self.textAttributes = nil;
	self.secondUnitName = nil;
	
	[super dealloc];
}

- (void) awakeFromNib
{
	[self registerForDraggedTypes: [NSArray arrayWithObjects: @"FBIndexesPboardType", NSTIFFPboardType, NSFilenamesPboardType, nil]];
}

- (NSInteger) count
{
	return [self.dataSource numberOfCellsForReelNavigator: self];
}

#pragma mark -
#pragma mark Drawing

@synthesize textAttributes, selectionShadow, secondUnitName;

- (void)drawRect:(NSRect)rect 
{
	float spf = 1.0f / (float) [self framesPerSecond];
	
	// Draw the cells
	for (NSUInteger i = 0; i < [self count]; ++i) {
		NSRect cellExterior = NSMakeRect(i * [self cellWidth], 0, [self cellWidth], [self cellHeight]);
		NSRect dest = NSMakeRect(cellExterior.origin.x + [self cellBorderWidth], [self cellBorderHeight], [self cellInteriorWidth], [self cellInteriorHeight]);
		
		if (NSIntersectsRect(rect, dest)) {
			NSImage *image = [self.dataSource reelNavigator: self thumbnailForCellAtIndex: i];
			NSSize imageSize = image.size;
			
			// Draw image
			[image drawInRect: dest fromRect: NSMakeRect(0, 0, imageSize.width, imageSize.height) operation: NSCompositeSourceOver fraction: 1];
			
			// Draw selection/highlight
			if ([self.selectedIndexes containsIndex: i]) {
				NSRect sr = dest;
				NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRoundedRect: sr xRadius: 4 yRadius: 4];
				
				[[NSColor orangeColor] setStroke];
				[self.selectionShadow set];
				[selectionPath setLineWidth: 4];
				[selectionPath stroke];
				
				[NSShadow clearShadow];
			}
			
			// Draw time indicator
			NSRect textDest = NSInsetRect(dest, 4, 4);
			float second = i * spf;
			NSString *timeFormat = [NSString stringWithFormat: @"%.1f %@", second, secondUnitName];
			
			[timeFormat drawWithRect: NSMakeRect(textDest.origin.x + 2, textDest.origin.y + 1, textDest.size.width - 4, textDest.size.height - 2) options: 0 attributes: textAttributes];
			
			// Draw frame indicator
			NSString *frameFormat = [NSString stringWithFormat: @"%d", i + 1];
			NSRect frameFormatBounds = [frameFormat boundingRectWithSize: NSMakeSize(textDest.size.width - 4, textDest.size.height - 16) options: 0 attributes: textAttributes];
			
			[frameFormat drawWithRect: NSMakeRect(textDest.origin.x + 2, textDest.origin.y + textDest.size.height - (1 + frameFormatBounds.size.height), textDest.size.width - 4, textDest.size.height - 2 * (1 + frameFormatBounds.size.height)) options: 0 attributes: textAttributes];
		}
	}
	
	// Draw the insertion mark
	if (insertionMark >= 0) {
		NSBezierPath *markPath = [NSBezierPath bezierPathWithRect: NSMakeRect(insertionMark * [self cellWidth] - [self cellBorderWidth], 0, 2 * [self cellBorderWidth], [self cellHeight])];
		
		[[NSColor blueColor] setFill];
		[markPath fill];
	}
}

#pragma mark -
#pragma mark First Responder
- (BOOL) acceptsFirstResponder
{
	return YES;
}

#pragma mark -
#pragma mark Mouse Events
- (void) mouseDown: (NSEvent *) e
{
	NSPoint p = [self convertPoint: [e locationInWindow] fromView: nil];
	NSUInteger clickedCell = (NSUInteger) floor(p.x / [self cellWidth]);
	
	// Save position and cell for later use in the mouseDragged: event
	mouseDownPosition = p;
	mouseDownCell = clickedCell;
	
	if (clickedCell < [self count]) {
		if ([e modifierFlags] & NSCommandKeyMask) {
			[self willChangeValueForKey: @"selectedIndexes"];
			if ([selectedIndexes containsIndex: clickedCell])
				[selectedIndexes removeIndex: clickedCell];
			else
				[selectedIndexes addIndex: clickedCell];
			
			[self didChangeValueForKey: @"selectedIndexes"];
			[self setNeedsDisplay: YES];
		} else {
			if (![selectedIndexes containsIndex: clickedCell]) {
				[self willChangeValueForKey: @"selectedIndexes"];
				[self setSelectedIndexes: [NSIndexSet indexSetWithIndex: clickedCell]];
				[self didChangeValueForKey: @"selectedIndexes"];
				[self setNeedsDisplay: YES];
			}
		}
	}
}

#pragma mark -
#pragma mark Handling Selection
- (NSInteger) cellAtPoint: (NSPoint) p
{
	return (NSUInteger) MIN(round(p.x / [self cellWidth]), [self count]);
}

#pragma mark -
#pragma mark Key Events
- (void) keyDown: (NSEvent *) theEvent
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	unichar
		key = [[theEvent characters] characterAtIndex: 0],
		snapshotKey = [ud integerForKey: FFUserDefaultSnapshotKey],
		nextPictureKey = [ud integerForKey: FFUserDefaultNextPictureKey],
		previousPictureKey = [ud integerForKey: FFUserDefaultPreviousPictureKey],
		firstPictureKey = [ud integerForKey: FFUserDefaultFirstPictureKey],
		lastPictureKey = [ud integerForKey: FFUserDefaultLastPictureKey];
	
	if (key == snapshotKey)
		[self requestSnapshot];
	else if (key == nextPictureKey)
		[self shiftSelectionToRight];
	else if (key == previousPictureKey)
		[self shiftSelectionToLeft];
	else if (key == firstPictureKey)
		[self shiftSelectionToBeginning];
	else if (key == lastPictureKey)
		[self shiftSelectionToEnd];
	else if (key == NSDeleteCharacter)
		[self remove: self];
}

#pragma mark -
#pragma mark Cell Dimensions
- (float) cellWidth
{
	return [self cellHeight] * 1.333;
}

- (float) cellInteriorWidth
{
	return [self cellWidth] - 2 * [self cellBorderWidth];
}

- (float) cellHeight
{
	return MAX([self frame].size.height, 0);
}

- (float) cellInteriorHeight
{
	return [self cellHeight] - 2 * [self cellBorderHeight];
}

- (float) cellBorderWidth
{
	return 2;
}

- (float) cellBorderHeight
{
	return 2;
}

#pragma mark -
#pragma mark Scrolling
- (void) scrollToImage: (NSUInteger) index
{
	NSAssert2(index >= 0 && index < [self count], @"Index out of range: %d (count = %d)", index, self.count);
	
	NSInteger cells = floor([[scrollView contentView] bounds].size.width / [self cellWidth]);
	NSInteger i = MAX(0, (int) index - cells / 2);
	
	[[scrollView contentView] scrollToPoint: NSMakePoint(i * [self cellWidth], 0)];
	[scrollView reflectScrolledClipView: [scrollView contentView]];
}

- (BOOL) imageVisible: (NSUInteger) index
{
	if (index >= self.count)
		return NO;
	
	NSRect visibleArea = [scrollView documentVisibleRect];
	float imageWidth = self.cellWidth;
	float imageLeft = index * imageWidth;
	
	return imageLeft >= visibleArea.origin.x && imageLeft + imageWidth <= visibleArea.origin.x + visibleArea.size.width;
}

#pragma mark -
#pragma mark Resize to fit Images
- (void) resizeToFitImages
{
	[self setFrameSize: NSMakeSize([self cellWidth] * ([self count] + 1), [self frame].size.height)];
	if ([self count] > 0)
		[self scrollToImage: [self count] - 1];
}

#pragma mark -
#pragma mark Adding and Removing Images
- (void) addObject: (CIImage *) image
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
}
- (void) insertObject: (CIImage *) image atIndex: (NSUInteger) index
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
}
- (void) insertObjects: (NSArray *) images atIndex: (NSUInteger) index
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
}
- (void) insertObjects: (NSArray *) images atIndexes: (NSIndexSet *) indexes
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
}
- (void) removeObjectsAtIndexes: (NSIndexSet *) indexes
{
	@throw [NSException exceptionWithName: @"NotImplemented" reason: nil userInfo: nil];
}

#pragma mark -
#pragma mark Retrieving Images

- (NSArray *) imagesAtIndexes: (NSIndexSet *) indexes
{
	NSMutableArray *a = [NSMutableArray arrayWithCapacity: indexes.count];
	
	[indexes enumerateIndexesUsingBlock:
	 ^(NSUInteger i, BOOL *stop) {
		 [a addObject: [self.dataSource reelNavigator: self imageForCellAtIndex: i]];
	 }];
	
	return a;
}

#pragma mark -
#pragma mark IB Add, Remove
- (IBAction) add: (id) sender
{
	[self.delegate reelNavigatorRequestsSnapshot: self];
}

- (IBAction) remove: (id) sender
{
	[self.delegate reelNavigatorRequestsDeletion: self];
}

#pragma mark -
#pragma mark Selection Indices and Selected Images
- (void) setSelectedIndexes: (NSMutableIndexSet *) s
{
	[self willChangeValueForKey: @"selectedIndexes"];
	[selectedIndexes autorelease];
	selectedIndexes = [[NSMutableIndexSet alloc] initWithIndexSet: s];
	
	// Ensure visibility of the last selected image
	if ([selectedIndexes count] > 0 && ![self imageVisible: selectedIndexes.lastIndex])
		[self scrollToImage: selectedIndexes.lastIndex];
	
	[self didChangeValueForKey: @"selectedIndexes"];
	[self setNeedsDisplay: YES];
}

- (NSMutableIndexSet *) selectedIndexes
{
	return selectedIndexes;
}

- (NSUInteger) selectedIndex
{
	return [selectedIndexes lastIndex];
}

- (CIImage *) selectedImage
{
	NSUInteger selectedIndex = [self selectedIndex];
	
	// return selectedIndex == NSNotFound ? nil : [self.reel imageAtIndex: selectedIndex];
	return selectedIndex == NSNotFound ? nil : [self.dataSource reelNavigator: self imageForCellAtIndex: selectedIndex];
}

- (NSArray *) selectedImages
{
	return [self imagesAtIndexes: [self selectedIndexes]];
}

- (void) shiftSelectionToRight
{
	if ([self count] > 0) {
		if ([[self selectedIndexes] count] == 0)
			[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: 0]];
		else {
			NSUInteger lastIndex = [[self selectedIndexes] lastIndex];
			
			if (lastIndex < [self count] - 1 && lastIndex < NSUIntegerMax)
				[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: lastIndex + 1]];
		}
	}
}

- (void) shiftSelectionToLeft
{
	if ([self count] > 0) {
		if ([[self selectedIndexes] count] == 0)
			[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: [self count] - 1]];
		else {
			NSUInteger firstIndex = [[self selectedIndexes] firstIndex];
			
			if (firstIndex > 0)
				[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: firstIndex - 1]];
		}
	}
}

- (void) shiftSelectionToBeginning
{
	if ([self count] > 0)
		[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: 0]];
}

- (void) shiftSelectionToEnd
{
	if ([self count] > 0)
		[self setSelectedIndexes: [NSMutableIndexSet indexSetWithIndex: [self count] - 1]];
}

#pragma mark -
#pragma mark Frames per Second
- (NSUInteger) framesPerSecond
{
	return framesPerSecond;
}

- (void) setFramesPerSecond: (NSUInteger) fps
{
	[self willChangeValueForKey: @"framesPerSecond"];
	framesPerSecond = fps;
	[self setNeedsDisplay: YES];
	[self didChangeValueForKey: @"framesPerSecond"];
}

#pragma mark -
#pragma mark Cut, Copy, Paste and Delete Menu Items
+ (NSArray *) pasteTypes
{
	return [NSArray arrayWithObjects: FFImagesPboardType, NSFilenamesPboardType, NSURLPboardType, NSTIFFPboardType, nil];
}

- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
	SEL action = [menuItem action];
	
	if (action == @selector(copy:) 
		|| action == @selector(cut:)
		|| action == @selector(delete:))
		return [selectedIndexes count] > 0;
	else if (action == @selector(paste:))
		return [[NSPasteboard generalPasteboard] availableTypeFromArray: [FBReelNavigator pasteTypes]] != nil;
	else
		return NO;
}

- (IBAction) copy: (id) sender
{
	NSArray *types = [NSArray arrayWithObjects: FFImagesPboardType, NSTIFFPboardType, nil];
	NSArray *a = [FBReelNavigator addTIFFRepresentations: [self selectedImages]];
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCIImage: self.selectedImage];
	
	[pb declareTypes: types owner: self];
	
	[pb setData: [NSArchiver archivedDataWithRootObject: a] forType: FFImagesPboardType];
	[pb setData: [rep TIFFRepresentation] forType: NSTIFFPboardType];
	
	[rep release];
}

- (IBAction) paste: (id) sender
{
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSString *bestType = [pb availableTypeFromArray: [FBReelNavigator pasteTypes]];
	NSUInteger index = [self selectedIndex] == NSNotFound ? 0 : [self selectedIndex];
	
	if (bestType != nil) {
		if ([bestType isEqualToString: FFImagesPboardType]) {
			NSArray *pastedImages = [NSUnarchiver unarchiveObjectWithData: [pb dataForType: FFImagesPboardType]];
			
			if (pastedImages != nil)
				[self insertObjects: pastedImages atIndex: index];
		} else if ([bestType isEqualToString: NSTIFFPboardType]) {
			CIImage *pastedImage = [[CIImage alloc] initWithData: [pb dataForType: NSTIFFPboardType]];
			
			if (pastedImage != nil) {
				[self insertObject: pastedImage atIndex: index];
				[pastedImage release];
			}
		} else if ([bestType isEqualToString: NSFilenamesPboardType]) {
			NSArray *filenames = [pb propertyListForType: NSFilenamesPboardType];
			NSMutableArray *pastedImages = [NSMutableArray arrayWithCapacity: [filenames count]];
			
			for (NSString *filename in filenames) {
				NSData *data = [NSData dataWithContentsOfFile: filename];
				CIImage *image = [[CIImage alloc] initWithData: data];
				
				if (image != nil) {
					[pastedImages addObject: image];
					[image release];
				}
			}
			
			[self insertObjects: pastedImages atIndex: index];
		} else if ([bestType isEqualToString: NSURLPboardType]) {
			NSURL *url = [NSURL URLFromPasteboard: pb];
			
			if (url != nil) {
				NSData *data = [NSData dataWithContentsOfURL: url];
				CIImage *pastedImage = [[CIImage alloc] initWithData: data];
				
				if (pastedImage != nil) {
					[self insertObject: pastedImage atIndex: index];
					[pastedImage release];
				}
			}
		}
	}
}

- (IBAction) delete: (id) sender
{
	[self remove: nil];
}

- (IBAction) cut: (id) sender
{
	[self copy: nil];
	[self delete: nil];
}

#pragma mark -
#pragma mark Loading Images from Files
+ (NSArray *) loadImagesFromFiles: (NSArray *) filenames
{
	NSMutableArray *images = [NSMutableArray arrayWithCapacity: [filenames count]], *errors = [NSMutableArray array];
	NSEnumerator *e = [filenames objectEnumerator];
	NSString *filename;
	
	while ((filename = [e nextObject])) {
		CIImage *image = [CIImage imageWithData: [NSData dataWithContentsOfFile: filename]];
		
		if (image == nil)
			[errors addObject: filename];
		else
			[images addObject: image];
	}
	
	if ([errors count] > 0) {
		NSRunAlertPanel(@"Error loading image files", [errors componentsJoinedByString: @"\n"], @"OK", nil, nil);
	}
	
	return images;
}

#pragma mark -
#pragma mark Making Snapshots
- (void) requestSnapshot
{
	if ([delegate respondsToSelector: @selector(imageStripRequestsSnapshot:)])
		[delegate reelNavigatorRequestsSnapshot: self];
	else
		[self add: self];
}

#pragma mark -
#pragma mark Handling Resolution Issues
+ (void) adaptImageSizeToResolution: (NSArray *) images
{
	NSLog(@"TODO Figure out if -adaptImageSizeToResolution: is still needed - right now, it does nothing (still works with NSImage, so careful!)");
//	// Adapt image size to help QuickTime work correctly 
//	// with images of resolutions different from 72 dpi
//	for (NSImage *anImage in images) {
//		NSBitmapImageRep *r = (NSBitmapImageRep *) [anImage bestRepresentationForDevice: nil];
//		
//		if (([r pixelsWide] != (int) (double) round(((NSSize) [r size]).width))) {
//			[anImage setScalesWhenResized: YES];
//			[anImage setSize: NSMakeSize([r pixelsWide], [r pixelsHigh])];
//		}
//	}	
}

- (void) reelHasChanged
{
	[self resizeToFitImages];
	[self setNeedsDisplay: YES];
	
	if (self.selectedIndex != NSNotFound)
		[self scrollToImage: self.selectedIndex];
}

#pragma mark -
#pragma mark Insertion mark
- (NSInteger) insertionMark
{
	return insertionMark;
}

- (void) setInsertionMark: (NSInteger) index
{
	if (index < -1 || index > [self count] + 1)
		NSLog(@"Suspicious insertion mark index: %d (strip has %d elements)", index, [self count]);
	
	insertionMark = index;
	[self setNeedsDisplay: YES];
}

#pragma mark -
#pragma mark Drag and Drop
@synthesize dragDropBuddy;

@end
