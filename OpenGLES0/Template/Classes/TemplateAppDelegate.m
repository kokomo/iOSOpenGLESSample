//
//  TemplateAppDelegate.m
//  Template
//
//  Created by zziuni on 11. 5. 18..
//  Copyright 2011 zziuni. All rights reserved.
//

#import "TemplateAppDelegate.h"
#import "EAGLView.h"

@implementation TemplateAppDelegate

@synthesize window;
@synthesize glView;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    [glView startAnimation];
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
	[glView stopAnimation];
}


- (void)applicationDidEnterBackground:(UIApplication *)application {

}


- (void)applicationWillEnterForeground:(UIApplication *)application {

}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	[glView startAnimation];
}


- (void)applicationWillTerminate:(UIApplication *)application {
	[glView stopAnimation];
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {

}


- (void)dealloc {
    [window release];
	[glView release];
    [super dealloc];
}


@end
