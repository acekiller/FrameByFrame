//
//  FBReelNavigatorDelegate.h
//  FrameByFrame
//
//  Created by Philipp Brendel on 06.11.10.
//  Copyright (c) 2010 BrendCorp. All rights reserved.
//

@class FBReelNavigator;

#pragma mark -
#pragma mark Reel Navigator Delegate
@protocol FBReelNavigatorDelegate <NSObject>

- (void) reelNavigatorRequestsSnapshot: (FBReelNavigator *) navigator;
- (void) reelNavigatorRequestsDeletion: (FBReelNavigator *) navigator;
// - (void) reelNavigator: (FBReelNavigator *) didSelectImageAtIndex: (NSUInteger) imageIndex;

@end
