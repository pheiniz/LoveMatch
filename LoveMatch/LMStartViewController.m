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
#import "LMDataConnector.h"
#import "ATMHud.h"


@interface LMStartViewController ()

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) ATMHud *hud;

@property (weak, nonatomic) IBOutlet UIButton *statsForUserButton;

@property (nonatomic, strong)  NSString *friendsGender;


- (IBAction)startFBSearchForFemale:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *femaleButton;
- (IBAction)startFBSearchForMale:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *maleButton;
- (IBAction)startFBSearchForAll:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *allGenderButton;
- (IBAction)statsForUser:(id)sender;
- (IBAction)logout:(id)sender;

- (void)openSession;
- (void)showLoginView;

@end

@implementation LMStartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _hud = [[ATMHud alloc] initWithDelegate:self];
    [self.view addSubview:_hud.view];
    [_hud setFixedSize:CGSizeZero];
    
    if ([[LMDataConnector sharedInstance] getCurrentUser]){
        UIImage *userPhoto = [UIImage imageWithData:[[[LMDataConnector sharedInstance] getCurrentUser] pictureIcon]];	
        [self.statsForUserButton setBackgroundImage:userPhoto forState:UIControlStateNormal];
    }
    
    [self.maleButton.layer setBorderWidth:1];
    [self.femaleButton.layer setBorderWidth:1];
    [self.allGenderButton.layer setBorderWidth:1];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];

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
        LMLoginViewController *loginViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginView"];
        [self presentViewController:loginViewController animated:NO completion:nil];
        [loginViewController setStartViewController:self];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
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
    
    [LMDataConnector.sharedInstance calculateDataForView:self];
}


- (void)calculationSuccessful {
    [self.statsForUserButton setBackgroundImage:[UIImage imageWithData:[[[LMDataConnector sharedInstance] getCurrentUser] pictureIcon]] forState:UIControlStateNormal];
    [_hud setCaption:@"Your ratings are ready.\nEnjoy!"];
	[_hud setActivity:NO];
	[_hud setImage:[UIImage imageNamed:@"19-check"]];
	[_hud update];
	[_hud hideAfter:2.0];
}

- (void)startHud {
    // set hud and block the view as long as data is loading
    [_hud setBlockTouches:YES];
    [_hud setCaption:@"We are now calculating the rating for you and your friends.\nThis might take a few seconds.\nBut we are almost done!"];
    [_hud setActivity:YES];
    [_hud show];
}



- (IBAction)startFBSearchForFemale:(id)sender {
    
    self.friendsGender = @"female";

    [self refreshTableView];

}

- (IBAction)startFBSearchForMale:(id)sender {
    
    self.friendsGender = @"male";

    [self refreshTableView];

}

- (IBAction)startFBSearchForAll:(id)sender {
    
    self.friendsGender = @"*";

    [self refreshTableView];
}

- (IBAction)statsForUser:(id)sender {

    User *currentUser = [[LMDataConnector sharedInstance] getCurrentUser];
    [_hud setFixedSize:CGSizeMake(260, 300)];
    int maleFriends = [[[LMDataConnector sharedInstance] getFriendsForGender:@"male"] count];
    float malePercent = ((float)maleFriends / (float)currentUser.friends.count)*100.0;
    int femaleFriends = [[[LMDataConnector sharedInstance] getFriendsForGender:@"female"] count];
    float femalePercent = ((float)femaleFriends / (float)currentUser.friends.count)*100.0;
    int transFriends = currentUser.friends.count - femaleFriends - maleFriends;
    float transPercent = ((float)transFriends / (float)currentUser.friends.count)*100.0;
    NSString *userInformation = [NSString stringWithFormat: @"Hi %@\nwe see you have %i friends\n%i are female (%.f%%)\n%i are male (%.f%%) and\n%i of your friends are somewhat uncertain about their gender (%.f%%)\n\n We found\n%i direct messages between you and your friends\n and you were liked %i times.\nYou tagged your friends %i times on your pictures while\nyour friends tagged you %i times on theirs.",currentUser.firstName, currentUser.friends.count, femaleFriends, femalePercent, maleFriends, malePercent, transFriends, transPercent, currentUser.numberDirectMessages.intValue, currentUser.numberLikesOnStatus.intValue, currentUser.numberOfTagedFriends.intValue, currentUser.numberOfTagedOnFriendsPictures.intValue];
    [_hud setCaption:userInformation];
	[_hud setActivity:NO];
	[_hud show];
    [_hud setFixedSize:CGSizeZero];
    
}

- (IBAction)logout:(id)sender {
    
    [_hud setCaption:@"Bye bye!"];
	[_hud setActivity:NO];
	[_hud show];
	[_hud hideAfter:2.0];
    
    [FBSession.activeSession close];
    [[LMDataConnector sharedInstance] deleteDatabase];
    [self performSelector:@selector(showLoginView) withObject:nil afterDelay:3.0];
}

- (void)openSession
{
    
    NSArray *permissions =
    [NSArray arrayWithObjects:@"user_photos", @"friends_photos", @"read_stream", @"read_mailbox", @"user_relationships", @"friends_relationships", nil];
    
    [FBSession openActiveSessionWithReadPermissions:permissions
                                       allowLoginUI:YES
                                  completionHandler:
     ^(FBSession *session,
       FBSessionState state, NSError *error) {
         [self sessionStateChanged:session state:state error:error];
     }];
}

- (void)refreshTableView
{
    LMRatingsTableViewController *ratingTableViewController = (LMRatingsTableViewController *)[self presentingViewController];
    
    [ratingTableViewController setFriends:[NSMutableArray arrayWithArray:[[LMDataConnector sharedInstance] getFriendsForGender:self.friendsGender]]];
    [ratingTableViewController.tableView reloadData];
    //[ratingTableViewController.tableView sizeToFit];
    [ratingTableViewController changeGenderTo:self.friendsGender];
    
    [self dismissViewControllerAnimated:YES completion:nil];
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
    if ([[segue identifier] isEqualToString:@"ShowLoginView"])
    {
        LMLoginViewController *loginViewController = [segue destinationViewController];
        [loginViewController setStartViewController:self];
    }
}

#pragma mark -
#pragma mark ATMHudDelegate
- (void)userDidTapHud:(ATMHud *)hud {
	[hud hide];
}

@end
