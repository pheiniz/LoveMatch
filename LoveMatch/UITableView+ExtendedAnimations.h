//
//  UITableView+ExtendedAnimations.h
//  TableViewExtAnimations
//
//  Created by Алексеев Влад on 08.07.11.
//  Copyright 2011 beefon software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UITableViewExtendedDelegate <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView 
	 exchangeCell:(UITableViewCell *)cell1 atIndexPath:(NSIndexPath *)indexPath1 
		 withCell:(UITableViewCell *)cell2 atIndexPath:(NSIndexPath *)indexPath2;

- (void)tableView:(UITableView *)tableView 
		 moveCell:(UITableViewCell *)cell 
	fromIndexPath:(NSIndexPath *)fromIndexPath 
	  toIndexPath:(NSIndexPath *)toIndexPath;

- (void)tableView:(UITableView *)tableView transitionDeletedCellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView transitionInsertedCellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@interface UITableView (ExtendedAnimations)

- (void)moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;
- (void)transitRowAtIndexPath:(NSIndexPath *)fromIndexPath toRowIndexPath:(NSIndexPath *)toIndexPath;
- (void)exchangeRowAtIndexPath:(NSIndexPath *)indexPath1 withRowAtIndexPath:(NSIndexPath *)indexPath2;

@end
