//
//  JQFirstViewController.m
//  JuqueApp
//
//  Created by Daniel Watson on 1/20/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import "JQArtistViewController.h"
#import "JQTrackViewController.h"

@interface JQArtistViewController ()

@end

@implementation JQArtistViewController

- (void)viewDidLoad {
    artistData = [NSArray array];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"http://localhost:8000/api/v1/artist/?format=json&limit=0"]];
        NSError *error;
        NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if(error == nil) {
            NSArray *artistList = [info objectForKey:@"objects"];
            [self performSelectorOnMainThread:@selector(gotArtists:) withObject:artistList waitUntilDone:YES];
        }
    });
    
    [super viewDidLoad];
}

- (void)gotArtists:(NSArray *)artistList {
    artistData = artistList;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    JQTrackViewController *next = [segue destinationViewController];
    NSDictionary *info = [artistData objectAtIndex:self.tableView.indexPathForSelectedRow.row];
    [next setArtist:info];
}

#pragma mark -

/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 0;
}
*/

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return [artistData count];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"ArtistCell"];
    NSDictionary *artist = [artistData objectAtIndex:indexPath.row];
    cell.textLabel.text = [artist objectForKey:@"name"];
    cell.detailTextLabel.text = [[artist objectForKey:@"track_count"] stringValue];
    return cell;
}

@end
