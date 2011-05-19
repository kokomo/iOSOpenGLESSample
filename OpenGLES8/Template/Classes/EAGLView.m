//
//  EAGLView.m
//  Template
//
//  Created by zziuni on 11. 5. 18..
//  Copyright 2011 zziuni. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"


@implementation EAGLView


@synthesize animating;
@synthesize animationFrameInterval;



#pragma mark class Method
/*
 overwritting method
 UIView - layer - Context (추상화된 화상) - buffers
				CALayer (core animation)
				CAEAGLLayer (Open GL)
*/
+(Class) layerClass{
	return [CAEAGLLayer class];
}

#pragma mark initializing
/*
 overwritting
 CAEAGLLayer initializing
 Context
 */
-(id) initWithCoder:(NSCoder *)coder{
		if ( (self = [super initWithCoder:coder]) ) {
			CAEAGLLayer *eaglLayer = (CAEAGLLayer *) self.layer;
			
			eaglLayer.opaque = YES;
			eaglLayer.drawableProperties = 
			[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE],
			 kEAGLDrawablePropertyRetainedBacking,
			 kEAGLColorFormatRGBA8,
			 kEAGLDrawablePropertyColorFormat,
			 nil];
			
			context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
			
			if (!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffer]) {
				[self release];
				return nil;
			}
			
			animating = FALSE;
			displayLinkSupported = FALSE;
			animationFrameInterval = 1;
			displayLink = nil,
			animationTimer = nil;
			
			NSString *reqSysVer = @"3.1";
			NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
			if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
				displayLinkSupported = TRUE;
			}
			[self drawView];
		}
	
	return self;
}

#pragma mark user method


-(void) drawView{
	[EAGLContext setCurrentContext:context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	// viewport
	CGRect rect = self.bounds;
	glViewport(0, 0, rect.size.width, rect.size.height);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	
	//projection
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	//background color
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	//배경색을 통해서 컬러버퍼와 깊이 버퍼 초기화
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	
	GLfloat pointVertices[] = {
		-0.5f, 0.0f, 0.0f,
		0.0f, -0.5f, 0.0f,
		0.0f, 0.5f, 0.0f,
		0.5f, 0.0f, 0.0f,
	};
	
	GLfloat colorVertices[] = {
		1.0f, 1.0f, 0.0f, 1.0f,
		1.0f, 0.0f, 1.0f, 1.0f,
		0.0f, 1.0f, 1.0f, 1.0f,
		1.0f, 0.0f, 0.0f, 1.0f,
	};
	
	glVertexPointer(3, GL_FLOAT, 0, pointVertices);
	glColorPointer(4, GL_FLOAT, 0, colorVertices);
	glTranslatef(-0.5f, 0.0f, 0.0f);
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glTranslatef(1.0f, 0.0f, 0.0f);
	
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	
	glBindFramebufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	[self checkGLError:NO];
}

-(void) layoutSubviews{
	[EAGLContext setCurrentContext:context];
	[self desprotyFramebuffer];
	[self createFramebuffer];
	[self drawView];
}

#pragma mark buffers
/*
 Frame buffer
 Render buffer
 ? buffer
 */
-(BOOL) createFramebuffer{
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	return YES;
}

-(void) desprotyFramebuffer{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if (depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer =0;
	}
}

-(NSInteger) animationFrameInterval{
	return animationFrameInterval;
}

-(void) setAnimationFrameInterval:(NSInteger)frameInterval {
		if (frameInterval >= 1) {
			animationFrameInterval = frameInterval;
			
			if (animating) {
				[self stopAnimation];
				[self startAnimation];
			}
		}
}

#pragma mark stop/start Animation

-(void) startAnimation{
	if(!animating){
			if (displayLinkSupported) {
				displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView)];
				[displayLink setFrameInterval:animationFrameInterval];
				[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
			}else {
				animationTimer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0/60.0) * animationFrameInterval)
																  target:self
																selector:@selector(drawView)
																userInfo:nil
																 repeats:TRUE];
			}
		animating = TRUE;

	}
}	

-(void) stopAnimation{
		if (animating) {
			if (displayLinkSupported) {
				[displayLink invalidate];
				displayLink = nil;
			}else {
				[animationTimer invalidate];
				animationTimer = nil;
			}
			animating = FALSE;

		}
}

#pragma mark system 

-(void) checkGLError:(BOOL)visibleCheck{
	GLenum error = glGetError();
	
	switch (error) {
		case GL_INVALID_ENUM:
			NSLog(@"GL Error:Enum argument is out of range.");
			break;
		case GL_INVALID_VALUE:
			NSLog(@"GL Error:Numeric value is out of range.");
			break;
		case GL_INVALID_OPERATION:
			NSLog(@"GL Error:Operation illegal in current state");
			break;
		case GL_STACK_OVERFLOW:
			NSLog(@"GL Error:Command would cause a strack overflow");
			break;
		case GL_STACK_UNDERFLOW:
			NSLog(@"GL Error:Command would cause a stack underflow");
			break;
		case GL_OUT_OF_MEMORY:
			NSLog(@"GL Error:Not enough memory to execute command");
			break;
		case GL_NO_ERROR:
			if (visibleCheck) {
				NSLog(@"No GL Error");	
			}
			break;
		default:
			NSLog(@"Unkown GL Error");
			break;
	}
}

-(void) dealloc{
		if ([EAGLContext currentContext] == context) {
			[EAGLContext setCurrentContext:nil];
		}
	[context release];
	context = nil;
	
	[super dealloc];
}

@end
