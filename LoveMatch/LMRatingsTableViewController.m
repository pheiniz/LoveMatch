//
//  LMRatingsTableViewController.m
//  LoveMatch
//
//  Created by Paul Heiniz on 05.12.12.
//  Copyright (c) 2012 nerdburgers. All rights reserved.
//

#import "LMRatingsTableViewController.h"

@interface LMRatingsTableViewController ()

@property (nonatomic, strong) UIButton *startViewButton;
@property (nonatomic, strong) NSString *gender;


@end

@implementation LMRatingsTableViewController

static int startButtonHeight = 35;
static int startButtonWidth = 71;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _startViewButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - startButtonWidth,self.view.frame.size.height - startButtonHeight,startButtonWidth ,startButtonHeight)];
    
    // Configure your view here.
    [_startViewButton setImage:[UIImage imageNamed:@"up"] forState:UIControlStateNormal];
    [_startViewButton addTarget:self
                                action:@selector(presentStartView)
                      forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_startViewButton];

}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (![[LMDataConnector sharedInstance] getCurrentUser] || !self.gender)
    {
        LMStartViewController *startViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"StartView"];
        [self presentViewController:startViewController animated:NO completion:nil];
    }
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGRect newFrame = _startViewButton.frame;
    newFrame.origin.x = self.view.frame.size.width - startButtonWidth;
    newFrame.origin.y = self.tableView.contentOffset.y+(self.tableView.frame.size.height-startButtonHeight);
    _startViewButton.frame = newFrame;
}

- (void)presentStartView
{
    [self performSegueWithIdentifier:@"ShowStartView" sender:self];
}

- (void)changeGenderTo:(NSString *)gender{
    if (![gender isEqualToString:self.gender]) {
        [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        self.gender = gender;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [_friends count];
}

- (LMFriendCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"FriendCell";
    int position = indexPath.row;
    LMFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Friend *friend = [_friends objectAtIndex:position];
    
    [cell.positionLabel setText:[NSString stringWithFormat:@"%i", position + 1]];
    if (position == 0){
        //[cell.positionImageView setImage:[UIImage imageNamed:@"circle_golden"]];
        [cell.positionImageView setBackgroundColor:[UIColor colorWithRed:210.0/255.0 green:210.0/255.0 blue:210.0/255.0 alpha:1]];
        [cell.positionImageView.layer setCornerRadius:20];
        [cell.positionImageView.layer setBorderWidth:3];
    }else{
        //[cell.positionImageView setImage:[UIImage imageNamed:@"circle_blue"]];
        [cell.positionImageView setBackgroundColor:[UIColor colorWithRed:210.0/255.0 green:210.0/255.0 blue:210.0/255.0 alpha:1]];
        [cell.positionImageView.layer setCornerRadius:20];
        [cell.positionImageView.layer setBorderWidth:3];
    }
    
    [cell.nameLabel setText:[NSString stringWithFormat:@"%@ %@", friend.firstName, friend.lastName]];
    [cell.ratingsLabel setText:[NSString stringWithFormat:@"%@", friend.rating]];
    
    cell.relationshipLabel.text = friend.relationshipStatus;
    
    if ([friend.relationshipStatus isEqualToString:@"Single"]||[friend.relationshipStatus isEqualToString:@"In an open Relationship"]||[friend.relationshipStatus isEqualToString:@"In an open Relationship"]){
        //supergreen, ok to date
        cell.relationshipLabel.textColor = [UIColor colorWithRed:78.0/255.0 green:102.0/255.0 blue:25.0/255.0 alpha:1];
    
    }else if ([friend.relationshipStatus isEqualToString:@"It's complicated"]||[friend.relationshipStatus isEqualToString:@"In an open Relationship"]){
        //blue, uncertain
        cell.relationshipLabel.textColor = [UIColor colorWithRed:2.0/255.0 green:127.0/255.0 blue:191.0/255.0 alpha:1];
    
    }else if ([friend.relationshipStatus isEqualToString:@"In a Relationship"]){
        //lightred, attention
        cell.relationshipLabel.textColor = [UIColor colorWithRed:217.0/255.0 green:48.0/255.0 blue:48.0/255.0 alpha:1];

    }else if ([friend.relationshipStatus isEqualToString:@"Engaged"]){
        //red, complicated
        cell.relationshipLabel.textColor = [UIColor colorWithRed:153.0/255.0 green:34.0/255.0 blue:34.0/255.0 alpha:1];
    
    }else if ([friend.relationshipStatus isEqualToString:@"Married"]||[friend.relationshipStatus isEqualToString:@"In a domestic partnership"]||[friend.relationshipStatus isEqualToString:@"In a civil partnership"]||[friend.relationshipStatus isEqualToString:@"In a civil union"]){
        //darkred, nogo
        cell.relationshipLabel.textColor = [UIColor colorWithRed:115.0/255.0 green:7.0/255.0 blue:16.0/255.0 alpha:1];
    }
    
    [cell.pictureImageView setImageWithURL:[NSURL URLWithString:friend.pictureURL]];
    
    [cell.pictureImageView.layer setCornerRadius:6];
    [cell.pictureBackground.layer setCornerRadius:6];

    [[cell.cellBackground layer] setBorderColor:[[UIColor blackColor] CGColor]];
    [[cell.cellBackground layer] setBorderWidth:3];
    
    
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) // Don't move the first row
        return NO;
    
    return YES;
}

- (void)tableView:(UITableView *)tableView
		 moveCell:(UITableViewCell *)cell
	fromIndexPath:(NSIndexPath *)fromIndexPath
	  toIndexPath:(NSIndexPath *)toIndexPath {
	Friend *friendToMove = [self.friends objectAtIndex:fromIndexPath.row];
	[_friends removeObjectAtIndex:fromIndexPath.row];
	[_friends insertObject:friendToMove atIndex:toIndexPath.row];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *url = [NSString stringWithFormat:@"http://www.facebook.com/profile.php?id=%@", (Friend *)[[_friends objectAtIndex:indexPath.row] uid]];
    SVModalWebViewController *webViewController = [[SVModalWebViewController alloc] initWithAddress:url];
    [webViewController setBarsTintColor:[UIColor darkGrayColor]];
    [self presentViewController:webViewController animated:YES completion:nil];

}

- (IBAction)test:(id)sender {
    [self.tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
						   toIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
}
@end
