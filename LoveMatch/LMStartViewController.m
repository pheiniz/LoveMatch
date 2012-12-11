//
//  LMStartViewController.m
//  LoveMatch
//
//  Created by Wolfgang Kluth on 02.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import "LMStartViewController.h"
#import "LMLoginViewController.h"
#import "LMRatingsTableViewController.h"


@interface LMStartViewController ()

- (void)openSession;
- (void)showLoginView;

@end

@implementation LMStartViewController

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (FBSession.activeSession.state == FBSessionStateOpen)
    {
        return;
    }
    
    // See if we have a valid token for the current state.
    if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded)
    {
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
            if ([self.presentedViewController isKindOfClass: [LMLoginViewController class]]) {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            
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
    
    [self getUserData];
}

- (void)getUserData
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSArray *resultArray = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    if (FBSession.activeSession.isOpen && [resultArray count] == 0 ) {
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
             if (!error) {
                 User *currentUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
                 [currentUser setUid:[user objectForKey:@"id"]];
                 [currentUser setFirstName:[user objectForKey:@"first_name"]];
                 [currentUser setLastName:[user objectForKey:@"last_name"]];
                 [currentUser setGender:[user objectForKey:@"gender"]];
                 
                 if ([currentUser.gender isEqualToString:@"male"])
                 {
                     [currentUser setInterestedIn:@"female"];
                 }else{
                     [currentUser setInterestedIn:@"male"];
                 }
                 
                 [currentUser setPictureURL:@""];
                 //self.userProfileImage.profileID = [user objectForKey:@"id"];
                 
                 [self saveContext];
                 
                 [self setCurrentUser:currentUser];
             }
         }];
    }else{
        [self setCurrentUser:[resultArray objectAtIndex:0]];
    }
}

- (void)startCalculationForFriendsWithGender:(NSString *)gender {
    NSLog(@"Start calculating ...");
    NSString *query = [NSString stringWithFormat:
                       @"{"
                       @"'all_friends_with_gender':'SELECT first_name, last_name, uid, pic, relationship_status FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) AND sex = \"%@\"',"
                       @"'likes_on_user_status':'SELECT user_id FROM like WHERE object_id IN (SELECT status_id FROM status WHERE uid=me()) AND  user_id IN (SELECT uid FROM #all_friends_with_gender)',"
                       @"'likes_on_same_post':'SELECT user_id FROM like WHERE user_id IN (SELECT uid FROM #all_friends_with_gender) AND object_id IN (SELECT object_id FROM like WHERE user_id=me())',"
                       @"'direct_messages':'SELECT author_id FROM message WHERE thread_id IN (SELECT thread_id FROM thread WHERE folder_id = 0) AND author_id IN (SELECT uid FROM #all_friends_with_gender)',"
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
                                  
                                  [self processFBData:[result objectForKey:@"data"]];
                              }
                          }];
}

- (void)processFBData:(NSArray *)jsonData {
    
    NSArray *friends = [[jsonData objectAtIndex:0] objectForKey:@"fql_result_set"];
    [self createFriendEntities:friends];
    
    NSArray *directMessages = [[jsonData objectAtIndex:1] objectForKey:@"fql_result_set"];
    NSLog(@"Direct Messages: %d", [directMessages count]);
    
    [self calculateRatingFor:directMessages withWeight:3];
    
    NSArray *likesOnUserStatus = [[jsonData objectAtIndex:3] objectForKey:@"fql_result_set"];
    NSLog(@"Likes on user status: %d", [likesOnUserStatus count]);
    
    [self calculateRatingFor:likesOnUserStatus withWeight:2];
    
    
    NSArray *likesOnSamePost = [[jsonData objectAtIndex:2] objectForKey:@"fql_result_set"];
    NSLog(@"Likes on same post: %d", [likesOnSamePost count]);
    
    [self calculateRatingFor:likesOnSamePost withWeight:1];
    
    [self performSegueWithIdentifier:@"ShowRatingsTableView" sender:self];
    
}

- (void)createFriendEntities:(NSArray *)friends {
    for (NSDictionary* friendDict in friends) {
        Friend *friend = [NSEntityDescription insertNewObjectForEntityForName:@"Friend" inManagedObjectContext:self.managedObjectContext];
        [friend setUid:[NSString stringWithFormat:@"%@",[friendDict valueForKey:@"uid"]]];
        [friend setFirstName:[friendDict valueForKey:@"first_name"]];
        [friend setLastName:[friendDict valueForKey:@"last_name"]];
        [friend setGender:[[self currentUser] interestedIn]];
        [friend setPictureURL:[friendDict valueForKey:@"pic"]];
        
        //TODO: relationship_status als null wird nicht erkannt. überarbeiten!
        if ([friendDict valueForKey:@"relationship_status"] == (id)[NSNull null]) {
            [friend setRelationshipStatus:@"Single"];
        }else{
            [friend setRelationshipStatus:[friendDict valueForKey:@"relationship_status"]];
        }
        
        [[self currentUser] addFriendsObject:friend];
    }
    [self saveContext];
    NSLog(@"Friends: %d", [friends count]);
}

- (void)calculateRatingFor:(NSArray *)users withWeight:(int)weight{
    NSFetchRequest *request;
    NSEntityDescription *entity;
    NSPredicate *predicate;
    NSArray *resultArray;
    
    for (NSDictionary *uidDict in users) {
        NSString *uid = [[uidDict allValues] objectAtIndex:0];
        
        request = [[NSFetchRequest alloc] init];
        entity = [NSEntityDescription entityForName:@"Friend" inManagedObjectContext:self.managedObjectContext];
        [request setEntity:entity];
        predicate = [NSPredicate predicateWithFormat: @"uid == %@", uid];
        [request setPredicate:predicate];
        resultArray = [self.managedObjectContext executeFetchRequest:request error:nil];
        
        Friend *friend = [resultArray objectAtIndex:0];
        friend.rating = [NSNumber numberWithInt:[friend.rating intValue] + weight];
        [self saveContext];
    }
}


- (IBAction)startFBSearch:(id)sender {    
    
    if ([_currentUser.friends count] == 0)
    {
        [self startCalculationForFriendsWithGender:[[self currentUser] interestedIn]];
    }else{
        [self performSegueWithIdentifier:@"ShowRatingsTableView" sender:self];
    }
    

}

- (void)openSession
{
    
    NSArray *permissions =
    [NSArray arrayWithObjects:@"user_photos", @"friends_photos", @"read_stream", @"read_mailbox", nil];
    
    [FBSession openActiveSessionWithReadPermissions:permissions
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ShowRatingsTableView"])
    {
        LMRatingsTableViewController *ratingTableViewController = [segue destinationViewController];
        
        NSSet *friendsSet = _currentUser.friends;
        NSSortDescriptor *ratingDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rating" ascending:NO];
        NSArray *friends = [[friendsSet allObjects]sortedArrayUsingDescriptors:[NSArray arrayWithObjects: ratingDescriptor, nil]];
        [ratingTableViewController setFriends:friends];
    }
}

#pragma mark - Core Data stack

- (void)saveContext
{
    NSError *error = nil;
    
    if (__managedObjectContext != nil)
    {
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             */
            NSLog(@"Failed to save to data store: %@", [error localizedDescription]);
            NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
            if(detailedErrors != nil && [detailedErrors count] > 0) {
                for(NSError* detailedError in detailedErrors) {
                    NSLog(@"  DetailedError: %@", [detailedError userInfo]);
                }
            }
            else {
                NSLog(@"  %@", [error userInfo]);
            }
            abort();
        }
    }
}

- (void)deleteDatabase
{
    NSError *error;
    NSPersistentStore *store = [self.persistentStoreCoordinator.persistentStores lastObject];
    NSURL *storeURL = store.URL;
    [self.persistentStoreCoordinator removePersistentStore:store error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error];
    
    
    // Create new persistent store
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSLog(@"Unresolved error %@, %@ while deleting and adding new database.", error, [error userInfo]);
        abort();
    }
}

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (__managedObjectContext != nil)
    {
        return __managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return __managedObjectContext;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (__managedObjectModel != nil)
    {
        return __managedObjectModel;
    }
    //mom because no versioning. in case of arror try out momd
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"LoveMatch" withExtension:@"momd"];
    
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (__persistentStoreCoordinator != nil)
    {
        return __persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:@"lovematch.sqlite"];
    
    
    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return __persistentStoreCoordinator;
}

@end
