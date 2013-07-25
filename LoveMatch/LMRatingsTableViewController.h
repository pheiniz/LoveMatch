//
//  LMRatingsTableViewController.h
//  LoveMatch
//
//  Created by Paul Heiniz on 05.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "LMFriendCell.h"
#import "Friend.h"
#import "UIImageView+AFNetworking.h"
#import "LMDataConnector.h"
#import "SVModalWebViewController.h"

@interface LMRatingsTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *friends;

- (void)changeGenderTo:(NSString *)gender;

@end
