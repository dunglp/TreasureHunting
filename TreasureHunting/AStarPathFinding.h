//
//  ShortestPathStep.h
//  TreasureHunting
//
//  Created by Bi on 03/10/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AStarPathFinding : NSObject

@property (assign, nonatomic) CGPoint position;
@property (assign, nonatomic) NSInteger gScore;
@property (assign, nonatomic) NSInteger hScore;
@property (strong, nonatomic) AStarPathFinding *parent;

- (id) initWithPosition: (CGPoint) position;
- (NSInteger) score;
+ (NSInteger) computeCostFromNode:(AStarPathFinding *)fromStep toNode:(AStarPathFinding *)toStep;
+ (NSInteger) computeHScoreFromCoordinate:(CGPoint)fromCoordinate toCoordinate:(CGPoint)toCoordinate rate:(NSUInteger) rate;

@end
