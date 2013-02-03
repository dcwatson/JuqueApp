//
//  JQTrackViewController.m
//  JuqueApp
//
//  Created by Daniel Watson on 1/25/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import "JQTrackViewController.h"
#import "JQMediaCacheProtocol.h"

@interface TrackInfo : NSObject

@property NSDictionary *info;

- (id)initWithDictionary:(NSDictionary *)dict;
- (NSString *)album;
- (NSInteger)number;

@end

@implementation TrackInfo

@synthesize info;

- (id)initWithDictionary:(NSDictionary *)dict {
    if(self = [super init]) {
        self.info = dict;
    }
    return self;
}

- (NSString *)album {
    id albumInfo = [self.info objectForKey:@"album"];
    return [albumInfo isKindOfClass:[NSNull class]] ? @"No Album" : [albumInfo objectForKey:@"name"];
}

- (NSInteger)number {
    return [[self.info objectForKey:@"track_number"] integerValue];
}

@end

@implementation JQTrackViewController

- (id)initWithStyle:(UITableViewStyle)style {
    if(self = [super initWithStyle:style]) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)setArtist:(NSDictionary *)artistInfo {
    self.navigationItem.title = [artistInfo objectForKey:@"name"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"%@/api/v1/track/?format=json&artist__id=%@&limit=0", JUQUE_SERVER, [artistInfo objectForKey:@"id"]];
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        NSError *error;
        NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if(error == nil) {
            NSArray *theList = [info objectForKey:@"objects"];
            [self performSelectorOnMainThread:@selector(gotTracks:) withObject:theList waitUntilDone:YES];
        }
    });
}

- (void)setArtwork:(UIImage *)image {
    UIImageView *artView = [[UIImageView alloc] initWithImage:image];
    CGRect frame = movieController.moviePlayer.backgroundView.frame;
    artView.frame = CGRectMake(frame.origin.x, frame.origin.y, 320.0, 320.0);
    movieController.moviePlayer.backgroundView.backgroundColor = [UIColor blackColor];
    [movieController.moviePlayer.backgroundView addSubview:artView];
}

- (void)_buildSections:(NSArray *)objects {
    sections = [NSMutableDictionary dictionary];
    for(TrackInfo *track in objects) {
        NSMutableArray *arr = [sections objectForKey:[track album]];
        if(arr == nil) {
            arr = [NSMutableArray arrayWithObject:track];
            [sections setObject:arr forKey:[track album]];
        }
        else {
            [arr addObject:track];
        }
    }
    sectionNames = [[sections allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}

- (void)gotTracks:(NSArray *)tracks {
    NSMutableArray *trackObjects = [NSMutableArray array];
    for(NSDictionary *info in tracks) {
        [trackObjects addObject:[[TrackInfo alloc] initWithDictionary:info]];
    }
    [self _buildSections:trackObjects];
    [self.tableView reloadData];
}

- (void)pushController:(NSDictionary *)track {
    NSString *urlString = [track objectForKey:@"url"];
    if(![urlString hasPrefix:@"http"]) {
        urlString = [NSString stringWithFormat:@"%@%@", JUQUE_SERVER, urlString];
    }
    NSURL *cacheURL = [JQMediaCacheProtocol cacheURLForRequestURL:[NSURL URLWithString:urlString]];

    movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:cacheURL];
    movieController.moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    movieController.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    
    id albumInfo = [track objectForKey:@"album"];
    if(![albumInfo isKindOfClass:[NSNull class]]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            NSString *urlString = [NSString stringWithFormat:@"%@%@", JUQUE_SERVER, [albumInfo objectForKey:@"artwork_url"]];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
            [self performSelectorOnMainThread:@selector(setArtwork:) withObject:[UIImage imageWithData:data scale:2.0] waitUntilDone:YES];
        });
    }
    [self.navigationController pushViewController:movieController animated:YES];
    movieController.navigationItem.title = [track objectForKey:@"name"];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return [sectionNames count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSString *album = [sectionNames objectAtIndex:section];
    return [[sections objectForKey:album] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [sectionNames objectAtIndex:section];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"TrackCell"];
    NSString *album = [sectionNames objectAtIndex:indexPath.section];
    TrackInfo *track = [[sections objectForKey:album] objectAtIndex:indexPath.row];
    cell.textLabel.text = [track.info objectForKey:@"name"];
    
    // Indicate if the track is cached locally.
    NSString *urlString = [track.info objectForKey:@"url"];
    if(![urlString hasPrefix:@"http"]) {
        urlString = [NSString stringWithFormat:@"%@%@", JUQUE_SERVER, urlString];
    }
    if([JQMediaCacheProtocol isCached:[NSURL URLWithString:urlString]]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *album = [sectionNames objectAtIndex:indexPath.section];
    TrackInfo *track = [[sections objectForKey:album] objectAtIndex:indexPath.row];
    
    NSString *urlString = [track.info objectForKey:@"url"];
    if(![urlString hasPrefix:@"http"]) {
        urlString = [NSString stringWithFormat:@"%@%@", JUQUE_SERVER, urlString];
    }
    NSURL *trackURL = [NSURL URLWithString:urlString];
    NSURL *cacheURL = [JQMediaCacheProtocol cacheURLForRequestURL:trackURL];
    
    if([JQMediaCacheProtocol isCached:trackURL]) {
        [self pushController:track.info];
    }
    else {
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryView = spinner;
        [spinner startAnimating];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSData *data = [NSData dataWithContentsOfURL:trackURL];
            NSFileManager *fm = [NSFileManager defaultManager];
            [fm createFileAtPath:[cacheURL path] contents:data attributes:nil];
            [self performSelectorOnMainThread:@selector(markCached:) withObject:cell waitUntilDone:YES];
            [self performSelectorOnMainThread:@selector(pushController:) withObject:track.info waitUntilDone:YES];
        });
    }
}

- (void)markCached:(UITableViewCell *)cell {
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
}

@end
