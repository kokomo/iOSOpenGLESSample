#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#import "EAGLView.h"

#define USE_DEPTH_BUFFER 1
#define DEGREES_TO_RADIANS(_ANGLE)((_ANGLE)/180.0 * M_PI)

@implementation EAGLView

@synthesize animating;
@synthesize animationFrameInterval;

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder
{
	if((self = [super initWithCoder:coder])) {
		CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
		
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties
		= [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:FALSE],
		   kEAGLDrawablePropertyRetainedBacking,
		   kEAGLColorFormatRGBA8,
		   kEAGLDrawablePropertyColorFormat,
		   nil];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		
		if(!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffer]) {
			[self release];
			return nil;
		}
		
		animating = FALSE;
		displayLinkSupported = FALSE;
		animationFrameInterval = 1;
		displayLink = nil;
		animationTimer = nil;
		
		NSString *reqSysVer = @"3.1";
		NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
		if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending) {
			displayLinkSupported = TRUE;
		}
		
		[self setupView];
		[self drawView];
	}
	return self;
}
//eye 위치, center는 포커스점. up는 카메라 회전. up은 -1, 1만 가능. 
void gluLookAt(GLfloat eyeX, GLfloat eyeY, GLfloat eyeZ, GLfloat centerX, GLfloat centerY, GLfloat centerZ, GLfloat upX, GLfloat upY, GLfloat upZ)
{
		GLfloat m[16];
		GLfloat x[3], y[3], z[3];
		GLfloat mag;
		/* Make rotation matrix */
		/* Z vector */
		z[0] = eyeX - centerX;
		z[1] = eyeY - centerY;
		z[2] = eyeZ - centerZ;
		mag = sqrt(z[0] * z[0] + z[1] * z[1] + z[2] * z[2]);
		if (mag) {           /* mpichler, 19950515 */
			z[0] /= mag;
			z[1] /= mag;
			z[2] /= mag;
		}        
		/* Y vector */
		y[0] = upX;
		y[1] = upY;
		y[2] = upZ;
		/* X vector = Y cross Z */

		x[0] = y[1] * z[2] - y[2] * z[1];
        x[1] = -y[0] * z[2] + y[2] * z[0];
        x[2] = y[0] * z[1] - y[1] * z[0];
		
		/* Recompute Y = Z cross X */
		y[0] = z[1] * x[2] - z[2] * x[1];
        y[1] = -z[0] * x[2] + z[2] * x[0];
        y[2] = z[0] * x[1] - z[1] * x[0];
		
		/* mpichler, 19950515 */
		/* cross product gives area of parallelogram, which is < 1.0 for
		 * non-perpendicular unit-length vectors; so normalize x, y here
		 */
		 
		 mag = sqrt(x[0] * x[0] + x[1] * x[1] + x[2] * x[2]);
		 if (mag) {
		 x[0] /= mag;
		 x[1] /= mag;
		 x[2] /= mag;
		 }        
		 mag = sqrt(y[0] * y[0] + y[1] * y[1] + y[2] * y[2]);
		 if (mag) {
		 y[0] /= mag;
		 y[1] /= mag;
		 y[2] /= mag;
		 }        
		 #define M(row,col)  m[col*4+row]
		 M(0, 0) = x[0];
		 M(0, 1) = x[1];
		 M(0, 2) = x[2];
		 M(0, 3) = 0.0;
		 M(1, 0) = y[0];
		 M(1, 1) = y[1];
		 M(1, 2) = y[2];
		 M(1, 3) = 0.0;
		 M(2, 0) = z[0];
		 M(2, 1) = z[1];
		 M(2, 2) = z[2];
		 M(2, 3) = 0.0;
		 M(3, 0) = 0.0;
		 M(3, 1) = 0.0;
		 M(3, 2) = 0.0;
		 M(3, 3) = 1.0;
		#undef M
		 glMultMatrixf(m);
		 /* Translate Eye to Origin */
		 glTranslatef(-eyeX, -eyeY, -eyeZ);
}

- (void) setupView 
{
	const GLfloat zNear = 1.0, zFar = 100.0, fieldOfView = 45.0;
	GLfloat size;
	
	glEnable(GL_DEPTH_TEST);
	glDepthFunc(GL_LEQUAL);
	
	size = zNear * tanf(DEGREES_TO_RADIANS(fieldOfView) / 2.0);
	CGRect rect = self.bounds;
	
	glViewport(0, 0, rect.size.width, rect.size.height);
	
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	
	glFrustumf(-size, size, -size / (rect.size.width / rect.size.height), size /  (rect.size.width / rect.size.height), zNear, zFar);

	
	// 카메라 위치 없음
	gluLookAt(2.0f, 4.0f, 4.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);
	
	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	
}

- (void)drawView
{
	[EAGLContext setCurrentContext:context];
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glEnableClientState(GL_VERTEX_ARRAY);
	//glEnableClientState(GL_COLOR_ARRAY);
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	GLfloat pointVertices2[] = {
        
		// Define the front face
		-1.0, 1.0, 1.0,             // top left
		-1.0, -1.0, 1.0,            // bottom left
		1.0, -1.0, 1.0,             // bottom right
		1.0, 1.0, 1.0,              // top right
        
		// Top face
		-1.0, 1.0, -1.0,            // top left (at rear)
		-1.0, 1.0, 1.0,             // bottom left (at front)
		1.0, 1.0, 1.0,              // bottom right (at front)
		1.0, 1.0, -1.0,             // top right (at rear)
        
		// Rear face
		1.0, 1.0, -1.0,             // top right (when viewed from front)
		1.0, -1.0, -1.0,            // bottom right
		-1.0, -1.0, -1.0,           // bottom left
		-1.0, 1.0, -1.0,            // top left
        
		// bottom face
		-1.0, -1.0, 1.0,
		-1.0, -1.0, -1.0,
		1.0, -1.0, -1.0,
		1.0, -1.0, 1.0,
        
		// left face
		-1.0, 1.0, -1.0,
		-1.0, 1.0, 1.0,
		-1.0, -1.0, 1.0,
		-1.0, -1.0, -1.0,
        
		// right face
		1.0, 1.0, 1.0,
		1.0, 1.0, -1.0,
		1.0, -1.0, -1.0,
		1.0, -1.0, 1.0
	};
	glVertexPointer(3, GL_FLOAT, 0, pointVertices2);
	
	glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
	glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
	
	glColor4f(0.0f, 1.0f, 0.0f, 1.0f);
	glDrawArrays(GL_TRIANGLE_FAN, 4, 4);
	
	glColor4f(1.0f, 0.0f, 0.0f, 1.0f);
	glDrawArrays(GL_TRIANGLE_FAN, 8, 4);
	
	glColor4f(0.0f, 1.0f, 0.0f, 1.0f);
	glDrawArrays(GL_TRIANGLE_FAN, 12, 4);
	
	glColor4f(0.0f, 0.0f, 1.0f, 1.0f);
	glDrawArrays(GL_TRIANGLE_FAN, 16, 4);
	
	glColor4f(0.0f, 0.0f, 1.0f, 1.0f);
	glDrawArrays(GL_TRIANGLE_FAN, 20, 4);
	
	
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	[self checkGLError:NO];
}

- (void)layoutSubviews
{
	[EAGLContext setCurrentContext:context];
	[self destroyFramebuffer];
	[self createFramebuffer];
	[self drawView];
}

- (BOOL)createFramebuffer
{
	glGenFramebuffersOES(1, &viewFramebuffer);
	glGenRenderbuffersOES(1, &viewRenderbuffer);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
	[context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(id<EAGLDrawable>)self.layer];
	glFramebufferRenderbufferOES(
								 GL_FRAMEBUFFER_OES,
								 GL_COLOR_ATTACHMENT0_OES,
								 GL_RENDERBUFFER_OES,
								 viewRenderbuffer);
	
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
	glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
	
	if(USE_DEPTH_BUFFER) {
		glGenRenderbuffersOES(1, &depthRenderbuffer);
		glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
		glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
		glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
	}
	
	if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
		return NO;
	}
	
	return YES;
}

- (void)destroyFramebuffer
{
	glDeleteFramebuffersOES(1, &viewFramebuffer);
	viewFramebuffer = 0;
	glDeleteRenderbuffersOES(1, &viewRenderbuffer);
	viewRenderbuffer = 0;
	
	if (depthRenderbuffer) {
		glDeleteRenderbuffersOES(1, &depthRenderbuffer);
		depthRenderbuffer = 0;
	}
}

- (NSInteger) animationFrameInterval
{
	return animationFrameInterval;
}

- (void) setAnimationFrameInterval:(NSInteger)frameInterval
{
	if (frameInterval >= 1)
	{
		animationFrameInterval = frameInterval;
		
		if (animating)
		{
			[self stopAnimation];
			[self startAnimation];
		}
	}
}

- (void) startAnimation
{
	if (!animating)
	{
		if (displayLinkSupported)
		{
			displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView)];
			[displayLink setFrameInterval:animationFrameInterval];
			[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		} else { 
			animationTimer
			= [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * animationFrameInterval) 
											   target:self
											 selector:@selector(drawView)
											 userInfo:nil
											  repeats:TRUE];
		}
		animating = TRUE;
	}
}

- (void)stopAnimation
{
	if (animating)
	{
		if (displayLinkSupported)
		{
			[displayLink invalidate];
			displayLink = nil;
		} else {
			[animationTimer invalidate];
			animationTimer = nil;
		}
		
		animating = FALSE;
	}
}

- (void)checkGLError:(BOOL)visibleCheck {
    GLenum error = glGetError();
    
    switch (error) {
        case GL_INVALID_ENUM:
            NSLog(@"GL Error: Enum argument is out of range");
            break;
        case GL_INVALID_VALUE:
            NSLog(@"GL Error: Numeric value is out of range");
            break;
        case GL_INVALID_OPERATION:
            NSLog(@"GL Error: Operation illegal in current state");
            break;
        case GL_STACK_OVERFLOW:
            NSLog(@"GL Error: Command would cause a stack overflow");
            break;
        case GL_STACK_UNDERFLOW:
            NSLog(@"GL Error: Command would cause a stack underflow");
            break;
        case GL_OUT_OF_MEMORY:
            NSLog(@"GL Error: Not enough memory to execute command");
            break;
        case GL_NO_ERROR:
            if (visibleCheck) {
                NSLog(@"No GL Error");
            }
            break;
        default:
            NSLog(@"Unknown GL Error");
            break;
    }
}

- (void)dealloc
{
	if([EAGLContext currentContext] == context) {
		[EAGLContext setCurrentContext:nil];
	}
	
	[context release];
	context = nil;
	
	[super dealloc];
}

@end

