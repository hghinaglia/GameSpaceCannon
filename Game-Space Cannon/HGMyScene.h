//
//  HGMyScene.h
//  Game-Space Cannon
//

//  Copyright (c) 2014 Hector Ghinaglia. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface HGMyScene : SKScene <SKPhysicsContactDelegate>

@property (nonatomic) int ammo;
@property (nonatomic) int score;
@property (nonatomic) int pointValue;
@property (nonatomic) BOOL multiMode;
@property (nonatomic) BOOL gamePaused;

@end
