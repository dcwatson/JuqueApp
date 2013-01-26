//
//  JQTrackViewController.m
//  JuqueApp
//
//  Created by Daniel Watson on 1/25/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import "JQTrackViewController.h"

@interface JQTrackViewController ()

@end

@implementation JQTrackViewController

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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
        NSString *urlString = [NSString stringWithFormat:@"http://192.168.1.28:8000/api/v1/track/?format=json&artist__id=%@", [artistInfo objectForKey:@"id"]];
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        NSError *error;
        NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if(error == nil) {
            NSArray *theList = [info objectForKey:@"objects"];
            [self performSelectorOnMainThread:@selector(gotTracks:) withObject:theList waitUntilDone:YES];
        }
    });
}

- (void)gotTracks:(NSArray *)tracks {
    trackList = tracks;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return [trackList count];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"TrackCell"];
    NSDictionary *track = [trackList objectAtIndex:indexPath.row];
    cell.textLabel.text = [track objectForKey:@"name"];
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *track = [trackList objectAtIndex:indexPath.row];
    NSString *urlString = [NSString stringWithFormat:@"http://192.168.1.28:8000%@", [track objectForKey:@"url"]];
    
    NSLog(@"playing %@", urlString);
    
    movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:urlString]];
    movieController.moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    movieController.moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSString *urlString = [NSString stringWithFormat:@"http://192.168.1.28:8000%@", [[track objectForKey:@"album"] objectForKey:@"artwork_url"]];
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:urlString]];
        [self performSelectorOnMainThread:@selector(setArtwork:) withObject:[UIImage imageWithData:data] waitUntilDone:YES];
    });
    
    [self.navigationController pushViewController:movieController animated:YES];
    movieController.navigationItem.title = [track objectForKey:@"name"];
}

- (void)setArtwork:(UIImage *)image {
    UIImageView *artView = [[UIImageView alloc] initWithImage:image];
    artView.frame = movieController.moviePlayer.backgroundView.frame;
    [movieController.moviePlayer.backgroundView addSubview:artView];
}

@end
