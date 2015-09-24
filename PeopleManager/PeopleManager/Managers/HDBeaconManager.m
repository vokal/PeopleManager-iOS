 //
//  HDBeaconManager.m
//  PeopleManager
//
//  Created by Scott Rasche on 9/24/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import "HDBeaconManager.h"
#import <CoreLocation/CoreLocation.h>
#import <Gimbal/Gimbal.h>
#import "HDConstants.h"

@interface HDBeaconManager() <CLLocationManagerDelegate, GMBLPlaceManagerDelegate, GMBLCommunicationManagerDelegate>

@property (nonatomic, strong) CLCircularRegion *vokalRegion;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) GMBLPlaceManager *placeManager;
@property (nonatomic) GMBLCommunicationManager *communicationManager;

@end

@implementation HDBeaconManager

+ (HDBeaconManager *)sharedInstance
{
    static HDBeaconManager *beaconManager;
    if (!beaconManager) {
        beaconManager = [[HDBeaconManager alloc] init];
        beaconManager.vokalRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(41.8922513, -87.63329269999997) radius:500 identifier:@"Vokal"];
        beaconManager.locationManager = [[CLLocationManager alloc] init];
        beaconManager.locationManager.delegate = beaconManager;
        [beaconManager.locationManager startMonitoringForRegion:beaconManager.vokalRegion];
        
        [Gimbal setAPIKey:GIMBAL_API_KEY options:nil];
        
        beaconManager.placeManager = [GMBLPlaceManager new];
        beaconManager.placeManager.delegate = beaconManager;
        
        beaconManager.communicationManager = [GMBLCommunicationManager new];
        beaconManager.communicationManager.delegate = beaconManager;
        
        [GMBLPlaceManager startMonitoring];
        [GMBLCommunicationManager startReceivingCommunications];
    }
    return beaconManager;
}

# pragma mark - Gimbal PlaceManager delegate methods

- (void)placeManager:(GMBLPlaceManager *)manager didBeginVisit:(GMBLVisit *)visit
{
    [self.delegate didEnterPlace:visit.place];
    UILocalNotification *note1 = [[UILocalNotification alloc] init];
    note1.alertBody = [NSString stringWithFormat:@"Entered %@", visit.place.name];
    note1.alertAction = @"Entered Region";
    note1.soundName = SOUND_ENTERED_REGION;
    note1.userInfo = [NSDictionary dictionaryWithObject:visit.place.name forKey:NOTIFICATION_IDENTIFIER_ENTER];
    [[UIApplication sharedApplication] presentLocalNotificationNow:note1];
    NSLog(@"Entered region : %@", visit.place.name);
    NSLog(@"Notification : %@", note1);
    note1.applicationIconBadgeNumber = 0;
}

- (void)placeManager:(GMBLPlaceManager *)manager didEndVisit:(GMBLVisit *)visit
{
    [self.delegate didExitPlace:visit.place];
    UILocalNotification *note1 = [[UILocalNotification alloc] init];
    NSString *exitPlace = visit.place.name;
    if ([visit.place.name isEqualToString:@"Chalk Room"]) {
        exitPlace = BEACON_RECEPTION;
    }
    note1.alertBody = [NSString stringWithFormat:@"Exited %@", exitPlace];
    note1.alertAction = @"Exited Region";
    note1.soundName = SOUND_EXITED_REGION;
    note1.userInfo = [NSDictionary dictionaryWithObject:visit.place.name forKey:NOTIFICATION_IDENTIFIER_EXIT];
    [[UIApplication sharedApplication] presentLocalNotificationNow:note1];
    NSLog(@"Exited region : %@", visit.place.name);
    NSLog(@"Notification : %@", note1);
    note1.applicationIconBadgeNumber = 0;
}

- (void)placeManager:(GMBLPlaceManager *)manager didReceiveBeaconSighting:(GMBLBeaconSighting *)sighting forVisits:(NSArray *)visits
{
    [self.delegate didSightBeacon:sighting];
}

# pragma mark - Gimbal CommunicationManager delegate methods

- (NSArray *)communicationManager:(GMBLCommunicationManager *)manager
presentLocalNotificationsForCommunications:(NSArray *)communications
                         forVisit:(GMBLVisit *)visit
{
    NSLog(@"Communications received for : %@", visit.place.name);
    return communications;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region
{
    NSLog(@"didEnterRegion : %@", region.identifier);
    [GMBLPlaceManager startMonitoring];
    [GMBLCommunicationManager startReceivingCommunications];
}

- (void)locationManager:(CLLocationManager *)manager
          didExitRegion:(CLRegion *)region
{
    NSLog(@"did exit = %@", region.identifier);
    [GMBLPlaceManager stopMonitoring];
    [GMBLCommunicationManager stopReceivingCommunications];
    
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error
{
    NSLog(@"Failed : %@", error.localizedDescription);
}

- (void)locationManager:(CLLocationManager *)manager
monitoringDidFailForRegion:(nullable CLRegion *)region
              withError:(NSError *)error
{
    NSLog(@"monitoringDidFailForRegion %@ : %@", error.localizedDescription, region.identifier);
}

@end
