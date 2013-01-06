//
//  LMLoginViewController.m
//  LoveMatch
//
//  Created by Wolfgang Kluth on 02.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import "LMLoginViewController.h"
#import <FacebookSDK/FacebookSDK.h>
#import "LMStartViewController.h"

@interface LMLoginViewController ()

@end

@implementation LMLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginButtonPressed:(id)sender
{
    NSArray *permissions =
    [NSArray arrayWithObjects:@"user_photos", @"friends_photos", @"read_stream", @"read_mailbox", @"user_relationships", @"friends_relationships", nil];
    
    [FBSession openActiveSessionWithReadPermissions:permissions
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                      
                                      [self.startViewController sessionStateChanged:session state:state error:error];
                                      
                                  }];
}
@end
