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


@end

@implementation LMRatingsTableViewController

static int startButtonHeight = 50;
static int startButtonWidth = 50;

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
    

    _startViewButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - startButtonWidth - 10,self.view.frame.size.height - startButtonHeight,startButtonWidth ,startButtonHeight)];
    
    // Configure your view here.
    _startViewButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.7 blue:0.8 alpha:0.75];
    [_startViewButton addTarget:self
                                action:@selector(presentStartView)
                      forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_startViewButton];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[LMDataConnector sharedInstance] currentUser])
    {
        return;
    }
    
    LMStartViewController *startViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"StartView"];
    [self presentViewController:startViewController animated:NO completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGRect newFrame = _startViewButton.frame;
    newFrame.origin.x = self.view.frame.size.width - startButtonWidth - 10;
    newFrame.origin.y = self.tableView.contentOffset.y+(self.tableView.frame.size.height-startButtonHeight);
    _startViewButton.frame = newFrame;
}

- (void)presentStartView
{
    [self performSegueWithIdentifier:@"ShowStartView" sender:self];
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
    LMFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Friend *friend = [_friends objectAtIndex:indexPath.row];
    
    [cell.nameLabel setText:[NSString stringWithFormat:@"%@ %@", friend.firstName, friend.lastName]];
    [cell.ratingsLabel setText:[NSString stringWithFormat:@"%@", friend.rating]];
    
    if (![friend.relationshipStatus isEqualToString:@"Single"]){
        cell.relationshipIcon.hidden = NO;
    }else{
        cell.relationshipIcon.hidden = YES;
    }
    [cell.relationshipLabel setText:friend.relationshipStatus];
    [cell.pictureImageView setImageWithURL:[NSURL URLWithString:friend.pictureURL]];
    [cell.cellBackground setBackgroundColor: [UIColor colorWithRed:(255.0 - friend.rating.floatValue)/255.0 green:friend.rating.floatValue/255.0 blue:0.0/255.0 alpha:1.0]];
    [[cell.cellBackground layer] setBorderWidth:3];
    
    
    
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

//// Override to support rearranging the table view.
//- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
//{
//}

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

- (void)tableView:(UITableView *)tableView
	 exchangeCell:(UITableViewCell *)cell1 atIndexPath:(NSIndexPath *)indexPath1
		 withCell:(UITableViewCell *)cell2 atIndexPath:(NSIndexPath *)indexPath2 {
//	NSMutableArray *sectionArray1 = [self.sections objectAtIndex:indexPath1.section];
//	NSMutableArray *sectionArray2 = [self.sections objectAtIndex:indexPath2.section];
//	
//	Friend *string1 = [[[sectionArray1 objectAtIndex:indexPath1.row] retain] autorelease];
//	NSString *string2 = [[[sectionArray2 objectAtIndex:indexPath2.row] retain] autorelease];
//	
//	[sectionArray1 replaceObjectAtIndex:indexPath1.row withObject:string2];
//	[sectionArray2 replaceObjectAtIndex:indexPath2.row withObject:string1];
//	
//	cell1.textLabel.text = string2;
//	cell2.textLabel.text = string1;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (IBAction)test:(id)sender {
    [self.tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
						   toIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
}
@end
