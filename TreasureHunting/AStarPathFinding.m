//
//  ShortestPathStep.m
//  TreasureHunting
//
//  Created by Bi on 03/10/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import "AStarPathFinding.h"

@implementation AStarPathFinding

- (id) initWithPosition: (CGPoint) position
{
    if ((self = [super init])) {
        _position = position;
    }
    return self;
}

- (NSInteger) score
{
    return self.gScore + self.hScore;
}

+ (NSInteger) computeCostFromNode:(AStarPathFinding *)fromStep toNode:(AStarPathFinding *)toStep
{
    return 1;
}


+ (NSInteger) computeHScoreFromCoordinate:(CGPoint)fromCoordinate toCoordinate:(CGPoint)toCoordinate rate:(NSUInteger) rate
{
    return rate * (abs(toCoordinate.x - fromCoordinate.x) + abs(toCoordinate.y - fromCoordinate.y));
}

@end
