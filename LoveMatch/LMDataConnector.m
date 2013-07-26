//
//  LMDataConnector.m
//  LoveMatch
//
//  Created by Paul Heiniz on 05.01.13.
//  Copyright (c) 2013 nerdburgers. All rights reserved.
//

#import "LMDataConnector.h"
#import "User.h"
#import "Friend.h"

@interface LMDataConnector()

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;


@property (nonatomic, strong) LMStartViewController *startViewController;

@end

@implementation LMDataConnector

@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

static LMDataConnector *sharedInstance = nil;

// Get the shared instance and create it if necessary.
+ (LMDataConnector *)sharedInstance {
    if (sharedInstance == nil) {
        sharedInstance = [[super alloc] init];
    }
    
    return sharedInstance;
}

// We can still have a regular init method, that will get called the first time the Singleton is used.
- (id)init
{
    self = [super init];
    
    if (self) {
    }
    
    return self;
}

// Equally, we don't want to generate multiple copies of the singleton.
- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


#pragma mark - Data calculation

- (void)calculateDataForView:(LMStartViewController *) viewController
{
    self.startViewController = viewController;
    [self getUserData];
}

- (User *)getCurrentUser
{
    if (self.currentUser)
        return self.currentUser;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSArray *resultArray = [self.managedObjectContext executeFetchRequest:request error:nil];
    if ([resultArray count] != 0)
    {
    [self setCurrentUser:[resultArray objectAtIndex:0]];
        return self.currentUser;
    }
    return nil;
}

- (void)getUserData
{
    if (FBSession.activeSession.isOpen && !self.currentUser) {
        
        // set hud and block the view as long as data is loading
        [self.startViewController startHud];
        
        [[FBRequest requestForMe] startWithCompletionHandler:
         ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
             if (!error) {
                 
                 User *tempUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:self.managedObjectContext];
                 [tempUser setUid:[user objectForKey:@"id"]];
                 [tempUser setFirstName:[user objectForKey:@"first_name"]];
                 [tempUser setLastName:[user objectForKey:@"last_name"]];
                 [tempUser setGender:[user objectForKey:@"gender"]];
                 
                 if ([tempUser.gender isEqualToString:@"male"])
                 {
                     [tempUser setInterestedIn:@"female"];
                 }else{
                     [tempUser setInterestedIn:@"male"];
                 }
                 
                 [tempUser setPictureURL:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", [tempUser uid]]];
                 
                 if ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] &&
                     ([UIScreen mainScreen].scale == 2.0)) {
                     //retina
                     [tempUser setPictureIcon:[NSData dataWithContentsOfURL:[NSURL URLWithString:[tempUser.pictureURL stringByAppendingString:@"?width=500&height=170"]]]];
                 } else {
                     //non-retina
                     [tempUser setPictureIcon:[NSData dataWithContentsOfURL:[NSURL URLWithString:[tempUser.pictureURL stringByAppendingString:@"?width=250&height=85"]]]];
                 }
                 
                 
                 [self saveContext];
                 
                 [self setCurrentUser:tempUser];
                 
                 //get all the friends data
                 [self startCalculationForAllFriends];
                 
             }
         }];
    }    
}

//get all data from FB
- (void)startCalculationForAllFriends{
    NSLog(@"Start calculating ...");
    NSString *query = [NSString stringWithFormat:
                       @"{"
                       @"'all_friends':'SELECT first_name, last_name, uid, pic, sex, relationship_status FROM user WHERE uid IN (SELECT uid2 FROM friend WHERE uid1 = me())',"
                       @"'users_family':'SELECT uid FROM family WHERE profile_id = me()',"
                       @"'likes_on_user_status':'SELECT user_id FROM like WHERE object_id IN (SELECT status_id FROM status WHERE uid=me()) AND  user_id IN (SELECT uid FROM #all_friends)',"
                       @"'likes_on_same_post':'SELECT user_id FROM like WHERE user_id IN (SELECT uid FROM #all_friends) AND object_id IN (SELECT object_id FROM like WHERE user_id=me())',"
                       @"'direct_messages':'SELECT author_id FROM message WHERE thread_id IN (SELECT thread_id FROM thread WHERE folder_id = 0) AND author_id IN (SELECT uid FROM #all_friends)',"
                       @"'user_link_on_friends_pictures':'SELECT owner FROM photo WHERE owner != me() AND object_id IN(SELECT object_id FROM photo_tag WHERE subject = me())',"
                       @"'linked_friends_on_own_pictures':'SELECT subject FROM photo_tag WHERE subject != me() AND object_id IN(SELECT object_id FROM photo WHERE owner = me())',"
                       @"'comment_on_user_status':'SELECT fromid FROM comment WHERE object_id IN (SELECT status_id FROM status WHERE uid=me()) AND fromid != me()',"
                       @"}"];
    
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
    
    for (NSDictionary *jsonDict in jsonData) {
        NSString *jsonpart = [jsonDict objectForKey:@"name"];
        NSArray *userIDArray = [jsonDict objectForKey:@"fql_result_set"];
        
        if ([jsonpart isEqualToString:@"users_family"]) {
            NSLog(@"Family Members: %d", [userIDArray count]);
            [self.currentUser setNumberFamilyMembers:[NSNumber numberWithInt:[userIDArray count]]];
            
            [self filterForFamilyMembers:userIDArray];
        }
        
        if ([jsonpart isEqualToString:@"direct_messages"]) {
            NSLog(@"Direct Messages: %d", [userIDArray count]);
            [self.currentUser setNumberDirectMessages:[NSNumber numberWithInt:[userIDArray count]]];
            [self calculateRatingFor:userIDArray withWeight:3];
        }
        
        if ([jsonpart isEqualToString:@"likes_on_user_status"]) {
            NSLog(@"Likes on user status: %d", [userIDArray count]);
            [self.currentUser setNumberLikesOnStatus:[NSNumber numberWithInt:[userIDArray count]]];
            [self calculateRatingFor:userIDArray withWeight:2];
        }
        
        if ([jsonpart isEqualToString:@"likes_on_same_post"]) {
            NSLog(@"Likes on same post: %d", [userIDArray count]);
            
            [self calculateRatingFor:userIDArray withWeight:1];
        }
        
        if ([jsonpart isEqualToString:@"user_link_on_friends_pictures"]) {
            NSLog(@"Tags for user on pictures posted by friends: %d", [userIDArray count]);
            
            [self.currentUser setNumberOfTagedOnFriendsPictures:[NSNumber numberWithInt:[userIDArray count]]];
            //TODO dynamische anpassung
            [self calculateRatingFor:userIDArray withWeight:3];
        }
        
        if ([jsonpart isEqualToString:@"linked_friends_on_own_pictures"]) {
            NSLog(@"Friends taged on users pictures: %d", [userIDArray count]);
            [self.currentUser setNumberOfTagedFriends:[NSNumber numberWithInt:[userIDArray count]]];
            [self calculateRatingFor:userIDArray withWeight:4];
        }
        
        if ([jsonpart isEqualToString:@"comment_on_user_status"]) {
            NSLog(@"Friends comments on users status: %d", [userIDArray count]);
            [self.currentUser setNumberOfCommentsOnStatus:[NSNumber numberWithInt:[userIDArray count]]];
            [self calculateRatingFor:userIDArray withWeight:3];
        }
    }

    [self.startViewController calculationSuccessful];
}


- (void)createFriendEntities:(NSArray *)friends {
    for (NSDictionary* friendDict in friends) {
        Friend *friend = [NSEntityDescription insertNewObjectForEntityForName:@"Friend" inManagedObjectContext:self.managedObjectContext];
        [friend setUid:[NSString stringWithFormat:@"%@",[friendDict valueForKey:@"uid"]]];
        [friend setFirstName:[friendDict valueForKey:@"first_name"]];
        [friend setLastName:[friendDict valueForKey:@"last_name"]];
        [friend setGender:[friendDict valueForKey:@"sex"]];
        [friend setPictureURL:[NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?width=200&height=200", friend.uid]];
        
        
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

- (void)filterForFamilyMembers:(NSArray *)familyMembers{
    NSFetchRequest *request;
    NSEntityDescription *entity;
    NSPredicate *predicate;
    NSArray *resultArray;
    
    for (NSDictionary *uidDict in familyMembers) {
        NSString *uid = [[uidDict allValues] objectAtIndex:0];
        
        request = [[NSFetchRequest alloc] init];
        entity = [NSEntityDescription entityForName:@"Friend" inManagedObjectContext:self.managedObjectContext];
        [request setEntity:entity];
        predicate = [NSPredicate predicateWithFormat: @"uid == %@", uid];
        [request setPredicate:predicate];
        resultArray = [self.managedObjectContext executeFetchRequest:request error:nil];
        
        if ([resultArray count] > 0){
            Friend *friend = [resultArray objectAtIndex:0];
            friend.isFamilyMember = [NSNumber numberWithBool:YES];
            [self saveContext];
        }
    }
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
        
        if ([resultArray count] > 0){
            Friend *friend = [resultArray objectAtIndex:0];
            friend.rating = [NSNumber numberWithInt:[friend.rating intValue] + weight];
            [self saveContext];
        }
    }
}

- (NSArray *)getFriendsForGender:(NSString *) gender
{
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Friend" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"isFamilyMember == NO && gender LIKE %@", gender];
    [request setPredicate:predicate];
    NSSortDescriptor *ratingDescriptor = [[NSSortDescriptor alloc] initWithKey:@"rating" ascending:NO];
    [request setSortDescriptors:[NSArray arrayWithObject:ratingDescriptor]];
    NSArray *resultArray = [self.managedObjectContext executeFetchRequest:request error:nil];
    
    return resultArray;
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
    if (![self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSLog(@"Unresolved error %@, %@ while deleting and adding new database.", error, [error userInfo]);
        abort();
    }
    
    self.currentUser = nil;
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
