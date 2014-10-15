//
//  Player.h
//  CellularAutomataFinal
//
//  Created by Bi Studio on 03/08/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Player : SKSpriteNode

@property (assign, nonatomic) CGPoint desiredPosition;
@property (readonly, nonatomic) CGRect boundingRect;

@property (copy, nonatomic) NSArray *playerIdleAnimationFrames;
@property (copy, nonatomic) NSArray *playerWalkAnimationFrames;
@property (assign, nonatomic) NSUInteger playerAnimationID; // 0 = idle; 1 = walk

- (void) resolveAnimationWithID:(NSUInteger)animationID;

@end
