//
//  CaveCell.m
//  TreasureHunting
//
//  Created by Bi on 03/10/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import "Node.h"

@implementation Node

- (id) initWithCoordinate: (CGPoint)coordinate
{
    if ((self = [super init])) {
        _coordinate = coordinate;
        _nodeType = Invalid;
    }
    return self;
}


@end
