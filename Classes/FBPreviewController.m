//
//  FBPreviewController.m
//  FrameByFrame
//
//  Created by Philipp Brendel on 18.01.11.
//  Copyright 2011 BrendCorp. All rights reserved.
//

#import "FBPreviewController.h"

@interface FBPreviewController ()
@property (retain) NSTimer *timer;
- (void) presentFrame;
- (void) nextFrame: (id) sender;
@end

#pragma mark -

@implementation FBPreviewController
@synthesize timer;

- (id)init {
    if ((self = [super init])) {
        // Initialization code here.
    }
    
    return self;
}

- (void)dealloc 
{
    [self.timer invalidate];
	self.timer = nil;
	
	reel = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Awaking from Nib

- (void) awakeFromNib
{
	[previewPanel setBecomesKeyOnlyIfNeeded: YES];
}

#pragma mark -
#pragma mark Playing Previews

@synthesize framesPerSecond;

- (BOOL) isPreviewPlaying
{
	return self.timer != nil;
}

- (void) startPreviewWithReel: (FBReel *) aReel
			 fromImageAtIndex: (NSUInteger) startIndex
			  framesPerSecond: (NSUInteger) fps
{
	[self stopPreview];
	
	reel = aReel;
	frameIndex = startIndex;
	self.timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 / (float) fps target: self selector: @selector(nextFrame:) userInfo: nil repeats: YES];
}

- (void) setupPreviewWithReel: (FBReel *) aReel
			 fromImageAtIndex: (NSUInteger) startIndex
			  framesPerSecond: (NSUInteger) fps
{
	[self stopPreview];
	reel = aReel;
	startFrame = frameIndex = startIndex;
	framesPerSecond = fps;
	[self presentFrame];
	
	[previewPanel orderFront: self];
}

- (void) nextFrame: (id) sender
{
	if (frameIndex < reel.count) {
		[self presentFrame];
		
		++frameIndex;
	} else
		[self stopPreview];
}

- (void) startPreview
{
	frameIndex = startFrame;
	self.timer = [NSTimer scheduledTimerWithTimeInterval: 1.0 / (float) framesPerSecond
												  target: self
												selector: @selector(nextFrame:)
												userInfo: nil
												 repeats: YES];
}

- (void) stopPreview
{
	[self.timer invalidate];
	self.timer = nil;
	
	playButton.state = NSOffState;
}

- (void) togglePreview
{
	if (self.isPreviewPlaying)
		[self stopPreview];
	else
		[self startPreview];
}

- (void) rewindPreview
{
	[self stopPreview];
	startFrame = frameIndex = 0;
	[self presentFrame];
}

#pragma mark -
#pragma mark Presenting Frames
- (void) presentFrame
{
	if (frameIndex < reel.count) {
		// NOTE Don't query cells, but images
		// This way, the reel can release unused images
		NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCIImage: [reel imageAtIndex: frameIndex]];
		NSImage *image = [[NSImage alloc] init];
		
		[image addRepresentation: rep];
		[imageView setImage: image];
		[image release];
		[rep release];
	}
}

#pragma mark -
#pragma mark Interface Builder Actions
- (IBAction) togglePreview: (id) sender
{
	[self togglePreview];
}

- (IBAction) rewindPreview: (id) sender
{
	[self rewindPreview];
}

@end
