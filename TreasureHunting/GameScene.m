//
//  MyScene.m
//  TreasureHunting
//
//  Created by Bi Studio on 03/10/14.
//  Copyright (c) 2014 Bi Studio. All rights reserved.
//

#import "GameScene.h"
#import "DPad.h"
#import "Dungeon.h"
#import "Player.h"
#import "Node.h"

// Player movement constant
static const CGFloat kPlayerMovementSpeed = 100.0f;

@interface GameScene ()
@property (assign, nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (strong, nonatomic) SKNode *world;
@property (strong, nonatomic) SKNode *hud;
@property (strong, nonatomic) Player *player;
@property (strong, nonatomic) DPad *dPad;
@property (assign, nonatomic) BOOL isExitingLevel;
@property (strong, nonatomic) Dungeon *cave;
@end

@implementation GameScene

- (id)initWithSize:(CGSize)size
{
    if ((self = [super initWithSize:size])) {
        // Background color
        self.backgroundColor = [SKColor colorWithRed:88.0f/255.0f green:90.0f/255.0f blue:103.0f/255.0f alpha:1.0f];
    
        // World node
        _world = [SKNode node];
        _world.name = @"WORLD";
    
        // Generate new cave
        _cave = [[Dungeon alloc] initWithAtlasNamed:@"tiles" mapSize:CGSizeMake(64.0f, 64.0f)];
        _cave.name = @"CAVE";
        _cave.connectedCave = YES;
        [_cave generateMap];
        [_world addChild:_cave];
    
        // Add Player
        _player = [Player spriteNodeWithTexture:[[SKTextureAtlas atlasNamed:@"tiles"] textureNamed:@"hero_idle_1"]];
        _player.name = @"PLAYER";
        _player.desiredPosition = _cave.entrance;
        [_world addChild:self.player];
    
        // HUD
        _hud = [SKNode node];
        _hud.name = @"HUD";
    
        // Dpad
        _dPad = [[DPad alloc] initWithRect:CGRectMake(0, 0, 64.0f, 64.0f)];
        _dPad.name = @"DPAD";
        _dPad.position = CGPointMake(64.0f / 4.0f, 64.0f / 4.0f);
        _dPad.numberOfDirections = 24;
        _dPad.deadRadius = 8.0f;
        [_hud addChild:self.dPad];
    
        // Add the HUD and World nodes to the scene
        [self addChild:_world];
        [self addChild:_hud];
    
    }
    return self;
}

- (void)update:(CFTimeInterval)currentTime
{
    // Calculate the time since last update
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
  
    self.lastUpdateTimeInterval = currentTime;
  
    if (timeSinceLast > 1) {
        timeSinceLast = 1.0f / 60.0f;
        self.lastUpdateTimeInterval = currentTime;
    }
  
    CGPoint velocity = self.isExitingLevel ? CGPointZero : self.dPad.velocity;
  
    if (velocity.x != 0 && velocity.y != 0) {
        // Calculate the desired position for the player
        self.player.desiredPosition = CGPointMake(self.player.position.x + velocity.x * timeSinceLast * kPlayerMovementSpeed, self.player.position.y + velocity.y * timeSinceLast * kPlayerMovementSpeed);
    
        // Insert code to detect collision between player and walls here
        NSArray *cells = [self getCaveCellsFromRect:self.player.boundingRect];
        
        for (Node *cell in cells) {
            CGPoint repel = [self intersectionRepelDistanceBetweenRect:self.player.boundingRect
                                                               andRect:[self.cave caveCellRectFromGridCoordinate:cell.coordinate]];
            
            self.player.desiredPosition = CGPointMake(self.player.desiredPosition.x + repel.x,
                                                      self.player.desiredPosition.y + repel.y);
        }
        
        // Insert code to detect if player reached exit or found treasure here
        Node *cell = [self.cave caveCellFromGridCoordinate:
                          [self.cave gridCoordinateForPosition:self.player.position]];
        
        switch (cell.nodeType) {
            case Exit:
                [self resolveExit];
                break;
                
            case Treasure:
                [self resolveTreasureInCell:cell];
                break;
                
            default:
                break;
        }
    }
  
    if (velocity.x != 0.0f) {
        self.player.xScale = (velocity.x > 0.0f) ? 1.0f : -1.0f;
    }
  
    // Ensure correct animation is playing
    self.player.playerAnimationID = (velocity.x != 0.0f) ? 1 : 0;
    [self.player resolveAnimationWithID:self.player.playerAnimationID];
  
    // Move the player to the desired position
    self.player.position = self.player.desiredPosition;
  
    // Move "camera" so the player is in the middle of the screen
    self.world.position = CGPointMake(-self.player.position.x + CGRectGetMidX(self.frame),
                                      -self.player.position.y + CGRectGetMidY(self.frame));
}

- (NSArray *)getCaveCellsFromRect:(CGRect)rect
{
    NSMutableArray *array = [NSMutableArray array];
    
    Node *topLeft = [self.cave caveCellFromGridCoordinate:
                         [self.cave gridCoordinateForPosition:rect.origin]];
    
    Node *topRight = [self.cave caveCellFromGridCoordinate:
                          [self.cave gridCoordinateForPosition:CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect))]];
    
    Node *bottomLeft = [self.cave caveCellFromGridCoordinate:
                            [self.cave gridCoordinateForPosition:CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect))]];
    
    Node *bottomRight = [self.cave caveCellFromGridCoordinate:
                             [self.cave gridCoordinateForPosition:CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect))]];
    
    if (topLeft && topLeft.nodeType == Wall) {
        [array addObject:topLeft];
    }
    if (topRight && topRight.nodeType == Wall && ![array containsObject:topRight]) {
        [array addObject:topRight];
    }
    if (bottomLeft && bottomLeft.nodeType == Wall && ![array containsObject:bottomLeft]) {
        [array addObject:bottomLeft];
    }
    if (bottomRight && bottomRight.nodeType == Wall && ![array containsObject:bottomRight]) {
        [array addObject:bottomRight];
    }
    
    return array;
}

- (CGPoint)intersectionRepelDistanceBetweenRect:(CGRect)playerRect andRect:(CGRect)cellRect
{
    if (CGRectIntersectsRect(playerRect, cellRect)) {
        // 1
        NSInteger signX = CGRectGetMaxX(playerRect) > CGRectGetMaxX(cellRect) ? 1 : -1;
        NSInteger signY = CGRectGetMaxY(playerRect) > CGRectGetMaxY(cellRect) ? 1 : -1;
        
        // 2
        CGRect intersectionRect = CGRectIntersection(playerRect, cellRect);
        
        // 3
        if (CGRectGetWidth(intersectionRect) < CGRectGetHeight(intersectionRect)) {
            // If the width is less than the height, resolve the collision horizontally
            return CGPointMake(CGRectGetWidth(intersectionRect) * signX, 0.0f);
        } else if (CGRectGetWidth(intersectionRect) > CGRectGetHeight(intersectionRect)) {
            // If the width is greater than the height, resolve the collision vertically
            return CGPointMake(0.0f, CGRectGetHeight(intersectionRect) * signY);
        } else {
            // If the width and height of the intersection are equal, then resolve collision
            // both horizontally and vertically
            return CGPointMake(CGRectGetWidth(intersectionRect) * signX,
                               CGRectGetHeight(intersectionRect) * signY);
        }
    }
    // 4
    return CGPointZero;
}

- (void)resolveExit
{
    // Disable the joystick to ensure the player cannot move around after reaching the exit
    self.isExitingLevel = YES;
    
    // Create actions to play the sound file for reaching the exit and add a block to transition
    // to the next cave
    SKAction *soundAction = [SKAction playSoundFileNamed:@"fanfare.mp3" waitForCompletion:NO];
    SKAction *blockAction = [SKAction runBlock:^{
        [self.view presentScene:[[GameScene alloc] initWithSize:self.size] transition:[SKTransition
                                                                                     doorsCloseVerticalWithDuration:0.5f]];
    }];
    SKAction *exitAnimAction = [SKAction sequence:@[[SKAction group:@[soundAction]], blockAction]];
    
    // Run the action sequence
    [self.player runAction:exitAnimAction];
}

- (void)resolveTreasureInCell:(Node *)cell
{
    // Make this cell into a floor
    cell.nodeType = Floor;
    
    // Calculate the position of the cell within the cave
    CGPoint cellPosition = CGPointMake(
                                       cell.coordinate.x * self.cave.tileSize.width + self.cave.tileSize.width / 2,
                                       (cell.coordinate.y * self.cave.tileSize.height + self.cave.tileSize.height / 2));
    
    // Get the node at the point of this cell
    SKNode *node = [self.cave nodeAtPoint:cellPosition];
    
    if (node) {
        // Get the treasure child node
        if ([node.name isEqualToString:@"TREASURE"]) {
            node = node.parent;
        }
        
        // Remove the treasure child sprite node
        [node removeAllChildren];
        
        // Play a sound effect for picking up the treasure
        [node runAction:[SKAction playSoundFileNamed:@"treasure.wav" waitForCompletion:NO]];
    }
}
@end
