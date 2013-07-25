//
//  LMStartViewController.h
//  LoveMatch
//
//  Created by Wolfgang Kluth on 02.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FacebookSDK/FacebookSDK.h>
#import "User.h"
#import "Friend.h"
#import "ATMHudDelegate.h"

@interface LMStartViewController : UIViewController <ATMHudDelegate>
- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error;
- (void)calculationSuccessful;
- (void)startHud;
@end
