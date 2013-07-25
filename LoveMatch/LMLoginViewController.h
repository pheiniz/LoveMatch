//
//  LMLoginViewController.h
//  LoveMatch
//
//  Created by Wolfgang Kluth on 02.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMStartViewController.h"

@interface LMLoginViewController : UIViewController

@property (nonatomic, strong) LMStartViewController *startViewController;
- (IBAction)loginButtonPressed:(id)sender;

@end
