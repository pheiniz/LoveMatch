//
//  LMDataConnector.h
//  LoveMatch
//
//  Created by Paul Heiniz on 05.01.13.
//  Copyright (c) 2013 nerdburgers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "LMStartViewController.h"

@interface LMDataConnector : NSObject

@property (nonatomic, strong) User *currentUser;
+ (id)sharedInstance;

- (void)calculateDataForView:(LMStartViewController *) viewController;
- (NSArray *)getFriendsForGender:(NSString *) gender;
- (void)deleteDatabase;
- (User *)getCurrentUser;

@end
