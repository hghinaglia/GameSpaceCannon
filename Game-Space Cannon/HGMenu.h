//
//  HGMenu.h
//  Game-Space Cannon
//
//  Created by Hector Ghinaglia on 7/31/14.
//  Copyright (c) 2014 Hector Ghinaglia. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface HGMenu : SKNode

@property (nonatomic) int score;
@property (nonatomic) int topScore;
@property (nonatomic) BOOL touchable;
@property (nonatomic) BOOL playMusic;

-(void)hide;
-(void)show;

@end
