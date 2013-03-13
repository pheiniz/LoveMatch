//
//  User.h
//  LoveMatch
//
//  Created by Paul Heiniz on 19.02.13.
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
@property (nonatomic, retain) NSData * pictureIcon;
@property (nonatomic, retain) NSString * pictureURL;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSNumber * numberLikesOnStatus;
@property (nonatomic, retain) NSNumber * numberDirectMessages;
@property (nonatomic, retain) NSNumber * numberFamilyMembers;
@property (nonatomic, retain) NSNumber * numberOfTagedFriends;
@property (nonatomic, retain) NSNumber * numberOfTagedOnFriendsPictures;
@property (nonatomic, retain) NSSet *friends;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addFriendsObject:(Friend *)value;
- (void)removeFriendsObject:(Friend *)value;
- (void)addFriends:(NSSet *)values;
- (void)removeFriends:(NSSet *)values;

@end
