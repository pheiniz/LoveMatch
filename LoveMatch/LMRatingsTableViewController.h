//
//  LMRatingsTableViewController.h
//  LoveMatch
//
//  Created by Paul Heiniz on 05.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMFriendCell.h"
#import "Friend.h"
#import "UIImageView+AFNetworking.h"

@interface LMRatingsTableViewController : UITableViewController

@property (nonatomic, strong) NSArray *friends;

@end
