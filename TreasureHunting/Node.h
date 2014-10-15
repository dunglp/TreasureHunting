//
//  CaveCell.h
//  TreasureHunting
//
//  Created by Bi on 03/10/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, NodeType) {
    Invalid = -1,
    Wall,
    Floor,
    Entry,
    Exit,
    Treasure,
    Max
};

@interface Node : NSObject

@property (assign, nonatomic) CGPoint coordinate;
@property (assign, nonatomic) NodeType nodeType;

- (id) initWithCoordinate: (CGPoint)coordinate;

@end
