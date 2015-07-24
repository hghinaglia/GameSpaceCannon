//
//  HGBall.m
//  Game-Space Cannon
//
//  Created by Hector Ghinaglia on 8/1/14.
//  Copyright (c) 2014 Hector Ghinaglia. All rights reserved.
//

#import "HGBall.h"

@implementation HGBall

-(void)updateTrail
{
    if (self.trail)
    {
        self.trail.position = self.position;
        
    }
}

-(void)removeFromParent
{
    if (self.trail)
    {
        self.trail.particleBirthRate = 0.0;
        
        SKAction *removeTrail = [SKAction sequence:@[[SKAction waitForDuration:self.trail.particleLifetime + self.trail.particleLifetimeRange],
                                                     [SKAction removeFromParent]]];
        [self runAction:removeTrail];
    }        
    
    [super removeFromParent];
}

@end
