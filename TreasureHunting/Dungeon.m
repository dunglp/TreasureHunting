//
//  Cave.m
//  TreasureHunting
//
//  Created by Bi Studio on 03/10/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import "Dungeon.h"
#import "Node.h"
#import "AStarPathFinding.h"

@interface Dungeon ()
    @property (strong, nonatomic) NSMutableArray *caves;
@end

@implementation Dungeon

- (CGFloat) getRandomNumber
{
    return random() / (float)0x7fffffff;
}

- (id) initWithAtlasNamed: (NSString *) name mapSize: (CGSize) mapSize
{
    if ((self = [super init])) {
        _atlas = [SKTextureAtlas atlasNamed:name];
        _mapSize = mapSize;
        _tileSize = [self sizeOfTiles];
        _wallRate = 0.45f;
        _toWallCondition = 4;
        _toFloorCondition = 3;
        _transitionStepCount = 1;
        _entrance = CGPointZero;
        _exit = CGPointZero;
        _entryExitMinRange = 32.0f;
    }
    return self;
}

- (void) initializeGrid
{
    self.map = [NSMutableArray arrayWithCapacity: (NSUInteger) self.mapSize.height];
    
    for (NSUInteger x = 0; x < self.mapSize.height; x++) {
        NSMutableArray *row = [NSMutableArray arrayWithCapacity: (NSUInteger) self.mapSize.width];
        
        for (NSUInteger y= 0; y < self.mapSize.width; y++) {
            CGPoint coordinate = CGPointMake(y, x);
            Node *cell = [[Node alloc] initWithCoordinate:coordinate];
            
            if ([self isEdgeAtGridCoordinate:coordinate]) {
                cell.nodeType = Wall;
            } else {
                cell.nodeType = [self getRandomNumber] < self.wallRate ? Wall : Floor;
            }
            
            [row addObject:cell];
        }
        
        [self.map addObject:row];
    }
}

- (void) generateMap
{
    [self initializeGrid];
    
    for (NSUInteger step = 0; step < self.transitionStepCount; step++) {
        [self doTransitionStep];
    }
    
    [self identifyCaves];
    
    if (self.connectedCave) {
        [self addToMainCave];
    } else {
        [self removeDisconnectedCaverns];
    }
    
    [self identifyCaves];
    [self setEntryAndExit];
    [self setTreasure];
    [self generateTiles];
    
}

- (BOOL) isValidGridCoordinate:(CGPoint)coordinate
{
    return !(coordinate.x < 0 || coordinate.x >= self.mapSize.width ||
             coordinate.y < 0 || coordinate.y >= self.mapSize.height);
}

- (Node *) caveCellFromGridCoordinate:(CGPoint)coordinate
{
    if ([self isValidGridCoordinate:coordinate]) {
        return (Node *)self.map[(NSUInteger)coordinate.y][(NSUInteger)coordinate.x];
    }
    
    return nil;
}

- (void) generateTiles
{
    for (NSUInteger y = 0; y < self.mapSize.height; y++) {
        for (NSUInteger x = 0; x < self.mapSize.width; x++) {
            Node *cell = [self caveCellFromGridCoordinate:CGPointMake(x, y)];
            
            SKSpriteNode *node;
            
            switch (cell.nodeType) {
                case Wall:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile2_0"]];
                    break;
                    
                case Entry:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile4_0"]];
                    break;
                    
                case Exit:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile3_0"]];
                    break;
                    
                case Treasure:
                {
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile0_0"]];
                    
                    SKSpriteNode *treasure = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"treasure"]];
                    treasure.name = @"TREASURE";
                    treasure.position = CGPointMake(0.0f, 0.0f);
                    [node addChild:treasure];
                    
                    break;
                }
                    
                default:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile0_0"]];
                    break;
            }
            
            node.position = [self positionForGridCoordinate:CGPointMake(x, y)];
            
            node.blendMode = SKBlendModeReplace;
            node.texture.filteringMode = SKTextureFilteringNearest;
            
            [self addChild:node];
        }
    }
}

- (CGSize) sizeOfTiles
{
    SKTexture *texture = [self.atlas textureNamed:@"tile0_0"];
    return texture.size;
}

- (CGPoint) positionForGridCoordinate: (CGPoint) coordinate
{
    return CGPointMake(coordinate.x * self.tileSize.width + self.tileSize.width / 2.0f,
                       (coordinate.y * self.tileSize.height + self.tileSize.height / 2.0f));
}

- (NSUInteger) countNeighborsWallFromGridCoordinate: (CGPoint) coordinate
{
    NSUInteger wallCount = 0;
    
    for (NSInteger i = -1; i < 2; i++) {
        for (NSInteger j = -1; j < 2; j++) {
            if ( i == 0 && j == 0 ) {
                break;
            }
            
            CGPoint neighborCoordinate = CGPointMake(coordinate.x + i, coordinate.y + j);
            if (![self isValidGridCoordinate:neighborCoordinate]) {
                wallCount++;
            } else if ([self caveCellFromGridCoordinate:neighborCoordinate].nodeType == Wall) {
                wallCount++;
            }
        }
    }
    return wallCount;
}

- (void) doTransitionStep
{
    NSMutableArray *newMap = [NSMutableArray arrayWithCapacity: (NSUInteger) self.mapSize.height];
    
    for (NSUInteger x = 0; x < self.mapSize.height; x++) {
        NSMutableArray *newRow = [NSMutableArray arrayWithCapacity:(NSUInteger)self.mapSize.width];
        for (NSUInteger y = 0; y < self.mapSize.width; y++) {
            CGPoint coordinate = CGPointMake(y, x);
            
            NSUInteger neighborWallCount = [self countNeighborsWallFromGridCoordinate:coordinate];
            
            Node *oldCell = [self caveCellFromGridCoordinate:coordinate];
            Node *newCell = [[Node alloc] initWithCoordinate:coordinate];
            
            if (oldCell.nodeType == Wall) {
                newCell.nodeType = (neighborWallCount < self.toFloorCondition) ? Floor : Wall;
            } else {
                newCell.nodeType = (neighborWallCount > self.toWallCondition) ? Wall : Floor;
            }
            [newRow addObject:newCell];
        }
        [newMap addObject:newRow];
    }
    
    self.map = newMap;
}

- (void) floodFillCave: (NSMutableArray *) array fromCoordinate: (CGPoint) coordinate
              fillNumber: (NSInteger) fillNumber
{
    Node *cell = (Node *)array[(NSUInteger)coordinate.y][(NSUInteger)coordinate.x];
    
    if (cell.nodeType != Floor) {
        return;
    }
    
    cell.nodeType = fillNumber;
    [[self.caves lastObject] addObject:cell];
    
    if (coordinate.x > 0) {
        [self floodFillCave:array fromCoordinate:CGPointMake(coordinate.x - 1, coordinate.y)
                   fillNumber:fillNumber];
    }
    if (coordinate.x < self.mapSize.width - 1) {
        [self floodFillCave:array fromCoordinate:CGPointMake(coordinate.x + 1, coordinate.y)
                   fillNumber:fillNumber];
    }
    if (coordinate.y > 0) {
        [self floodFillCave:array fromCoordinate:CGPointMake(coordinate.x, coordinate.y - 1)
                   fillNumber:fillNumber];
    }
    if (coordinate.y < self.mapSize.height - 1) {
        [self floodFillCave:array fromCoordinate:CGPointMake(coordinate.x, coordinate.y + 1)
                   fillNumber:fillNumber];
    }
}

- (void) identifyCaves
{
    self.caves = [NSMutableArray array];
    NSMutableArray *floodFillArray = [NSMutableArray arrayWithCapacity:(NSUInteger)self.mapSize.height];
    
    for (NSUInteger y = 0; y < self.mapSize.height; y++) {
        NSMutableArray *floodFillArrayRow = [NSMutableArray arrayWithCapacity:(NSUInteger)self.mapSize.width];
        
        for (NSUInteger x = 0; x < self.mapSize.width; x++) {
            Node *cellToCopy = (Node *)self.map[y][x];
            Node *copiedCell = [[Node alloc] initWithCoordinate:cellToCopy.coordinate];
            copiedCell.nodeType = cellToCopy.nodeType;
            [floodFillArrayRow addObject:copiedCell];
        }
        
        [floodFillArray addObject:floodFillArrayRow];
    }
    
    NSInteger fillNumber = Max;
    for (NSUInteger y = 0; y < self.mapSize.height; y++) {
        for (NSUInteger x = 0; x < self.mapSize.width; x++) {
            if (((Node *)floodFillArray[y][x]).nodeType == Floor) {
                [self.caves addObject:[NSMutableArray array]];
                [self floodFillCave:floodFillArray fromCoordinate:CGPointMake(x, y) fillNumber:fillNumber];
                fillNumber++;
            }
        }
    }
    
}

- (NSInteger) mainCaveIndex
{
    NSInteger mainCaveIndex = -1;
    NSUInteger maxCaveSize = 0;
    
    for (NSUInteger i = 0; i < [self.caves count]; i++) {
        NSArray *caveCells = (NSArray *)self.caves[i];
        NSUInteger caveCellsCount = [caveCells count];
        
        if (caveCellsCount > maxCaveSize) {
            maxCaveSize = caveCellsCount;
            mainCaveIndex = i;
        }
    }
    
    return mainCaveIndex;
}

- (void) removeDisconnectedCaverns
{
    NSInteger mainCaveIndex = [self mainCaveIndex];
    NSUInteger cavesCount = [self.caves count];
    
    if (cavesCount > 0) {
        for (NSUInteger i = 0; i < cavesCount; i++) {
            if (i != mainCaveIndex) {
                NSArray *array = (NSArray *)self.caves[i];
                
                for (Node *cell in array) {
                    ((Node *)self.map[(NSUInteger)cell.coordinate.y][(NSUInteger)cell.coordinate.x]).nodeType = Wall;
                }
            }
        }
    }
}

- (void) addToMainCave
{
    NSUInteger mainCaveIndex = [self mainCaveIndex];
    
    NSArray *mainCave = (NSArray *)self.caves[mainCaveIndex];
    
    for (NSUInteger cavernIndex = 0; cavernIndex < [self.caves count]; cavernIndex++) {
        if (cavernIndex != mainCaveIndex) {
            NSArray *originCavern = self.caves[cavernIndex];
            Node *originCell = (Node *)originCavern[arc4random() % [originCavern count]];
            Node *destinationCell = (Node *)mainCave[arc4random() % [mainCave count]];
            [self createPathBetweenOrigin:originCell destination:destinationCell];
        }
    }
}

- (void) insertNode: (AStarPathFinding *)step toList:(NSMutableArray *)list
{
    NSInteger stepFScore = [step score];
    NSInteger count = [list count];
    NSInteger i = 0;
    
    for (; i < count; i++) {
        if (stepFScore <= [[list objectAtIndex:i] score]) {
            break;
        }
    }
    
    [list insertObject:step atIndex:i];
}



- (NSArray *) neighbourCells:(CGPoint)cellCoordinate
{
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:4];
    
    // Top
    CGPoint p = CGPointMake(cellCoordinate.x, cellCoordinate.y - 1);
    if ([self isValidGridCoordinate:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
    }
    
    // Left
    p = CGPointMake(cellCoordinate.x - 1, cellCoordinate.y);
    if ([self isValidGridCoordinate:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
    }
    
    // Bottom
    p = CGPointMake(cellCoordinate.x, cellCoordinate.y + 1);
    if ([self isValidGridCoordinate:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
    }
    
    // Right
    p = CGPointMake(cellCoordinate.x + 1, cellCoordinate.y);
    if ([self isValidGridCoordinate:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
    }
    
    return [NSArray arrayWithArray:tmp];
}

- (void) createPathBetweenOrigin:(Node *)originCell destination:(Node *)destinationCell
{
    NSMutableArray *openList = [NSMutableArray array];
    NSMutableArray *closedLists = [NSMutableArray array];
    
    [self insertNode:[[AStarPathFinding alloc] initWithPosition:originCell.coordinate] toList:openList];
    
    while ([openList count] != 0)
    {
        AStarPathFinding *currentNode = [openList firstObject];
        
        [closedLists addObject:currentNode];
        [openList removeObjectAtIndex:0];
        
        if (CGPointEqualToPoint(currentNode.position, destinationCell.coordinate)) {
            [self constructMovePath:currentNode];
            break;
        }
        
        NSArray *neighbours = [self neighbourCells:currentNode.position];
        
        for (NSValue *n in neighbours) {
            AStarPathFinding *node = [[AStarPathFinding alloc] initWithPosition:[n CGPointValue]];
            
            if ([closedLists containsObject:node]) {
                continue;
            }
            
            NSInteger moveCost = [AStarPathFinding computeCostFromNode:currentNode toNode:node];
            
            NSUInteger index = [openList indexOfObject:node];
            
            if (index != NSNotFound) {
                node = [openList objectAtIndex:index];
                
                if ((currentNode.gScore + moveCost) < node.gScore) {
                    node.gScore = currentNode.gScore + moveCost;
                    AStarPathFinding *tmp = [[AStarPathFinding alloc] initWithPosition:node.position];
                    [openList removeObjectAtIndex:index];
                    [self insertNode:tmp toList:openList];
                }
            } else {
                node.parent = currentNode;
                node.gScore = currentNode.gScore + moveCost;
                node.hScore = [self computeHScoreFrom:node.position to:destinationCell.coordinate];
                [self insertNode:node toList:openList];
            }
        }
        
    }
}

- (void) constructMovePath: (AStarPathFinding *)path
{
    do {
        if (path.parent) {
            Node *cell = [self caveCellFromGridCoordinate:path.position];
            cell.nodeType = Floor;
        }
        path = path.parent;
    } while (path);
}

- (NSInteger) computeHScoreFrom:(CGPoint)fromCoordinate to:(CGPoint)toCoordinate
{
    Node *cell = [self caveCellFromGridCoordinate:toCoordinate];
    
    NSUInteger multiplier = cell.nodeType = Wall ? 15 : 1;
    
    return multiplier * (abs(toCoordinate.x - fromCoordinate.x) + abs(toCoordinate.y - fromCoordinate.y));
}

- (void) setEntryAndExit
{
    NSUInteger mainCaveIndex = [self mainCaveIndex];
    NSArray *mainCave = (NSArray *)self.caves[mainCaveIndex];
    
    NSUInteger mainCaveCount = [mainCave count];
    Node *entranceCell = (Node *)mainCave[arc4random() % mainCaveCount];
    
    [self caveCellFromGridCoordinate:entranceCell.coordinate].nodeType = Entry;
    _entrance = [self positionForGridCoordinate:entranceCell.coordinate];
    
    Node *exitCell = nil;
    CGFloat distance = 0.0f;
    
    while (distance < self.entryExitMinRange)
    {
        exitCell = (Node *) mainCave[arc4random() % mainCaveCount];
        
        NSInteger a = (exitCell.coordinate.x - entranceCell.coordinate.x);
        NSInteger b = (exitCell.coordinate.y - entranceCell.coordinate.y);
        distance = a * a + b * b;
        
    }
    
    [self caveCellFromGridCoordinate: exitCell.coordinate].nodeType = Exit;
    _exit = [self positionForGridCoordinate: exitCell.coordinate];
}

- (void) setTreasure
{
    NSUInteger treasureCondition = 4;
    
    for (NSUInteger x = 0; x < self.mapSize.height; x++) {
        for (NSUInteger y = 0; y < self.mapSize.width; y++) {
            Node *cell = (Node *) self.map[x][y];
            
            if (cell.nodeType == Floor) {
                NSUInteger neighborWallCount = [self countNeighborsWallFromGridCoordinate:CGPointMake(y, x)];
                
                if (neighborWallCount > treasureCondition) {
                    cell.nodeType = Treasure;
                }
            }
        }
    }
}

- (CGRect) caveCellRectFromGridCoordinate: (CGPoint) coordinate
{
    if ([self isValidGridCoordinate:coordinate]) {
        CGPoint cellPosition = [self positionForGridCoordinate:coordinate];
        
        return CGRectMake(cellPosition.x - (self.tileSize.width / 2), cellPosition.y - (self.tileSize.height / 2),
                          self.tileSize.width, self.tileSize.height);
    }
    return CGRectZero;
}

- (BOOL) isEdgeAtGridCoordinate: (CGPoint) coordinate
{
    return ((NSUInteger)coordinate.x == 0 || (NSUInteger)coordinate.x == (NSUInteger)self.mapSize.width - 1 ||
            (NSUInteger)coordinate.y == 0 || (NSUInteger)coordinate.y == (NSUInteger)self.mapSize.height - 1);
}

- (CGPoint) gridCoordinateForPosition: (CGPoint) position
{
    return CGPointMake((position.x / self.tileSize.width), (position.y / self.tileSize.height));
}


@end
