//
//  DPad.h
//  TreasureHunting
//
//  Created by Bi Studio on 03/08/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface DPad : SKNode

@property (assign, nonatomic, readonly) CGPoint stickPosition;
@property (assign, nonatomic, readonly) CGFloat degrees;
@property (assign, nonatomic, readonly) CGPoint velocity;
@property (assign, nonatomic) BOOL autoCenter;
@property (assign, nonatomic) BOOL isDPad;
@property (assign, nonatomic) BOOL hasDeadzone; // Turns deadzone on/off for joystick, always YES if isDPad == YES
@property (assign, nonatomic) NSUInteger numberOfDirections; // Only used when isDPad == YES

@property (assign, nonatomic) CGFloat joystickRadius;
@property (assign, nonatomic) CGFloat thumbRadius;
@property (assign, nonatomic) CGFloat deadRadius; // Size of deadzone in joystick (how far you must move before input starts). Automatically set is isDPad == YES

- (id)initWithRect:(CGRect)rect;

@end
