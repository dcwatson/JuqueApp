//
//  JQTrackViewController.h
//  JuqueApp
//
//  Created by Daniel Watson on 1/25/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface JQTrackViewController : UITableViewController {
    AVPlayer *player;
    NSArray *trackList;
}

- (void)setArtist:(NSDictionary *)artistInfo;

@end
