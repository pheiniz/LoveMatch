//
//  Friend.h
//  LoveMatch
//
//  Created by Paul Heiniz on 04.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Friend : NSManagedObject

@property (nonatomic, retain) NSString * gender;
@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * firstName;
@property (nonatomic, retain) NSNumber * inRelationship;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSNumber * rating;
@property (nonatomic, retain) NSManagedObject *user;

@end
