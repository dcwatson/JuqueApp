//
//  JQMediaDownloader.m
//  JuqueApp
//
//  Created by Daniel Watson on 2/2/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import "JQMediaDownloader.h"

NSString *const JQIgnoreRequestHeader = @"X-Juque-Ignore";

@interface RangeRequest : NSObject {
    NSURLProtocol *protocol;
    NSURL *originalURL;
    NSInteger offset, remaining;
    BOOL started, finished;
}

- (id)initWithRequest:(NSURLRequest *)request protocol:(NSURLProtocol *)proto;
- (void)handleData:(NSData *)data contentLength:(NSInteger)contentLength contentType:(NSString *)contentType;
- (void)handleError:(NSError *)error;
- (void)finish;
@end

@implementation RangeRequest

- (id)initWithRequest:(NSURLRequest *)request protocol:(NSURLProtocol *)proto {
    if(self = [super init]) {
        NSString *range = [[[[request allHTTPHeaderFields] objectForKey:@"Range"] componentsSeparatedByString:@"="] objectAtIndex:1];
        NSArray *parts = [range componentsSeparatedByString:@"-"];
        // "0-499": offset=0, remaining=500
        // "1-": offset=1, remaining=-1
        // "1024-2047": offset=1024, remaining=1024
        originalURL = [request URL];
        offset = [[parts objectAtIndex:0] isEqualToString:@""] ? 0 : [[parts objectAtIndex:0] integerValue];
        remaining = [[parts objectAtIndex:1] isEqualToString:@""] ? - 1 : [[parts objectAtIndex:1] integerValue] + 1 - offset;
        protocol = proto;
        started = NO;
        finished = NO;
        NSLog(@"RangeRequest(%d, %d)", offset, remaining);
    }
    return self;
}

- (void)handleData:(NSData *)data contentLength:(NSInteger)contentLength contentType:(NSString *)contentType {
    if(data == nil)
        return;
    if(!started) {
        // If the range request was not capped, set the number of bytes remaining based on the content length.
        if(remaining < 0) {
            remaining = contentLength - offset;
        }
        NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:@{
                                        @"Server": @"Juque/1.0",
                                        @"Content-Type": contentType,
                                        @"Content-Length": [NSString stringWithFormat:@"%d", remaining],
                                        @"Content-Range": [NSString stringWithFormat:@"bytes %d-%d/%d", offset, offset + remaining - 1, contentLength],
                                        @"Accept-Ranges": @"bytes",
                                        @"Connection": @"keep-alive",
                                        }];
        NSLog(@"RangeRequest started: %@ %@", originalURL, headers);
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:originalURL statusCode:206 HTTPVersion:@"HTTP/1.1" headerFields:headers];
        [[protocol client] URLProtocol:protocol didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        started = YES;
    }
    [self sendData:data];
}

- (void)sendData:(NSData *)availableData {
    if(remaining > 0) {
        if([availableData length] > offset) {
            NSUInteger avail = [availableData length] - offset;
            NSUInteger len = MIN(avail, remaining);
            NSData *data = [availableData subdataWithRange:NSMakeRange(offset, len)];
            [[protocol client] URLProtocol:protocol didLoadData:data];
            // Next time, pick up where we left off.
            offset += len;
            remaining -= len;
        }
    }
    if(remaining <= 0) {
        [self finish];
    }
}

- (void)handleError:(NSError *)error {
    [[protocol client] URLProtocol:protocol didFailWithError:error];
}

- (void)finish {
    if(!finished) {
        NSLog(@"RangeRequest finished: %@", originalURL);
        [[protocol client] URLProtocolDidFinishLoading:protocol];
        finished = YES;
    }
}

@end

static NSMutableArray *gDownloaders = nil;

@implementation JQMediaDownloader

+ (JQMediaDownloader *)downloaderWithRequest:(NSURLRequest *)request protocol:(NSURLProtocol *)protocol cachePath:(NSString *)path {
    if(gDownloaders == nil) {
        gDownloaders = [[NSMutableArray alloc] init];
    }
    // First, see if the request is already being downloaded by a downloader that can handle it.
    for(JQMediaDownloader *downloader in gDownloaders) {
        if([downloader canHandle:request]) {
            NSLog(@"FOUND DOWNLOADER");
            [downloader handleRequest:request protocol:protocol];
            return downloader;
        }
    }
    // Otherwise, create a new downloader for the request.
    NSLog(@"CREATING NEW DOWNLOADER");
    JQMediaDownloader *downloader = [[JQMediaDownloader alloc] initWithRequest:request protocol:protocol cachePath:path];
    [gDownloaders addObject:downloader];
    return downloader;
}

- (id)initWithRequest:(NSURLRequest *)request protocol:(NSURLProtocol *)protocol cachePath:(NSString *)path {
    if(self = [super init]) {
        requestString = [[[[request URL] absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0];
        rangeRequests = [[NSMutableArray alloc] init];
        downloadData = nil;
        contentLength = -1;
        cachePath = [path copy];
        
        [self handleRequest:request protocol:protocol];
        
        // Send a new request without a Range header, so we can grab the whole thing and serve range requests ourself.
        NSMutableURLRequest *newRequest = [NSMutableURLRequest requestWithURL:[request URL]];
        [newRequest setValue:@"1" forHTTPHeaderField:JQIgnoreRequestHeader];
        [NSURLConnection connectionWithRequest:newRequest delegate:self];
    }
    return self;
}

- (BOOL)canHandle:(NSURLRequest *)request {
    NSString *rs = [[[[request URL] absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0];
    return [requestString caseInsensitiveCompare:rs] == NSOrderedSame;
}

- (void)handleRequest:(NSURLRequest *)request protocol:(NSURLProtocol *)protocol {
    RangeRequest *range = [[RangeRequest alloc] initWithRequest:request protocol:protocol];
    [rangeRequests addObject:range];
    // In case we've already started downloading, try to serve the range request immediately.
    [range handleData:downloadData contentLength:contentLength contentType:contentType];
}

#pragma mark "NSURLConnection Delegate"

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse, expecting %lld bytes", [response expectedContentLength]);
    if([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *resp = (NSHTTPURLResponse *)response;
        NSLog(@"UPSTREAM headers = %@", [resp allHeaderFields]);
    }
    contentLength = [response expectedContentLength];
    contentType = [response MIMEType];
    NSInteger capacity = contentLength > 0 ? contentLength : 1024 * 1024 * 4;
    downloadData = [NSMutableData dataWithCapacity:capacity];
    for(RangeRequest *range in rangeRequests) {
        // handleData doubles as a way to start the range request response.
        [range handleData:downloadData contentLength:contentLength contentType:contentType];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [downloadData appendData:data];
    for(RangeRequest *range in rangeRequests) {
        [range handleData:downloadData contentLength:contentLength contentType:contentType];
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"download failed: %@", error);
    for(RangeRequest *range in rangeRequests) {
        [range handleError:error];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"download finished: %@", requestString);
    for(RangeRequest *range in rangeRequests) {
        [range handleData:downloadData contentLength:contentLength contentType:contentType];
        [range finish];
    }
    if(downloadData != nil) {
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm createFileAtPath:cachePath contents:downloadData attributes:nil];
        NSLog(@"wrote %d bytes to %@", [downloadData length], cachePath);
        downloadData = nil;
    }
}

@end
