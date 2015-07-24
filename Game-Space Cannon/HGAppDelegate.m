//
//  HGAppDelegate.m
//  Game-Space Cannon
//
//  Created by Hector Ghinaglia on 7/30/14.
//  Copyright (c) 2014 Hector Ghinaglia. All rights reserved.
//

#import "HGAppDelegate.h"
#import <SpriteKit/SpriteKit.h>
#import "HGMyScene.h"

@implementation HGAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    /* PAUSANDO EL JUEGO CUANDO SALIMOS DE LA APP */
    
    // obtenemos la instancia del scene
    SKView *view = (SKView *)self.window.rootViewController.view;
    // buscamos la propiedad gamePaused del scene y lo ponemos en YES
    ((HGMyScene *)view.scene).gamePaused = YES;
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end