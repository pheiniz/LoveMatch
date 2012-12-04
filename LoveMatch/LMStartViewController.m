//
//  LMStartViewController.m
//  LoveMatch
//
//  Created by Wolfgang Kluth on 02.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import "LMStartViewController.h"
#import "LMLoginViewController.h"

@interface LMStartViewController ()

- (void)openSession;
- (void)showLoginView;

@end

@implementation LMStartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[FBRequest requestForMe] startWithCompletionHandler:
     ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
         if (!error) {
             [[self currentUser] setFirstName:[user objectForKey:@"first_name"]];
             [[self currentUser] setLastName:[user objectForKey:@"last_name"]];
             [[self currentUser] setGender:[user objectForKey:@"gender"]];
             
             if ([self.currentUser.gender isEqualToString:@"male"])
             {
                 [[self currentUser] setInterestedIn:@"female"];
             }else{
                 [[self currentUser] setInterestedIn:@"male"];
             }
             
             //self.userProfileImage.profileID = [user objectForKey:@"id"];
         }
     }];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (FBSession.activeSession.state == FBSessionStateOpen)
    {
        return;
    }
    
    // See if we have a valid token for the current state.
    if (FBSession.activeSession.state == FBSessionStateOpen) {
        // To-do, show logged in view
        [self openSession];
    } else {
        // No, display the login page.
        [self showLoginView];
    }
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
{
    switch (state) {
        case FBSessionStateOpen:
            //            if ([[topViewController modalViewController] isKindOfClass: LMLoginViewController class]]) {
            [self dismissViewControllerAnimated:YES completion:nil];
            //            }
            
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            // Once the user has logged in, we want them to
            // be looking at the root view.
            //[self dismissViewControllerAnimated:YES completion:nil];
            
            [FBSession.activeSession closeAndClearTokenInformation];
            
            //[self showLoginView];
            break;
        default:
            break;
    }
    
    if (error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)startCalculationForFriendsWithGender:(NSString *) gender{
    NSLog(@"Start calculating ...");
    NSString *query = [NSString stringWithFormat:
                       @"{"
                       @"'all_friends_with_gender':'SELECT first_name, last_name, uid, pic, relationship_status FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) AND sex = \"%@\"',"
                       @"'likes_on_user_status':'SELECT user_id FROM like WHERE object_id IN (SELECT status_id FROM status WHERE uid=me()) AND  user_id IN (SELECT uid FROM #all_friends_with_gender)',"
                       @"'likes_on_same_post':'SELECT user_id, object_id FROM like WHERE user_id IN (SELECT uid FROM #all_friends_with_gender) AND object_id IN (SELECT object_id FROM like WHERE user_id=me())',"
                       @"}", gender];
    
    // Set up the query parameter
    NSDictionary *queryParam = [NSDictionary dictionaryWithObjectsAndKeys:
                                query, @"q", nil];
    // Make the API request that uses FQL
    [FBRequestConnection startWithGraphPath:@"/fql"
                                 parameters:queryParam
                                 HTTPMethod:@"GET"
                          completionHandler:^(FBRequestConnection *connection,
                                              id result,
                                              NSError *error) {
                              if (error) {
                                  NSLog(@"Error: %@", [error localizedDescription]);
                              } else {
                                  NSLog(@"Result: %@", result);
                                  NSArray *friends = [[(NSArray *) [result objectForKey:@"data"] objectAtIndex:0] objectForKey:@"fql_result_set"];
                                  NSLog(@"Friends: %d", [friends count]);
                                  NSArray *likesOnStatus = [[(NSArray *) [result objectForKey:@"data"] objectAtIndex:2] objectForKey:@"fql_result_set"];
                                  NSLog(@"Likes on user status: %d", [likesOnStatus count]);
                                  NSArray *likesOnSamePost = [[(NSArray *) [result objectForKey:@"data"] objectAtIndex:1] objectForKey:@"fql_result_set"];
                                  NSLog(@"Likes on same post: %d", [likesOnSamePost count]);
                                  //[self getDataForFriends:friends];
                              }
                          }];
}

- (void)getDataForFriends:(NSArray *) friends{
    for (NSDictionary *friend in friends)
    {
        // Multi-query to fetch the active user's friends, limit to 25.
        // The initial query is stored in reference named "friends".
        // The second query picks up the "uid2" info from the first
        // query and gets the friend details.
        NSString *query = [NSString stringWithFormat: 
        @"{"
        @"'likes_on_same_status':'SELECT user_id, object_id FROM like WHERE user_id = %@ AND object_id IN (SELECT object_id FROM like WHERE user_id=me())',"
        @"'likes_on_user_status':'SELECT user_id FROM like WHERE object_id IN (SELECT status_id FROM status WHERE uid=me())',"
        @"}", [friend valueForKey:@"uid"]];
        // Set up the query parameter
        NSDictionary *queryParam = [NSDictionary dictionaryWithObjectsAndKeys:
                                    query, @"q", nil];
        // Make the API request that uses FQL
        [FBRequestConnection startWithGraphPath:@"/fql"
                                     parameters:queryParam
                                     HTTPMethod:@"GET"
                              completionHandler:^(FBRequestConnection *connection,
                                                  id result,
                                                  NSError *error) {
                                  if (error) {
                                      NSLog(@"Error: %@", [error localizedDescription]);
                                  } else {
                                      //NSLog(@"Result: %@", result);
                                      NSLog(@"Result: ");
                                  }
                              }];
    }
}

- (IBAction)startFBSearch:(id)sender {    
    
    [self startCalculationForFriendsWithGender:[[self currentUser] interestedIn]];

}

- (void)openSession
{
    [FBSession openActiveSessionWithReadPermissions:nil
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
}


- (void)showLoginView
{
    [self performSegueWithIdentifier:@"ShowLoginView" sender:self];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
