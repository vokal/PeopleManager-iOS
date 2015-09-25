//
//  HDBeaconManager.h
//  PeopleManager
//
//  Created by Scott Rasche on 9/24/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import <Foundation/Foundation.h>
@class GMBLPlace;
@class GMBLBeaconSighting;
@class GMBLVisit;

@protocol BeaconDelegate <NSObject>

- (void)didEnterPlace:(GMBLPlace *)place;
- (void)didExitPlace:(GMBLPlace *)place;
- (void)didSightBeacon:(GMBLBeaconSighting *)beaconSighting;

@end

@interface HDBeaconManager : NSObject

+ (HDBeaconManager *)sharedInstance;

@property (nonatomic, weak) id <BeaconDelegate> delegate;
@property (nonatomic, strong, readonly) GMBLVisit *mostRecentBeaconZoneEntered;
@property (nonatomic, strong, readonly) GMBLVisit *mostRecentBeaconZoneExited;

@end
