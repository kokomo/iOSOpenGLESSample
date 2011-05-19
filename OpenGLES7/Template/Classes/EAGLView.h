//
//  EAGLView.h
//  Template
//
//  Created by zziuni on 11. 5. 18..
//  Copyright 2011 zziuni. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface EAGLView : UIView {
@private
	
	GLint backingWidth;
	GLint backingHeight;
	
	EAGLContext *context;
	
	GLuint viewRenderbuffer, viewFramebuffer;
	GLuint depthRenderbuffer;
	
	BOOL animating;
	
	NSTimer *animationTimer;
	NSInteger animationFrameInterval;
	
	id displayLink;
	BOOL displayLinkSupported;
	
	GLfloat rota;

}

@property (readonly, nonatomic, getter=isAnimation) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

-(void) startAnimation;
-(void) stopAnimation;
-(void) drawView;

-(BOOL) createFramebuffer;
-(void) desprotyFramebuffer;

-(void) checkGLError:(BOOL) visibleCheck;

@end
