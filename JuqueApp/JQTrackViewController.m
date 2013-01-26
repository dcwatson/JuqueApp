//
//  JQTrackViewController.m
//  JuqueApp
//
//  Created by Daniel Watson on 1/25/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import "JQTrackViewController.h"
#import <MediaPlayer/MediaPlayer.h>

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
    [player pause];
    NSDictionary *track = [trackList objectAtIndex:indexPath.row];
    NSString *urlString = [NSString stringWithFormat:@"http://192.168.1.28:8000%@", [track objectForKey:@"url"]];
    
    NSLog(@"playing %@", urlString);
    
    MPMoviePlayerViewController *controller = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:urlString]];
    controller.moviePlayer.controlStyle = MPMovieControlStyleEmbedded;
    [self.navigationController pushViewController:controller animated:YES];
    
    /*
    MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:urlString]];
    moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    moviePlayer.view.transform = CGAffineTransformConcat(moviePlayer.view.transform, CGAffineTransformMakeRotation(M_PI_2));
    UIWindow *backgroundWindow = [[UIApplication sharedApplication] keyWindow];
    [moviePlayer.view setFrame:backgroundWindow.frame];
    [backgroundWindow addSubview:moviePlayer.view];
    [moviePlayer setFullscreen:YES animated:YES];
    [moviePlayer prepareToPlay];
    [moviePlayer play];
     */
}

@end
