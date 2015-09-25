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
#import "HDConstants.h"
#import "HDCloudKitManager.h"

@interface HDMainViewController () <BeaconDelegate>

@property (nonatomic, strong) HDBeaconManager *beaconManager;
@property (nonatomic, strong) HDCloudKitManager *cloudManager;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) IBOutlet UILabel *labelLadderRoom;
@property (strong, nonatomic) IBOutlet UILabel *labelReception;

@end

@implementation HDMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textView.text = @"";
    self.beaconManager = [HDBeaconManager sharedInstance];
    self.beaconManager.delegate = self;
    
    self.cloudManager = [HDCloudKitManager sharedInstance];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    
    self.labelLadderRoom.text = @"";
    self.labelReception.text = @"";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

#pragma mark - BeaconDelegate

- (void)didEnterPlace:(GMBLPlace *)place
{
    NSString *text = self.textView.text;
    text = [text stringByAppendingFormat:@"Entering : %@, %@\n", place.name, [self.dateFormatter stringFromDate:[NSDate date]]];
    self.textView.text = text;
    NSString *placeName = place.name;
    if ([place.name isEqualToString:@"Chalk Room"]) {
        placeName = BEACON_RECEPTION;
    }
    [self.cloudManager enteredRegion:YES
                          regionName:placeName
                          withPerson:@"Skip"
                              onDate:[NSDate date]
               withCompletionHandler:^(NSArray *records, NSError *error) {
                   
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
                          withPerson:@"Skip"
                              onDate:[NSDate date]
               withCompletionHandler:^(NSArray *records, NSError *error) {
                   
               }];
}

- (void)didSightBeacon:(GMBLBeaconSighting *)beaconSighting
{
    NSString *name = beaconSighting.beacon.name;
    if ([name isEqualToString:BEACON_LADDER_ROOM]) {
        self.labelLadderRoom.text = [NSString stringWithFormat:@"Ladder : %ld", beaconSighting.RSSI];
    } else {
        self.labelReception.text = [NSString stringWithFormat:@"Reception : %ld", beaconSighting.RSSI];
    }
}

@end
