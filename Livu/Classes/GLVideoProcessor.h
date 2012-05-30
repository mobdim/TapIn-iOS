//
//  GLVideoProcessor.m
//  Livu
//
//  Created by Steve on 10/1/2011.
//  Copyright 2010 Steve McFarlin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreVideo/CoreVideo.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#include "esUtil.h"

@interface GLVideoProcessor : NSObject
{
	
	EAGLContext *context, *threadContext;
	CGImageRef	overlayCGImageRef;
	UIImage		*overlayImage;
	GLubyte *textureData;
	
	GLuint directDisplayProgram, thresholdProgram, positionProgram;
	GLuint videoFrameTexture, overlayFrameTexture;
	
	GLubyte *rawPositionPixels;
	
	/* The pixel dimensions of the backbuffer */
	GLint backingWidth, backingHeight;
	NSInteger texWidth, texHeight;
	
	GLfloat overlayVertices[8];
	
	/* OpenGL names for the renderbuffer and framebuffers used to render to this view */
	GLuint viewRenderbuffer, viewFramebuffer;
	
	GLuint videoTexture, overlayTexture;
	GLuint offscreenRenderbuffer, offscreenFramebuffer;
	ESMatrix projectionMatrix, modelviewMatrix, modelviewProjectionMatrix;
}

// Initialization and teardown
- (id)initWithWidth:(int) width andHeight:(int) height usingOverlayImage:(UIImage*) img;
- (BOOL)createFramebuffers;
- (void) setupThreadingContext;

// OpenGL ES 2.0 setup methods
//- (BOOL)loadVertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName forProgram:(GLuint *)programPointer;
- (BOOL)loadVertexShader:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName;
- (BOOL)loadVertexShaderLiteral:(char *)vertexShaderString fragmentShaderLiteral:(char *)fragmentShaderString;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type fromString:(char *)shaderString;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

- (void)processCameraFrame:(CVImageBufferRef)cameraFrame rotationAngle:(GLint) angle adjustAspectRatio:(BOOL)adjust;

@end

