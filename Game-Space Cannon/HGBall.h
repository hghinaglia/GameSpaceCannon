//
//  HGBall.h
//  Game-Space Cannon
//
//  Created by Hector Ghinaglia on 8/1/14.
//  Copyright (c) 2014 Hector Ghinaglia. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface HGBall : SKSpriteNode

@property (nonatomic) SKEmitterNode *trail;
@property (nonatomic) int bounces;

-(void)updateTrail;

@end
