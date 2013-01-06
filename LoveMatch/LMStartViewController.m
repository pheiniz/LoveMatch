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

@property (nonatomic, strong) User *currentUser;
@property (weak, nonatomic) IBOutlet UIButton *statsForUserButton;

@property (nonatomic, strong)  NSString *friendsGender;


- (IBAction)startFBSearchForFemale:(id)sender;
- (IBAction)startFBSearchForMale:(id)sender;
- (IBAction)startFBSearchForAll:(id)sender;
- (IBAction)statsForUser:(id)sender;
- (IBAction)logout:(id)sender;

- (void)openSession;
- (void)showLoginView;

@end

@implementation LMStartViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _hud = [[ATMHud alloc] initWithDelegate:nil];
    [self.view addSubview:_hud.view];
    [_hud setFixedSize:CGSizeZero];
    
    if ([[LMDataConnector sharedInstance] currentUser]){
        [self.statsForUserButton setBackgroundImage:[UIImage imageWithData:[[[LMDataConnector sharedInstance] currentUser] pictureIcon]] forState:UIControlStateNormal];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([[LMDataConnector sharedInstance] currentUser]){
        [self.statsForUserButton setBackgroundImage:[UIImage imageWithData:[[[LMDataConnector sharedInstance] currentUser] pictureIcon]] forState:UIControlStateNormal];
    }
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
            
            //[self showLoginView];
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
    [self.statsForUserButton setBackgroundImage:[UIImage imageWithData:[[[LMDataConnector sharedInstance] currentUser] pictureIcon]] forState:UIControlStateNormal];
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
    
}

- (IBAction)logout:(id)sender {
    
    [_hud setCaption:@"Bye bye!"];
	[_hud setActivity:NO];
	[_hud show];
	[_hud hideAfter:2.0];
    
    [FBSession.activeSession close];
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
    if ([[segue identifier] isEqualToString:@"ShowRatingsTableView"])
    {
        LMRatingsTableViewController *ratingTableViewController = (LMRatingsTableViewController *)[self presentingViewController];
            
            

        [ratingTableViewController setFriends:[NSMutableArray arrayWithArray:[[LMDataConnector sharedInstance] getFriendsForGender:self.friendsGender]]];
        
    }else if ([[segue identifier] isEqualToString:@"ShowLoginView"])
    {
        LMLoginViewController *loginViewController = [segue destinationViewController];
        [loginViewController setStartViewController:self];
    }
}

@end
