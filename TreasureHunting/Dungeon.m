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
        [self connectToMainCavern];
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

- (NSUInteger) countWallMooreNeighborsFromGridCoordinate: (CGPoint) coordinate
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
    // 1
    NSMutableArray *newGrid = [NSMutableArray arrayWithCapacity:(NSUInteger)self.mapSize.height];
    
    // 2
    for (NSUInteger y = 0; y < self.mapSize.height; y++) {
        NSMutableArray *newRow = [NSMutableArray arrayWithCapacity:(NSUInteger)self.mapSize.width];
        for (NSUInteger x = 0; x < self.mapSize.width; x++) {
            CGPoint coordinate = CGPointMake(x, y);
            
            // 3
            NSUInteger mooreNeighborWallCount = [self countWallMooreNeighborsFromGridCoordinate:coordinate];
            
            // 4
            Node *oldCell = [self caveCellFromGridCoordinate:coordinate];
            Node *newCell = [[Node alloc] initWithCoordinate:coordinate];
            
            // 5
            // 5a
            if (oldCell.nodeType == Wall) {
                newCell.nodeType = (mooreNeighborWallCount < self.toFloorCondition) ? Floor : Wall;
            } else {
                // 5b
                newCell.nodeType = (mooreNeighborWallCount > self.toWallCondition) ? Wall : Floor;
            }
            [newRow addObject:newCell];
        }
        [newGrid addObject:newRow];
    }
    
    // 6
    self.map = newGrid;
}

- (void) floodFillCavern: (NSMutableArray *) array fromCoordinate: (CGPoint) coordinate
              fillNumber: (NSInteger) fillNumber
{
    Node *cell = (Node *)array[(NSUInteger)coordinate.y][(NSUInteger)coordinate.x];
    
    if (cell.nodeType != Floor) {
        return;
    }
    
    cell.nodeType = fillNumber;
    [[self.caves lastObject] addObject:cell];
    
    if (coordinate.x > 0) {
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x - 1, coordinate.y)
                   fillNumber:fillNumber];
    }
    if (coordinate.x < self.mapSize.width - 1) {
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x + 1, coordinate.y)
                   fillNumber:fillNumber];
    }
    if (coordinate.y > 0) {
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x, coordinate.y - 1)
                   fillNumber:fillNumber];
    }
    if (coordinate.y < self.mapSize.height - 1) {
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x, coordinate.y + 1)
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
                [self floodFillCavern:floodFillArray fromCoordinate:CGPointMake(x, y) fillNumber:fillNumber];
                fillNumber++;
            }
        }
    }
    
}

- (NSInteger)mainCavernIndex
{
    NSInteger mainCavernIndex = -1;
    NSUInteger maxCavernSize = 0;
    
    for (NSUInteger i = 0; i < [self.caves count]; i++) {
        NSArray *caveCells = (NSArray *)self.caves[i];
        NSUInteger caveCellsCount = [caveCells count];
        
        if (caveCellsCount > maxCavernSize) {
            maxCavernSize = caveCellsCount;
            mainCavernIndex = i;
        }
    }
    
    return mainCavernIndex;
}

- (void) removeDisconnectedCaverns
{
    NSInteger mainCavernIndex = [self mainCavernIndex];
    NSUInteger cavesCount = [self.caves count];
    
    if (cavesCount > 0) {
        for (NSUInteger i = 0; i < cavesCount; i++) {
            if (i != mainCavernIndex) {
                NSArray *array = (NSArray *)self.caves[i];
                
                for (Node *cell in array) {
                    ((Node *)self.map[(NSUInteger)cell.coordinate.y][(NSUInteger)cell.coordinate.x]).nodeType = Wall;
                }
            }
        }
    }
}

- (void)connectToMainCavern
{
    NSUInteger mainCavernIndex = [self mainCavernIndex];
    
    NSArray *mainCavern = (NSArray *)self.caves[mainCavernIndex];
    
    for (NSUInteger cavernIndex = 0; cavernIndex < [self.caves count]; cavernIndex++) {
        if (cavernIndex != mainCavernIndex) {
            NSArray *originCavern = self.caves[cavernIndex];
            Node *originCell = (Node *)originCavern[arc4random() % [originCavern count]];
            Node *destinationCell = (Node *)mainCavern[arc4random() % [mainCavern count]];
            [self createPathBetweenOrigin:originCell destination:destinationCell];
        }
    }
}

// Added inList parameter as this implementation does not use properties to store
// open and closed lists.
- (void)insertStep:(AStarPathFinding *)step inList:(NSMutableArray *)list
{
    NSInteger stepFScore = [step fScore];
    NSInteger count = [list count];
    NSInteger i = 0;
    
    for (; i < count; i++) {
        if (stepFScore <= [[list objectAtIndex:i] fScore]) {
            break;
        }
    }
    
    [list insertObject:step atIndex:i];
}

- (NSInteger)costToMoveFromStep:(AStarPathFinding *)fromStep toAdjacentStep:(AStarPathFinding *)toStep
{
    // Always returns one, as it is equally expensive to move either up, down, left or right.
    return 1;
}

- (NSInteger)computeHScoreFromCoordinate:(CGPoint)fromCoordinate toCoordinate:(CGPoint)toCoordinate
{
    // Get the cell at the toCoordinate to calculate the hScore
    Node *cell = [self caveCellFromGridCoordinate:toCoordinate];
    
    // It is 10 times more expensive to move through wall cells than floor cells.
    NSUInteger multiplier = cell.nodeType = Wall ? 10 : 1;
    
    return multiplier * (abs(toCoordinate.x - fromCoordinate.x) + abs(toCoordinate.y - fromCoordinate.y));
}

- (NSArray *)adjacentCellsCoordinateForCellCoordinate:(CGPoint)cellCoordinate
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

- (void)createPathBetweenOrigin:(Node *)originCell destination:(Node *)destinationCell
{
    NSMutableArray *openSteps = [NSMutableArray array];
    NSMutableArray *closedSteps = [NSMutableArray array];
    
    [self insertStep:[[AStarPathFinding alloc] initWithPosition:originCell.coordinate] inList:openSteps];
    
    do {
        // Get the lowest F cost step.
        // Because the list is ordered, the first step is always the one with the lowest F cost.
        AStarPathFinding *currentStep = [openSteps firstObject];
        
        // Add the current step to the closed list
        [closedSteps addObject:currentStep];
        
        // Remove it from the open list
        [openSteps removeObjectAtIndex:0];
        
        // If the currentStep is the desired cell coordinate, we are done!
        if (CGPointEqualToPoint(currentStep.position, destinationCell.coordinate)) {
            // Turn the path into floors to connect the caverns
            do {
                if (currentStep.parent != nil) {
                    Node *cell = [self caveCellFromGridCoordinate:currentStep.position];
                    cell.nodeType = Floor;
                }
                currentStep = currentStep.parent; // Go backwards
            } while (currentStep != nil);
            break;
        }
        
        // Get the adjacent cell coordinates of the current step
        NSArray *adjSteps = [self adjacentCellsCoordinateForCellCoordinate:currentStep.position];
        
        for (NSValue *v in adjSteps) {
            AStarPathFinding *step = [[AStarPathFinding alloc] initWithPosition:[v CGPointValue]];
            
            // Check if the step isn't already in the closed set
            if ([closedSteps containsObject:step]) {
                continue; // ignore it
            }
            
            // Compute the cost form the current step to that step
            NSInteger moveCost = [self costToMoveFromStep:currentStep toAdjacentStep:step];
            
            // Check if the step is already in the open list
            NSUInteger index = [openSteps indexOfObject:step];
            
            if (index == NSNotFound) { // Not on the open list, so add it
                
                // Set the current step as the parent
                step.parent = currentStep;
                
                // The G score is equal to the parent G score plus the cost to move from the parent to it
                step.gScore = currentStep.gScore + moveCost;
                
                // Compute the H score, which is the estimated move cost to move from that step
                // to the desired cell coordinate
                step.hScore = [self computeHScoreFromCoordinate:step.position
                                                   toCoordinate:destinationCell.coordinate];
                
                // Adding it with the function which is preserving the list ordered by F score
                [self insertStep:step inList:openSteps];
                
            } else { // Already in the open list
                
                // To retrieve the old one, which has its scores already computed
                step = [openSteps objectAtIndex:index];
                
                // Check to see if the G score for that step is lower if we use the current step to get there
                if ((currentStep.gScore + moveCost) < step.gScore) {
                    
                    // The G score is equal to the parent G score plus the cost to move the parent to it
                    step.gScore = currentStep.gScore + moveCost;
                    
                    // Because the G score has changed, the F score may have changed too.
                    // So to keep the open list ordered we have to remove the step, and re-insert it with
                    // the insert function, which is preserving the list ordered by F score.
                    AStarPathFinding *preservedStep = [[AStarPathFinding alloc] initWithPosition:step.position];
                    
                    // Remove the step from the open list
                    [openSteps removeObjectAtIndex:index];
                    
                    // Re-insert the step to the open list
                    [self insertStep:preservedStep inList:openSteps];
                }
            }
        }
        
    } while ([openSteps count] > 0);
}

- (void)constructPathFromStep:(AStarPathFinding *)step
{
    do {
        if (step.parent != nil) {
            Node *cell = [self caveCellFromGridCoordinate:step.position];
            cell.nodeType = Floor;
        }
        step = step.parent; // Go backwards
    } while (step != nil);
}

- (void) setEntryAndExit
{
    // 1
    NSUInteger mainCavernIndex = [self mainCavernIndex];
    NSArray *mainCavern = (NSArray *)self.caves[mainCavernIndex];
    
    // 2
    NSUInteger mainCavernCount = [mainCavern count];
    Node *entranceCell = (Node *)mainCavern[arc4random() % mainCavernCount];
    
    // 3
    [self caveCellFromGridCoordinate:entranceCell.coordinate].nodeType = Entry;
    _entrance = [self positionForGridCoordinate:entranceCell.coordinate];
    
    Node *exitCell = nil;
    CGFloat distance = 0.0f;
    
    do
    {
        // 4
        exitCell = (Node *)mainCavern[arc4random() % mainCavernCount];
        
        // 5
        NSInteger a = (exitCell.coordinate.x - entranceCell.coordinate.x);
        NSInteger b = (exitCell.coordinate.y - entranceCell.coordinate.y);
        distance = a * a + b * b;
        
    }
    while (distance < self.entryExitMinRange);
    
    // 6
    [self caveCellFromGridCoordinate:exitCell.coordinate].nodeType = Exit;
    _exit = [self positionForGridCoordinate:exitCell.coordinate];
}

- (void)setTreasure
{
    NSUInteger treasureHiddenLimit = 4;
    
    for (NSUInteger x = 0; x < self.mapSize.height; x++) {
        for (NSUInteger y = 0; y < self.mapSize.width; y++) {
            Node *cell = (Node *)self.map[x][y];
            
            if (cell.nodeType == Floor) {
                NSUInteger mooreNeighborWallCount = [self countWallMooreNeighborsFromGridCoordinate:CGPointMake(y, x)];
                
                if (mooreNeighborWallCount > treasureHiddenLimit) {
                    cell.nodeType = Treasure;
                }
            }
        }
    }
}

- (CGPoint)gridCoordinateForPosition:(CGPoint)position
{
    return CGPointMake((position.x / self.tileSize.width), (position.y / self.tileSize.height));
}

- (CGRect)caveCellRectFromGridCoordinate:(CGPoint)coordinate
{
    if ([self isValidGridCoordinate:coordinate]) {
        CGPoint cellPosition = [self positionForGridCoordinate:coordinate];
        
        return CGRectMake(cellPosition.x - (self.tileSize.width / 2),
                          cellPosition.y - (self.tileSize.height / 2),
                          self.tileSize.width,
                          self.tileSize.height);
    }
    return CGRectZero;
}

- (BOOL)isEdgeAtGridCoordinate:(CGPoint)coordinate
{
    return ((NSUInteger)coordinate.x == 0 ||
            (NSUInteger)coordinate.x == (NSUInteger)self.mapSize.width - 1 ||
            (NSUInteger)coordinate.y == 0 ||
            (NSUInteger)coordinate.y == (NSUInteger)self.mapSize.height - 1);
}

@end
