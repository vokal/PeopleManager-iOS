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

@interface HDMainViewController () <BeaconDelegate>

@property (nonatomic, strong) HDBeaconManager *beaconManager;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) IBOutlet UILabel *labelLadderRoom;
@property (strong, nonatomic) IBOutlet UILabel *labelChalkRoom;

@end

@implementation HDMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.textView.text = @"";
    self.beaconManager = [HDBeaconManager sharedInstance];
    self.beaconManager.delegate = self;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    self.labelLadderRoom.text = @"";
    self.labelChalkRoom.text = @"";
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
}

- (void)didExitPlace:(GMBLPlace *)place
{
    NSString *text = self.textView.text;
    text = [text stringByAppendingFormat:@"Exiting : %@, %@\n", place.name, [self.dateFormatter stringFromDate:[NSDate date]]];
    self.textView.text = text;
}

- (void)didSightBeacon:(GMBLBeaconSighting *)beaconSighting
{
    NSString *name = beaconSighting.beacon.name;
    if ([name isEqualToString:BEACON_LADDER_ROOM]) {
        self.labelLadderRoom.text = [NSString stringWithFormat:@"Ladder power : %ld",beaconSighting.RSSI];
    }
    else {
        self.labelChalkRoom.text = [NSString stringWithFormat:@"Chalk power : %ld",beaconSighting.RSSI];
    }
}

@end
