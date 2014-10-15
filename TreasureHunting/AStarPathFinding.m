//
//  ShortestPathStep.m
//  TreasureHunting
//
//  Created by Bi on 03/10/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import "AStarPathFinding.h"

@implementation AStarPathFinding

- (id) initWithPosition: (CGPoint)pos
{
    if ((self = [super init])) {
        _position = pos;
    }
    return self;
}

- (NSInteger) fScore
{
    return self.gScore + self.hScore;
}

@end
