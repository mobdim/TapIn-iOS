//
//  UIHTTPImageView.h
//  TapIn
//
//  Created by Vu Tran on 8/9/12.
//  Copyright (c) 2012 Vu Tran. All rights reserved.
//

#import "ASIHTTPRequest.h"

@interface UIHTTPImageView : UIImageView {
    ASIHTTPRequest *request;
}

- (void)setImageWithURL:(NSURL *)url placeholderImage:(UIImage *)placeholder;

@end