//
//  JQProxyURLProtocol.h
//  JuqueApp
//
//  Created by Daniel Watson on 1/25/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JQProxyURLProtocol : NSURLProtocol <NSURLConnectionDelegate> {
    NSURL *cacheURL;
}

@end
