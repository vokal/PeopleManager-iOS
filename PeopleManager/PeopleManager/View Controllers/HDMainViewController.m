//
//  HDMainViewController.m
//  PeopleManager
//
//  Created by Scott Rasche on 9/24/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import "HDMainViewController.h"
#import <Gimbal/Gimbal.h>
#import "HDBeaconManager.h"
#import "HDBeaconModel.h"
#import "HDConstants.h"
#import "HDCloudKitManager.h"
#import "HDUtilities.h"
#import <AudioToolbox/AudioToolbox.h>

@interface HDMainViewController () <BeaconDelegate>

@property (nonatomic, strong) HDBeaconManager *beaconManager;
@property (nonatomic, strong) HDCloudKitManager *cloudManager;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) IBOutlet UILabel *labelLadderRoom;
@property (strong, nonatomic) IBOutlet UILabel *labelReception;
@property (strong, nonatomic) IBOutlet UIButton *buttonSignOut;
@property (strong, nonatomic) IBOutlet UILabel *labelWhereToWork;
@property (strong, nonatomic) IBOutlet UILabel *labelHeader;
@property (strong, nonatomic) IBOutlet UILabel *labelCurrentLocation;

@property (strong, nonatomic) NSString *employeeName;

@property (strong, nonatomic) GMBLPlace *mostCurrentPlace;

@property (strong, nonatomic) HDBeaconModel *strongestBeaconSignal;

@end

@implementation HDMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.textView.text = @"";
    self.beaconManager = [HDBeaconManager sharedInstance];
    self.beaconManager.delegate = self;
    
    self.cloudManager = [HDCloudKitManager sharedInstance];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    
    self.labelLadderRoom.text = @"";
    self.labelReception.text = @"";
    self.buttonSignOut.layer.borderColor = [UIColor whiteColor].CGColor;
    self.buttonSignOut.layer.borderWidth = 2.0;
    self.labelWhereToWork.text = @"";
    
    self.employeeName = [[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_USER_ID];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orderReceived:)
                                                 name:NOTIFICATION_ORDER
                                               object:nil];
    self.title = self.employeeName;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.cloudManager fetchOrdersForPerson:self.employeeName
                                     onDate:[NSDate date]
                      withCompletionHandler:^(NSArray *records, NSError *error) {
                          [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                              if (!error && records.count) {
                                  CKRecord *mostRecentRequest = records.firstObject;
                                  self.labelWhereToWork.text = mostRecentRequest[FIELD_BEACON_REGION];
                                  
                              } else {
                                  self.labelWhereToWork.text = @"No Assignment";
                              }
                          }];
                      }];
    GMBLVisit *currentLocation = self.beaconManager.mostRecentBeaconZoneEntered;
    if (currentLocation) {
        self.labelCurrentLocation.text = currentLocation.place.name;
    } else {
        if (self.mostCurrentPlace) {
            self.labelCurrentLocation.text = self.mostCurrentPlace.name;
        } else {
            self.labelCurrentLocation.text = @"Unknown";
        }
    }
}

#pragma mark - BeaconDelegate

- (void)didEnterPlace:(GMBLPlace *)place
{
    self.strongestBeaconSignal = [[HDBeaconModel alloc] init];
    self.strongestBeaconSignal.beaconLocation = place.name;
    self.strongestBeaconSignal.lastReportedSignalStrength = -90;
    self.strongestBeaconSignal.lastEntry = [NSDate date];
    NSString *text = self.textView.text;
    text = [text stringByAppendingFormat:@"Entering : %@, %@\n", place.name, [self.dateFormatter stringFromDate:[NSDate date]]];
    self.textView.text = text;
    NSString *placeName = place.name;
    if ([place.name isEqualToString:@"Chalk Room"]) {
        placeName = BEACON_RECEPTION;
    }
    self.labelCurrentLocation.text = placeName;
    self.mostCurrentPlace = place;
    [self.cloudManager enteredRegion:YES
                          regionName:placeName
                          withPerson:self.employeeName
                              onDate:[NSDate date]
               withCompletionHandler:^(NSArray *records, NSError *error) {
                   if (!error) {
                       
                   }
               }];
}

- (void)didExitPlace:(GMBLPlace *)place
{
    NSString *text = self.textView.text;
    text = [text stringByAppendingFormat:@"Exiting : %@, %@\n", place.name, [self.dateFormatter stringFromDate:[NSDate date]]];
    self.textView.text = text;
    NSString *placeName = place.name;
    if ([place.name isEqualToString:@"Chalk Room"]) {
        placeName = BEACON_RECEPTION;
    }
    
    [self.cloudManager enteredRegion:NO
                          regionName:placeName
                          withPerson:self.employeeName
                              onDate:[NSDate date]
               withCompletionHandler:^(NSArray *records, NSError *error) {
                   if (error) {
                       
                   }
               }];
}

- (void)didSightBeacon:(GMBLBeaconSighting *)beaconSighting
{
    NSString *name = beaconSighting.beacon.name;
    if (self.strongestBeaconSignal) {
        if (![beaconSighting.beacon.name isEqualToString:self.strongestBeaconSignal.beaconLocation] && beaconSighting.RSSI > self.strongestBeaconSignal.lastReportedSignalStrength) {
            self.strongestBeaconSignal = [[HDBeaconModel alloc] init];
            self.strongestBeaconSignal.beaconLocation = beaconSighting.beacon.name;
            self.strongestBeaconSignal.lastReportedSignalStrength = beaconSighting.RSSI;
            self.strongestBeaconSignal.lastEntry = [NSDate date];
            [self.cloudManager enteredRegion:YES
                                  regionName:self.strongestBeaconSignal.beaconLocation
                                  withPerson:self.employeeName
                                      onDate:[NSDate date]
                       withCompletionHandler:^(NSArray *records, NSError *error) {
                           if (!error) {
                               
                           }
                       }];
            
        }
    } else {
        self.strongestBeaconSignal = [[HDBeaconModel alloc] init];
        self.strongestBeaconSignal.beaconLocation = beaconSighting.beacon.name;
        self.strongestBeaconSignal.lastReportedSignalStrength = beaconSighting.RSSI;
        self.strongestBeaconSignal.lastEntry = [NSDate date];
        [self.cloudManager enteredRegion:YES
                              regionName:self.strongestBeaconSignal.beaconLocation
                              withPerson:self.employeeName
                                  onDate:[NSDate date]
                   withCompletionHandler:^(NSArray *records, NSError *error) {
                       if (!error) {
                           
                       }
                   }];
    }
    
    self.labelCurrentLocation.text = self.strongestBeaconSignal.beaconLocation;
    if ([name isEqualToString:BEACON_LADDER_ROOM]) {
        self.labelLadderRoom.text = [NSString stringWithFormat:@"Ladder : %ld", beaconSighting.RSSI];
    } else {
        self.labelReception.text = [NSString stringWithFormat:@"Reception : %ld", beaconSighting.RSSI];
    }
}

#pragma mark - IBActions

- (IBAction)signOutPressed:(UIButton *)sender
{
    self.buttonSignOut.enabled = NO;
    [self.cloudManager signIn:NO
                   withPerson:self.employeeName
                       onDate:[NSDate date]
        withCompletionHandler:^(NSArray *records, NSError *error) {
            if (!error) {
                [HDUtilities showSystemWideAlertWithError:NO message:@"Have a Good Night!"];
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }];
                [self.cloudManager deleteSignedInStatusForPerson:self.employeeName withCompletionHandler:^(NSArray *records, NSError *error) {
                    
                }];
                
            } else {
                [HDUtilities showSystemWideAlertWithError:YES message:error.localizedDescription];
            }
        }];
}

#pragma mark - notifications

- (void)orderReceived:(NSNotification *)notification
{
    NSLog(@"notification = %@", notification.userInfo);
    
    [self.cloudManager fetchOrdersForPerson:self.employeeName
                                     onDate:[NSDate date]
                      withCompletionHandler:^(NSArray *records, NSError *error) {
                          if (records.count) {
                              CKRecord *order = records.firstObject;
                              NSString *loc = order[FIELD_BEACON_REGION];
                              
                              [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                                  NSString *message = [NSString stringWithFormat:@"Go to %@!!!", loc];
                                  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Orders Recevied"
                                                                                                 message:message
                                                                                          preferredStyle:UIAlertControllerStyleAlert];
                                  UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
                                  [alert addAction:ok];
                                  [self presentViewController:alert animated:YES completion:nil];
                                  
                                  [self playSound];
                              }];
                          }
                      }];
}

- (void)playSound
{
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"fired" ofType:@"m4a"];
    SystemSoundID soundID;
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: soundPath], &soundID);
    AudioServicesPlaySystemSound (soundID);
}

@end
