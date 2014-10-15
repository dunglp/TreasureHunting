//
//  Player.m
//  CellularAutomataFinal
//
//  Created by Bi Studio on 03/10/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import "Player.h"

@implementation Player

- (id)initWithTexture:(SKTexture *)texture
{
  if ((self = [super initWithTexture:texture])) {
    self.desiredPosition = self.position;
    
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:@"tiles"];
    
    self.playerIdleAnimationFrames = @[[atlas textureNamed:@"hero_idle_1"],
                                       [atlas textureNamed:@"hero_idle_2"]];
    
    self.playerWalkAnimationFrames = @[[atlas textureNamed:@"hero_run_1"],
                                       [atlas textureNamed:@"hero_run_2"],
                                       [atlas textureNamed:@"hero_run_3"],
                                       [atlas textureNamed:@"hero_run_4"]];
  }
  return self;
}

- (CGRect)boundingRect
{
  return CGRectMake(self.desiredPosition.x - (CGRectGetWidth(self.frame) / 2),
            self.desiredPosition.y - (CGRectGetHeight(self.frame) / 2),
            CGRectGetWidth(self.frame),
            CGRectGetHeight(self.frame));
}

- (void)resolveAnimationWithID:(NSUInteger)animationID
{
  NSString *animationKey = nil;
  NSArray *animationFrames = nil;
  CGFloat animationSpeed = 0.0f;
  
  switch (animationID)
  {
    case 0:
      // Idle
      animationKey = @"anim_idle";
      animationFrames = self.playerIdleAnimationFrames;
      animationSpeed = 10.0f;
      break;
      
    default:
      // Walk
      animationKey = @"anim_walk";
      animationFrames = self.playerWalkAnimationFrames;
      animationSpeed = 5.0f;
      break;
  }
  
  SKAction *animAction = [self actionForKey:animationKey];
  
  // If this animation is already running or there are no frames we exit
  if (animAction || [animationFrames count] < 1) {
    return;
  }
  
  animAction = [SKAction animateWithTextures:animationFrames timePerFrame:animationSpeed/60.0f resize:YES restore:NO];
  
  if (animationID == 1) {
    // Append sound for walking
    animAction = [SKAction group:@[animAction, [SKAction playSoundFileNamed:@"step.wav" waitForCompletion:NO]]];
  }
  
  [self runAction:animAction withKey:animationKey];
}

@end
