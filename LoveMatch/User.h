//
//  User.h
//  LoveMatch
//
//  Created by Paul Heiniz on 02.01.13.
//  Copyright (c) 2013 nerdburgers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Friend;

@interface User : NSManagedObject

@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * interestedIn;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * pictureURL;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSData * pictureIcon;
@property (nonatomic, retain) NSSet *friends;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addFriendsObject:(Friend *)value;
- (void)removeFriendsObject:(Friend *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

@end
