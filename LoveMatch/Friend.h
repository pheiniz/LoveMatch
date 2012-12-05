//
//  Friend.h
//  LoveMatch
//
//  Created by Paul Heiniz on 05.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class User;

@interface Friend : NSManagedObject

@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSString * relationshipStatus;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, retain) NSString * pictureURL;
@property (nonatomic, retain) User *user;

@end
