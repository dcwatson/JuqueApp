//
//  JQFirstViewController.h
//  JuqueApp
//
//  Created by Daniel Watson on 1/20/13.
//  Copyright (c) 2013 Daniel Watson. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JQArtistViewController : UITableViewController <UITableViewDataSource> {
    NSMutableArray *artistData, *sections;
}

@end
