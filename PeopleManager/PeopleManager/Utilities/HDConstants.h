//
//  HDConstants.h
//  PeopleManager
//
//  Created by Scott Rasche on 9/24/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const SOUND_ENTERED_REGION;
FOUNDATION_EXPORT NSString *const SOUND_EXITED_REGION;
FOUNDATION_EXPORT NSString *const NOTIFICATION_IDENTIFIER_EXIT;
FOUNDATION_EXPORT NSString *const NOTIFICATION_IDENTIFIER_ENTER;
FOUNDATION_EXPORT NSString *const GIMBAL_API_KEY;
FOUNDATION_EXPORT NSString *const BEACON_LADDER_ROOM;
FOUNDATION_EXPORT NSString *const BEACON_RECEPTION;
FOUNDATION_EXPORT NSString *const BEACON_UUID;

// cloud kit
FOUNDATION_EXPORT NSString *const RECORD_TYPE_PERSON_ACTIVITY;
FOUNDATION_EXPORT NSString *const FIELD_NAME;
FOUNDATION_EXPORT NSString *const FIELD_ACTIVITY;
FOUNDATION_EXPORT NSString *const FIELD_BEACON_REGION;
FOUNDATION_EXPORT NSString *const FIELD_DATE_ADDED;
FOUNDATION_EXPORT NSString *const ACTIVITY_ENTERED;
FOUNDATION_EXPORT NSString *const ACTIVITY_EXITED;
FOUNDATION_EXPORT NSString *const RECORD_TYPE_MESSAGE;
FOUNDATION_EXPORT NSString *const FIELD_MESSAGE;
FOUNDATION_EXPORT NSString *const FIELD_FROM_NAME;
FOUNDATION_EXPORT NSString *const FIELD_TO_NAME;
FOUNDATION_EXPORT NSString *const FIELD_DATE_SENT;
FOUNDATION_EXPORT NSString *const DEFAULTS_RESEND_QUEUE;
FOUNDATION_EXPORT NSString *const SUBSCRIPTION_ADD_ACTIVITY;
FOUNDATION_EXPORT NSString *const SUBSCRIPTION_ADD_MESSAGE;

@interface HDConstants : NSObject

@end
