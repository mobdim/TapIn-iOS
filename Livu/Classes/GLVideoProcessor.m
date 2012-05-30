//
//  GLVideoProcessor.h
//  Livu
//
//  Created by Steve on 10/1/2011.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import "GLVideoProcessor.h"


enum {
    UNIFORM_VIDEOFRAME,
	UNIFORM_INPUTCOLOR,
	UNIFORM_THRESHOLD,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTUREPOSITON,
    NUM_ATTRIBUTES
};

static const GLfloat squareVertices[] = {
	-1.0f, -1.0f,
	1.0f, -1.0f,
	-1.0f,  1.0f,
	1.0f,  1.0f,
};

static const GLfloat textureVertices[] = {
	0.0f,  1.0f,
	0.0f,  0.0f,
	1.0f, 1.0f,
	1.0f, 0.0f,
};

static const GLfloat overlayTextureVertices[] = {
	0.0f,  0.0f,
	1.0f, 0.0f,
	0.0f,  1.0f,
	1.0f, 1.0f,
};


@interface GLVideoProcessor () 
- (BOOL)createFramebuffers;
- (void) destroyFramebuffer;
@end

@implementation GLVideoProcessor


#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithWidth:(int) width andHeight:(int) height usingOverlayImage:(UIImage*) img {
    if ((self = [super init])) {
		backingWidth = width; backingHeight = height;
		rawPositionPixels = (GLubyte *) calloc(backingWidth * backingHeight * 4, sizeof(GLubyte));	
		
		overlayImage = [img retain];
		
		context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
		
		if (!context || ![EAGLContext setCurrentContext:context] || ![self createFramebuffers]) {
			NSLog(@"Could not create GL context and frame buffers");
			[self dealloc];
			return nil;
		}
		
    }
    return self;
}

- (void)dealloc {
	free(rawPositionPixels);
	[self destroyFramebuffer];
	glDeleteTextures(1, &overlayTexture);
	[super dealloc];
}

- (void) setupThreadingContext {
	EAGLSharegroup* group = context.sharegroup;
    if (!group)
    {
		//NSLog(@"Could not get sharegroup from the main context");
    }
    threadContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1 sharegroup:group];
    if (!threadContext || ![EAGLContext setCurrentContext:threadContext]) {
		//NSLog(@"Could not create WorkingContext");
    }
}

#pragma mark -
#pragma mark OpenGL ES 2.0 rendering methods

- (void)destroyFramebuffer;
{	
	if (viewFramebuffer) {
		glDeleteFramebuffers(1, &viewFramebuffer);
		viewFramebuffer = 0;
	}
	
	if (viewRenderbuffer) {
		glDeleteRenderbuffers(1, &viewRenderbuffer);
		viewRenderbuffer = 0;
	}
}



- (BOOL)createFramebuffers {	
	glEnable(GL_TEXTURE_2D);
	glDisable(GL_DEPTH_TEST);
	
	
	// Offscreen position framebuffer object
	glGenFramebuffers(1, &offscreenFramebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, offscreenFramebuffer);
	
	glGenRenderbuffers(1, &offscreenRenderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, offscreenRenderbuffer);
	
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, backingWidth, backingHeight);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, offscreenRenderbuffer);	
    
	
	// Offscreen position framebuffer texture target
	glGenTextures(1, &videoTexture);
    glBindTexture(GL_TEXTURE_2D, videoTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);	
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, backingWidth, backingHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, videoTexture, 0);
	
	overlayCGImageRef = overlayImage.CGImage;
	
	texWidth = CGImageGetWidth(overlayCGImageRef);
	texHeight = CGImageGetHeight(overlayCGImageRef);
	
	//	static const GLfloat overlayVertices[] = {
	//		0.2375f, 0.316f,
	//		1.0f, 0.316f,
	//		0.2375f,  1.0f,
	//		1.0f,  1.0f,
	//	};
	
	GLfloat widthRatio = (GLfloat) texWidth / (GLfloat) backingWidth;
	GLfloat heightRatio = (GLfloat) texHeight / (GLfloat) backingHeight;
	
	overlayVertices[0] = widthRatio;
	overlayVertices[1] = heightRatio;
	overlayVertices[2] = 1.0f;
	overlayVertices[3] = heightRatio;
	overlayVertices[4] = widthRatio;
	overlayVertices[5] = 1.0f;
	overlayVertices[6] = 1.0f;
	overlayVertices[7] = 1.0f;
	
	//NSLog(@"Texture Width %d, Texture Height %d", texWidth, texHeight);
	
	textureData = (GLubyte *)malloc(texWidth * texHeight * 4);
	
	CGContextRef textureContext = CGBitmapContextCreate(textureData, texWidth, texHeight, 8, texWidth * 4, CGImageGetColorSpace(overlayCGImageRef), kCGImageAlphaPremultipliedLast);
	
	//CGContextSetBlendMode(textureContext, kCGBlendModeCopy);
	CGContextDrawImage(textureContext, CGRectMake(0.0, 0.0, (float)texWidth, (float)texHeight), overlayCGImageRef);
	
	CGContextRelease(textureContext);
	
	
	// Create a new texture from the camera frame data, display that using the shaders
	glGenTextures(1, &overlayTexture);
	glBindTexture(GL_TEXTURE_2D, overlayTexture);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	// This is necessary for non-power-of-two textures
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	// Using BGRA extension to pull in video frame data directly
	//glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, texWidth, texHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, textureData);
	
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
		NSLog(@"Incomplete FBO: %d", status);
        //exit(1);
		return NO;
    }
	
	return YES;
}

#pragma mark -
#pragma mark OpenGL ES 2.0 setup methods

- (BOOL)loadVertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName {
    GLuint vertexShader, fragShader;
	
    NSString *vertShaderPathname, *fragShaderPathname;
    
	GLuint *programPointer = &directDisplayProgram;
	
    // Create shader program.
    *programPointer = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:vertexShaderName ofType:@"vsh"];
    if (![self compileShader:&vertexShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
		//NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:fragmentShaderName ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
		//NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(*programPointer, vertexShader);
    
    // Attach fragment shader to program.
    glAttachShader(*programPointer, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(*programPointer, ATTRIB_VERTEX, "position");
    glBindAttribLocation(*programPointer, ATTRIB_TEXTUREPOSITON, "inputTextureCoordinate");
    
    // Link program.
    if (![self linkProgram:*programPointer]) {
		//NSLog(@"Failed to link program: %d", *programPointer);
        
        if (vertexShader) {
            glDeleteShader(vertexShader);
            vertexShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (*programPointer) {
            glDeleteProgram(*programPointer);
            *programPointer = 0;
        }
        
        return FALSE;
    }
    
	// Get uniform locations.
    uniforms[UNIFORM_VIDEOFRAME] = glGetUniformLocation(*programPointer, "videoFrame");
    //uniforms[UNIFORM_INPUTCOLOR] = glGetUniformLocation(*programPointer, "inputColor");
    //uniforms[UNIFORM_THRESHOLD] = glGetUniformLocation(*programPointer, "threshold");
    
    
	glUseProgram(directDisplayProgram);
	
	
    // Release vertex and fragment shaders.
    if (vertexShader) {
        glDeleteShader(vertexShader);
	}
    if (fragShader) {
        glDeleteShader(fragShader);		
	}
    
    return TRUE;
}

- (BOOL)loadVertexShaderLiteral:(char *)vertexShaderString fragmentShaderLiteral:(char *)fragmentShaderString {
    GLuint vertexShader, fragShader;
	
	GLuint *programPointer = &directDisplayProgram;
	
    // Create shader program.
    *programPointer = glCreateProgram();
    
    // Create and compile vertex shader.
    if (![self compileShader:&vertexShader type:GL_VERTEX_SHADER fromString:vertexShaderString]) {
		//NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER fromString:fragmentShaderString]) {
		//NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(*programPointer, vertexShader);
    
    // Attach fragment shader to program.
    glAttachShader(*programPointer, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(*programPointer, ATTRIB_VERTEX, "position");
    glBindAttribLocation(*programPointer, ATTRIB_TEXTUREPOSITON, "inputTextureCoordinate");
    
    // Link program.
    if (![self linkProgram:*programPointer]) {
		//NSLog(@"Failed to link program: %d", *programPointer);
        
        if (vertexShader) {
            glDeleteShader(vertexShader);
            vertexShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (*programPointer) {
            glDeleteProgram(*programPointer);
            *programPointer = 0;
        }
        
        return FALSE;
    }
    
	// Get uniform locations.
    uniforms[UNIFORM_VIDEOFRAME] = glGetUniformLocation(*programPointer, "videoFrame");
    //uniforms[UNIFORM_INPUTCOLOR] = glGetUniformLocation(*programPointer, "inputColor");
    //uniforms[UNIFORM_THRESHOLD] = glGetUniformLocation(*programPointer, "threshold");
    
    
	glUseProgram(directDisplayProgram);
	
	
    // Release vertex and fragment shaders.
    if (vertexShader) {
        glDeleteShader(vertexShader);
	}
    if (fragShader) {
        glDeleteShader(fragShader);		
	}
    
    return TRUE;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
		//NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
		NSLog(@"Here %d", logLength);
        GLchar *log = (GLchar *)malloc(2048);
        glGetShaderInfoLog(*shader, 2048, &logLength, log);
		//NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type fromString:(char *)shaderString
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithCString:shaderString encoding:NSUTF8StringEncoding] UTF8String];
    if (!source) {
		//NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
		NSLog(@"Here %d", logLength);
        GLchar *log = (GLchar *)malloc(2048);
        glGetShaderInfoLog(*shader, 2048, &logLength, log);
		//NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog {
    GLint status;
    
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(2048);
        glGetProgramInfoLog(prog, 2048, &logLength, log);
		//NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
		//NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return FALSE;
    
    return TRUE;
}


#pragma mark -
#pragma mark ColorTrackingCameraDelegate methods


- (void)processCameraFrame:(CVImageBufferRef)cameraFrame rotationAngle:(GLint) angle adjustAspectRatio:(BOOL) doAdjust
{
	
	//We need to get this on the capture queue. This can create a dead lock on the main queue.
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		CVPixelBufferLockBaseAddress(cameraFrame, 0);
		int bufferHeight = CVPixelBufferGetHeight(cameraFrame);
		int bufferWidth = CVPixelBufferGetWidth(cameraFrame);
		
		
		// Create a new texture from the camera frame data, display that using the shaders
		glGenTextures(1, &videoFrameTexture);
		glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		// This is necessary for non-power-of-two textures
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
		// Using BGRA extension to pull in video frame data directly
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
		
        esMatrixLoadIdentity( &projectionMatrix );
        //esOrtho(ESMatrix *result, float left, float right, float bottom, float top, float nearZ, float farZ)
        if (!doAdjust) {
            //double aspectRatio = (double) bufferHeight / (double) bufferWidth;
            double aspectRatio = (double) bufferWidth / (double) bufferHeight;
            aspectRatio /= 2.0;
            esOrtho(&projectionMatrix, -1.0, 1.0, -1.0 * aspectRatio, 1.0 * aspectRatio, -1.0, 1.0);            
            //esOrtho(&projectionMatrix, -1.0 * aspectRatio, 1.0 * aspectRatio, -1.0, 1.0, -1.0, 1.0);            
        } else {
            esOrtho(&projectionMatrix, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0);            
        }
        // generate a model view
		esMatrixLoadIdentity(&modelviewMatrix);
		esRotate(&modelviewMatrix, angle, 0, 0, -1);
        // compute the final MVP
		esMatrixMultiply(&modelviewProjectionMatrix, &modelviewMatrix, &projectionMatrix);
		
		glBindFramebuffer(GL_FRAMEBUFFER, offscreenFramebuffer);
		glViewport(0, 0, backingWidth, backingHeight);
		
		glClearColor(1.0, 0, 0, 0);
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );   
		
		glUseProgram(directDisplayProgram);
		
		glActiveTexture(GL_TEXTURE0);
		glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
		
		GLint uMVPIndex  = glGetUniformLocation(directDisplayProgram, "uMvp");
		glUniformMatrix4fv( uMVPIndex, 1, GL_FALSE, (GLfloat*) &modelviewProjectionMatrix.m[0][0] );
		
		glUniform1i(uniforms[UNIFORM_VIDEOFRAME], 0);	
		
		// Update attribute values.
		glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
		glEnableVertexAttribArray(ATTRIB_VERTEX);
		glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
		glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glReadPixels(0, 0, backingWidth, backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
		glDeleteTextures(1, &videoFrameTexture);
		
		/*		
		 esMatrixLoadIdentity( &projectionMatrix );
		 esOrtho(&projectionMatrix, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
		 // generate a model view
		 esMatrixLoadIdentity(&modelviewMatrix);
		 //esRotate(&modelviewMatrix, 90, 0, 0, -1);
		 // compute the final MVP
		 esMatrixMultiply(&modelviewProjectionMatrix, &modelviewMatrix, &projectionMatrix);
		 
		 glUseProgram(directDisplayProgram);
		 
		 glActiveTexture(GL_TEXTURE0);
		 glBindTexture(GL_TEXTURE_2D, overlayTexture);
		 
		 uMVPIndex  = glGetUniformLocation(directDisplayProgram, "uMvp");
		 //GLint uTextureIndex  = glGetUniformLocation(directDisplayProgram, "textureImg");
		 glUniformMatrix4fv( uMVPIndex, 1, GL_FALSE, (GLfloat*) &modelviewProjectionMatrix.m[0][0] );
		 //glUniform1i(uTextureIndex, 0); 
		 
		 
		 glUniform1i(uniforms[UNIFORM_VIDEOFRAME], 0);	
		 
		 // Update attribute values.
		 glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, overlayVertices);
		 glEnableVertexAttribArray(ATTRIB_VERTEX);
		 glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, overlayTextureVertices);
		 glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
		 
		 glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		 
		 
		 //glReadPixels(0, 0, FBO_WIDTH, FBO_HEIGHT, GL_RGBA, GL_UNSIGNED_BYTE, rawPositionPixels);
		 glReadPixels(0, 0, backingWidth, backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
		 
		 esMatrixLoadIdentity(&projectionMatrix);
		 esMatrixLoadIdentity(&modelviewMatrix);
		 esMatrixLoadIdentity(&modelviewProjectionMatrix);
		 
		 glDeleteTextures(1, &videoFrameTexture);
		 //glDeleteTextures(1, &overlayTexture);
		 */
		
		CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
		
	});
}


@end




//- (void)processFrontCameraFrame:(CVImageBufferRef)cameraFrame;
//{
//	
//	//We need to get this on the capture queue. This can create a dead lock on the main queue.
//	
//	dispatch_sync(dispatch_get_main_queue(), ^{
//		CVPixelBufferLockBaseAddress(cameraFrame, 0);
//		int bufferHeight = CVPixelBufferGetHeight(cameraFrame);
//		int bufferWidth = CVPixelBufferGetWidth(cameraFrame);
//		
//		
//		// Create a new texture from the camera frame data, display that using the shaders
//		glGenTextures(1, &videoFrameTexture);
//		glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//		// This is necessary for non-power-of-two textures
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//		
//		// Using BGRA extension to pull in video frame data directly
//		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferWidth, bufferHeight, 0, GL_BGRA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
//		
//		
//		esMatrixLoadIdentity( &projectionMatrix );
//		esOrtho(&projectionMatrix, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
//		// generate a model view
//		esMatrixLoadIdentity(&modelviewMatrix);
//		esRotate(&modelviewMatrix, 90, 0, 0, -1);
//		// compute the final MVP
//		esMatrixMultiply(&modelviewProjectionMatrix, &modelviewMatrix, &projectionMatrix);
//		
//		glBindFramebuffer(GL_FRAMEBUFFER, offscreenFramebuffer);
//		glViewport(0, 0, backingWidth, backingHeight);
//		
//		glClearColor(1.0, 0, 0, 0);
//		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );   
//		//glEnable(GL_TEXTURE_2D);
//		
//		glUseProgram(directDisplayProgram);
//		
//		glActiveTexture(GL_TEXTURE0);
//		glBindTexture(GL_TEXTURE_2D, videoFrameTexture);
//		
//		GLint uMVPIndex  = glGetUniformLocation(directDisplayProgram, "uMvp");
//		//GLint uTextureIndex  = glGetUniformLocation(directDisplayProgram, "textureImg");
//		glUniformMatrix4fv( uMVPIndex, 1, GL_FALSE, (GLfloat*) &modelviewProjectionMatrix.m[0][0] );
//		//glUniform1i(uTextureIndex, 0); 
//		
//		
//		glUniform1i(uniforms[UNIFORM_VIDEOFRAME], 0);	
//		//glUniform4f(uniforms[UNIFORM_INPUTCOLOR], thresholdColor[0], thresholdColor[1], thresholdColor[2], 1.0f);
//		//glUniform1f(uniforms[UNIFORM_THRESHOLD], thresholdSensitivity);
//		
//		// Update attribute values.
//		glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, squareVertices);
//		glEnableVertexAttribArray(ATTRIB_VERTEX);
//		glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, textureVertices);
//		glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
//		
//		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//		
//		
//		
//		esMatrixLoadIdentity( &projectionMatrix );
//		esOrtho(&projectionMatrix, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
//		// generate a model view
//		esMatrixLoadIdentity(&modelviewMatrix);
//		//esRotate(&modelviewMatrix, 90, 0, 0, -1);
//		// compute the final MVP
//		esMatrixMultiply(&modelviewProjectionMatrix, &modelviewMatrix, &projectionMatrix);
//		
//		glUseProgram(directDisplayProgram);
//		
//		glActiveTexture(GL_TEXTURE0);
//		glBindTexture(GL_TEXTURE_2D, overlayTexture);
//		
//		uMVPIndex  = glGetUniformLocation(directDisplayProgram, "uMvp");
//		//GLint uTextureIndex  = glGetUniformLocation(directDisplayProgram, "textureImg");
//		glUniformMatrix4fv( uMVPIndex, 1, GL_FALSE, (GLfloat*) &modelviewProjectionMatrix.m[0][0] );
//		//glUniform1i(uTextureIndex, 0); 
//		
//		
//		glUniform1i(uniforms[UNIFORM_VIDEOFRAME], 0);	
//		//glUniform4f(uniforms[UNIFORM_INPUTCOLOR], thresholdColor[0], thresholdColor[1], thresholdColor[2], 1.0f);
//		//glUniform1f(uniforms[UNIFORM_THRESHOLD], thresholdSensitivity);
//		
//		
//		// Update attribute values.
//		glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, overlayVertices);
//		glEnableVertexAttribArray(ATTRIB_VERTEX);
//		glVertexAttribPointer(ATTRIB_TEXTUREPOSITON, 2, GL_FLOAT, 0, 0, overlayTextureVertices);
//		glEnableVertexAttribArray(ATTRIB_TEXTUREPOSITON);
//		
//		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
//		
//		
//		
//		//glReadPixels(0, 0, FBO_WIDTH, FBO_HEIGHT, GL_RGBA, GL_UNSIGNED_BYTE, rawPositionPixels);
//		glReadPixels(0, 0, backingWidth, backingHeight, GL_RGBA, GL_UNSIGNED_BYTE, CVPixelBufferGetBaseAddress(cameraFrame));
//		
//		//GLenum err = glGetError();
//		//NSLog(@"GL Error: %d", err);
//		
//		
//		esMatrixLoadIdentity(&projectionMatrix);
//		esMatrixLoadIdentity(&modelviewMatrix);
//		esMatrixLoadIdentity(&modelviewProjectionMatrix);
//		
//		glDeleteTextures(1, &videoFrameTexture);
//		//glDeleteTextures(1, &overlayTexture);
//		
//		CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
//		
//	});
//}
