//
//  JQFirstViewController.m
//  JuqueApp
//
//  Created by Daniel Watson on 1/20/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import "JQArtistViewController.h"
#import "JQTrackViewController.h"

@interface ArtistInfo : NSObject

@property NSDictionary *info;

- (id)initWithDictionary:(NSDictionary *)dict;
- (NSString *)name;

@end

@implementation ArtistInfo

@synthesize info;

- (id)initWithDictionary:(NSDictionary *)dict {
    if(self = [super init]) {
        self.info = dict;
    }
    return self;
}

- (NSString *)name {
    return [self.info objectForKey:@"name"];
}

@end

@implementation JQArtistViewController

- (void)viewDidLoad {
    artistData = [NSMutableArray array];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/api/v1/artist/?format=json&limit=0", JUQUE_SERVER]]];
        NSError *error;
        NSDictionary *info = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        if(error == nil) {
            NSArray *artistList = [info objectForKey:@"objects"];
            [self performSelectorOnMainThread:@selector(gotArtists:) withObject:artistList waitUntilDone:YES];
        }
    });
    
    [super viewDidLoad];
}

- (void)_buildSections:(NSArray *)objects {
    SEL selector = @selector(name);
    NSInteger idx, sectionTitlesCount = [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];

    sections = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    
    for(idx = 0; idx < sectionTitlesCount; idx++) {
        [sections addObject:[NSMutableArray array]];
    }
    
    for(id object in objects) {
        NSInteger sectionNumber = [[UILocalizedIndexedCollation currentCollation] sectionForObject:object collationStringSelector:selector];
        [[sections objectAtIndex:sectionNumber] addObject:object];
    }
    
    for(idx = 0; idx < sectionTitlesCount; idx++) {
        NSArray *objectsForSection = [sections objectAtIndex:idx];
        [sections replaceObjectAtIndex:idx withObject:[[UILocalizedIndexedCollation currentCollation] sortedArrayFromArray:objectsForSection collationStringSelector:selector]];
    }
}

- (void)gotArtists:(NSArray *)artistList {
    for(NSDictionary *info in artistList) {
        [artistData addObject:[[ArtistInfo alloc] initWithDictionary:info]];
    }
    [self _buildSections:artistData];
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    JQTrackViewController *next = [segue destinationViewController];
    NSIndexPath *path = self.tableView.indexPathForSelectedRow;
    ArtistInfo *artist = [[sections objectAtIndex:path.section] objectAtIndex:path.row];
    [next setArtist:artist.info];
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return [sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[sections objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [table dequeueReusableCellWithIdentifier:@"ArtistCell"];
    ArtistInfo *artist = [[sections objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    cell.textLabel.text = [artist.info objectForKey:@"name"];
    cell.detailTextLabel.text = [[artist.info objectForKey:@"track_count"] stringValue];
    return cell;
}

@end
