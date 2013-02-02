//
//  JQProxyURLProtocol.m
//  JuqueApp
//
//  Created by Daniel Watson on 1/25/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import "JQMediaCacheProtocol.h"
#import "JQMediaDownloader.h"
#import <CommonCrypto/CommonDigest.h>

@interface NSString (MD5)
- (NSString *)md5;
@end

@implementation NSString (MD5)
- (NSString *)md5 {
    const char *ptr = [self UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    CC_MD5(ptr, strlen(ptr), md5Buffer);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", md5Buffer[i]];
    return output;
}
@end

@interface NSDate (HTTP)
- (NSString *)httpString;
@end

@implementation NSDate (HTTP)

- (NSString *)httpString {
    static NSDateFormatter *df = nil;
    if(df == nil) {
        df = [[NSDateFormatter alloc] init];
        df.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        df.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        df.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
    }
    return [df stringFromDate:self];
}

@end

@implementation JQMediaCacheProtocol

+ (BOOL)isCached:(NSURL *)url {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [[JQMediaCacheProtocol cacheURLForRequestURL:url] path];
    return [fm fileExistsAtPath:path];
}

+ (NSURL *)cacheURLForRequestURL:(NSURL *)url {
    NSString *requestString = [[[url absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *cacheURL = [[fm URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0];
    NSString *filename = [NSString stringWithFormat:@"%@.%@", [requestString md5], [requestString pathExtension]];
    return [cacheURL URLByAppendingPathComponent:filename];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    NSLog(@"%@ received %@ with URL %@", self, NSStringFromSelector(_cmd), [[request URL] absoluteString]);
    NSString *extension = [[[[[request URL] absoluteString] componentsSeparatedByString:@"?"] objectAtIndex:0] pathExtension];
    NSArray *acceptable = @[@"mp3", @"mp4", @"m4a"];
    BOOL canAccept = NO;
    for(NSString *ext in acceptable) {
        if([ext isEqualToString:extension]) {
            canAccept = YES;
            break;
        }
    }
    if(!canAccept)
        return NO;
    return [[[request URL] scheme] isEqualToString:@"http"] && ([request valueForHTTPHeaderField:JQIgnoreRequestHeader] == nil);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSFileManager *fm = [NSFileManager defaultManager];
    cachePath = [[JQMediaCacheProtocol cacheURLForRequestURL:[[self request] URL]] path];
    NSLog(@"REQUEST cachePath = %@, headers = %@", cachePath, [[self request] allHTTPHeaderFields]);
    
    if([fm fileExistsAtPath:cachePath]) {
        // TODO: this in inefficient, should read only what we need
        NSData *data = [fm contentsAtPath:cachePath];
        NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithDictionary:@{
                                        @"Server": @"Juque/1.0",
                                        @"Date": [[NSDate date] httpString],
                                        @"Content-Length": [NSString stringWithFormat:@"%d", [data length]],
                                        @"Content-Type": @"audio/mp4",
                                        @"Accept-Ranges": @"bytes",
                                        @"Connection": @"keep-alive",
                                        }];
        
        NSString *range = [[[self request] allHTTPHeaderFields] objectForKey:@"Range"];
        NSUInteger status = 200;
        if(range != nil) {
            range = [[range componentsSeparatedByString:@"="] objectAtIndex:1];
            NSArray *parts = [range componentsSeparatedByString:@"-"];
            NSInteger start = [[parts objectAtIndex:0] isEqualToString:@""] ? 0 : [[parts objectAtIndex:0] integerValue];
            NSInteger end = [[parts objectAtIndex:1] isEqualToString:@""] ? [data length] - 1 : [[parts objectAtIndex:1] integerValue];
            NSLog(@"%@ range %d - %d", parts, start, end);
            status = 206;
            [headers setValue:[NSString stringWithFormat:@"bytes %d-%d/%d", start, end, [data length]] forKey:@"Content-Range"];
            data = [data subdataWithRange:NSMakeRange(start, end - start + 1)];
            [headers setValue:[NSString stringWithFormat:@"%d", [data length]] forKey:@"Content-Length"];
        }
        
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[[self request] URL] statusCode:status HTTPVersion:@"HTTP/1.1" headerFields:headers];
        NSLog(@"RESPONSE headers = %@", [response allHeaderFields]);
        [[self client] URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        [[self client] URLProtocol:self didLoadData:data];
        [[self client] URLProtocolDidFinishLoading:self];
    }
    else {
        [JQMediaDownloader downloaderWithRequest:[self request] protocol:self cachePath:cachePath];
    }
}

- (void)stopLoading {
    NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
}

@end
