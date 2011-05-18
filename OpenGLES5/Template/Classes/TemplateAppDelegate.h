//
//  TemplateAppDelegate.h
//  Template
//
//  Created by zziuni on 11. 5. 18..
//  Copyright 2011 zziuni. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EAGLView.h"

@interface TemplateAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	EAGLView *glView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

@end

