//
//  HDBeaconModel.h
//  PeopleManager
//
//  Created by Scott Rasche on 9/25/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HDBeaconModel : NSObject

@property (nonatomic, strong) NSString *beaconLocation;
@property (nonatomic, strong) NSDate *lastExit;
@property (nonatomic, strong) NSDate *lastEntry;
@property (assign) NSInteger lastReportedSignalStrength;

@end
