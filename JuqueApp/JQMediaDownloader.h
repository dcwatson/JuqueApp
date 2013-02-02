//
//  JQMediaDownloader.h
//  JuqueApp
//
//  Created by Daniel Watson on 2/2/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const JQIgnoreRequestHeader;

@interface JQMediaDownloader : NSObject <NSURLConnectionDelegate> {
    // The absolute URL, minus the querystring. Used to uniquely identify a download.
    NSString *requestString;
    // The path the file should be written to once the download is complete.
    NSString *cachePath;
    // In-memory cache of downloaded data; range requests served from this.
    NSMutableData *downloadData;
    // Once the download starts, grab the Content-Length (needed for byte requests like "1024-")
    NSInteger contentLength;
    // Once the download starts, grab the Content-Type.
    NSString *contentType;
    // All pending range requests for this URL.
    NSMutableArray *rangeRequests;
}

+ (JQMediaDownloader *)downloaderWithRequest:(NSURLRequest *)request protocol:(NSURLProtocol *)protocol cachePath:(NSString *)path;

// Creates a new NSURLRequest and starts downloading it.
- (id)initWithRequest:(NSURLRequest *)request protocol:(NSURLProtocol *)protocol cachePath:(NSString *)path;

// Determines whether this current download can serve bytes for the specified request.
- (BOOL)canHandle:(NSURLRequest *)request;

// Called when a second request comes in for a URL that is being downloaded.
- (void)handleRequest:(NSURLRequest *)request protocol:(NSURLProtocol *)protocol;

@end
