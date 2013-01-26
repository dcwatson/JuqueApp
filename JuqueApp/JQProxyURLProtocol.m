//
//  JQProxyURLProtocol.m
//  JuqueApp
//
//  Created by Daniel Watson on 1/25/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import "JQProxyURLProtocol.h"
#import <CommonCrypto/CommonDigest.h>

@implementation JQProxyURLProtocol

+ (NSString *)md5:(NSString *)source {
    const char *ptr = [source UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", md5Buffer[i]];
    return output;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)theRequest {
    NSLog(@"%@ received %@ with URL %@", self, NSStringFromSelector(_cmd), [[theRequest URL] absoluteString]);
    //NSLog(@"headers = %@", [theRequest allHTTPHeaderFields]);
    return [[[theRequest URL] fragment] isEqualToString:@"juque"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    return request;
}

- (void)startLoading {
    NSLog(@"%@ received %@ - start", self, NSStringFromSelector(_cmd));
    
    NSMutableURLRequest *request = [[self request] mutableCopy];
    NSURL *url = [request URL];
    NSURL *httpURL = [[NSURL alloc] initWithScheme:@"http" host:[url host] path:[url path]];
    
    NSString *md5 = [JQProxyURLProtocol md5:[httpURL absoluteString]];
    NSFileManager *fm = [NSFileManager defaultManager];
    cacheURL = [[[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:md5];
    
    if([fm fileExistsAtPath:[cacheURL absoluteString]]) {
        NSLog(@"CACHE HIT");
    }
    
    NSLog(@"CACHE MISS md5 = %@, cache = %@", md5, [cacheURL absoluteString]);
    [request setURL:httpURL];
    [NSURLConnection connectionWithRequest:request delegate:self];
}

- (void)stopLoading {
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
}

#pragma mark "NSURLConnection Delegate"

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSLog(@"didReceiveResponse");
    [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"didReceiveData");
    NSFileManager *fm = [NSFileManager defaultManager];
    [[self client] URLProtocol:self didLoadData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSLog(@"finished");
    [[self client] URLProtocolDidFinishLoading:self];
}

@end
