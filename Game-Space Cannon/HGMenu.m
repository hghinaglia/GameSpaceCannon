//
//  HGMenu.m
//  Game-Space Cannon
//
//  Created by Hector Ghinaglia on 7/31/14.
//  Copyright (c) 2014 Hector Ghinaglia. All rights reserved.
//

#import "HGMenu.h"

@implementation HGMenu
{
    SKLabelNode *_scoreLabel;
    SKLabelNode *_topScoreLabel;
    SKSpriteNode *_title;
    SKSpriteNode *_scoreBoard;
    SKSpriteNode *_playButton;
    SKSpriteNode *_musicOnOffButton;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _title = [SKSpriteNode spriteNodeWithImageNamed:@"Title"];
        _title.position = CGPointMake(0, 140);
        [self addChild:_title];
        
        _scoreBoard = [SKSpriteNode spriteNodeWithImageNamed:@"ScoreBoard"];
        _scoreBoard.position = CGPointMake(0, 70);
        [self addChild:_scoreBoard];
        
        _playButton = [SKSpriteNode spriteNodeWithImageNamed:@"PlayButton"];
        _playButton.name = @"PlayButton";
        _playButton.position = CGPointMake(0, 0);
        [self addChild:_playButton];
        
        _musicOnOffButton = [SKSpriteNode spriteNodeWithImageNamed:@"MusicOnButton"];
        _musicOnOffButton.name = @"MusicOnOffButton";
        _musicOnOffButton.position = CGPointMake(90, 0);
        [_playButton addChild:_musicOnOffButton];
        
        _scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _scoreLabel.fontSize = 30;
        _scoreLabel.position = CGPointMake(-52, -20);
        [_scoreBoard addChild:_scoreLabel];

        _topScoreLabel = [SKLabelNode labelNodeWithFontNamed:@"DIN Alternate"];
        _topScoreLabel.fontSize = 30;
        _topScoreLabel.position = CGPointMake(48, -20);
        [_scoreBoard addChild:_topScoreLabel];
        
        
        [self setTopScore:0];
        [self setScore:0];        
        [self setTouchable:YES];
        [self setPlayMusic:YES];
    }
    return self;
}

-(void)setScore:(int)score
{
    _score = score;
    _scoreLabel.text = [NSString stringWithFormat:@"%d", score];
}

-(void)setTopScore:(int)topScore
{
    _topScore = topScore;
    _topScoreLabel.text = [NSString stringWithFormat:@"%d", topScore];
}

-(void)setPlayMusic:(BOOL)playMusic
{
    _playMusic = playMusic;
    
    if (playMusic)
    {
        _musicOnOffButton.texture = [SKTexture textureWithImageNamed:@"MusicOnButton"];
    }
    else
    {
        _musicOnOffButton.texture = [SKTexture textureWithImageNamed:@"MusicOffbutton"];
    }
}

-(void)show
{
    self.hidden = NO;
    self.touchable = NO;
    
    SKAction *fadeIn = [SKAction fadeInWithDuration:0.5];
    
    _title.position = CGPointMake(0, 280);
    _title.alpha = 0;
    SKAction *animateTitle = [SKAction group:@[[SKAction moveToY:140 duration:0.5], fadeIn]];
    animateTitle.timingMode = SKActionTimingEaseOut;
    [_title runAction:animateTitle];
    
    _scoreBoard.xScale = 4.0;
    _scoreBoard.yScale = 4.0;
    _scoreBoard.alpha = 0;
    SKAction *animateScoreBoard = [SKAction group:@[[SKAction scaleTo:1.0 duration:0.5], fadeIn]];
    animateScoreBoard.timingMode = SKActionTimingEaseOut;
    [_scoreBoard runAction:animateScoreBoard];
    
    _playButton.alpha = 0;
    SKAction *animatePlayButton = [SKAction fadeInWithDuration:2];
    animateScoreBoard.timingMode = SKActionTimingEaseIn;
    [_playButton runAction:animatePlayButton completion:^{
        self.touchable = YES;
    }];
}

-(void)hide
{
    
    self.touchable = NO;
    
    SKAction *animateMenu = [SKAction scaleTo:0.0 duration:0.5];
    animateMenu.timingMode = SKActionTimingEaseIn;
    [self runAction:animateMenu completion:^{
        self.hidden = YES;
        self.xScale = 1.0;
        self.yScale = 1.0;
    }];
}

@end
