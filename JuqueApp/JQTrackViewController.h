//
//  JQTrackViewController.h
//  JuqueApp
//
//  Created by Daniel Watson on 1/25/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface JQTrackViewController : UITableViewController {
    NSArray *sectionNames;
    NSMutableDictionary *sections;
    MPMoviePlayerViewController *movieController;
    UIImageView *cloudAccessoryView;
}

- (void)setArtist:(NSDictionary *)artistInfo;

@end
