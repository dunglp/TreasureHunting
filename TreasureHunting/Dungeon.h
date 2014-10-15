//
//  Cave.h
//  TreasureHunting
//
//  Created by Bi Studio on 03/10/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@class Node;

@interface Dungeon : SKNode 

@property (strong, nonatomic, readonly) SKTextureAtlas *atlas;

// The map
@property (strong, nonatomic) NSMutableArray *map;

// Map size
@property (assign, nonatomic, readonly) CGSize mapSize;

// Tile size
@property (assign, nonatomic, readonly) CGSize tileSize;

// Wall or Floor random rate - 0 : floor, 1 : wall
@property (assign, nonatomic) CGFloat wallRate;

// Map conversion
@property (assign, nonatomic) NSUInteger toWallCondition;
@property (assign, nonatomic) NSUInteger toFloorCondition;

// Transition steps count
@property (assign, nonatomic) NSUInteger transitionStepCount;

@property (assign, nonatomic) BOOL connectedCave;

@property (assign, nonatomic, readonly) CGPoint entrance;
@property (assign, nonatomic, readonly) CGPoint exit;
@property (assign, nonatomic) CGFloat entryExitMinRange;

// Init map with atlas name and map size
- (id) initWithAtlasNamed:(NSString *)name mapSize:(CGSize)mapSize;

// Generate map
- (void) generateMap;

- (Node *) caveCellFromGridCoordinate:(CGPoint)coordinate;
- (CGPoint) gridCoordinateForPosition:(CGPoint)position;
- (CGRect) caveCellRectFromGridCoordinate:(CGPoint)coordinate;

@end
