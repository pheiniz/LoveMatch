//
//  LMFriendCell.h
//  LoveMatch
//
//  Created by Paul Heiniz on 05.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMFriendCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *pictureImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratingsLabel;
@property (weak, nonatomic) IBOutlet UILabel *relationshipLabel;

@end
