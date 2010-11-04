//
//  FBDocument.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 28.10.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "FBReel.h"

@interface FBDocument : NSDocument 
{
	QTCaptureSession *captureSession;
	QTCaptureDeviceInput *captureDeviceInput;
	QTCaptureDecompressedVideoOutput *captureDecompressedVideoOutput;
	IBOutlet QTCaptureView *captureView;
	
	NSArray *inputDevices;
	QTCaptureDeviceInput *videoDeviceInput;
	
	FBReel *reel;
	BOOL shouldTakeSnapshot;
	
	CIFilter *inputFilter;
	
	NSURL *originalDocumentURL, *temporaryStorageURL;
}

#pragma mark -
#pragma mark Handling Document Storage
@property (retain) NSURL *originalDocumentURL, *temporaryStorageURL;
- (NSURL *) createTemporaryURL;

#pragma mark -
#pragma mark Video Input Devices
@property (retain) NSArray *inputDevices;
@property (retain) QTCaptureDevice *selectedInputDevice;
- (void) refreshInputDevices;

#pragma mark -
#pragma mark Displaying Video Input
- (CIImage *)view:(QTCaptureView *)view willDisplayImage:(CIImage *)image;
@property (retain) CIFilter *inputFilter;
- (CIFilter *) generateFilter;
- (CIFilter *) generateFilterForSinglePicture;
- (CIFilter *) generateFilterForMultiplePictures;

#pragma mark -
#pragma mark Taking Pictures
- (void) createSnapshotFromImage: (CIImage *) image;

#pragma mark -
#pragma mark Managing the Movie Reel
@property (retain) IBOutlet FBReel *reel;

#pragma mark -
#pragma mark Interface Builder Actions
- (IBAction) snapshot: (id) sender;

@end
