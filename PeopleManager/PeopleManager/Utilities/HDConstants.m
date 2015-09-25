//
//  HDConstants.m
//  PeopleManager
//
//  Created by Scott Rasche on 9/24/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import "HDConstants.h"

NSString *const SOUND_ENTERED_REGION = @"Rooster.m4a";
NSString *const SOUND_EXITED_REGION = @"Cash Register.caf";
NSString *const SOUND_FIRED = @"fired.m4a";

NSString *const NOTIFICATION_IDENTIFIER_EXIT = @"Notification Exit";
NSString *const NOTIFICATION_IDENTIFIER_ENTER = @"Notification Enter";
NSString *const NOTIFICATION_APP_WIDE_ALERT = @"App Wide Alert";
NSString *const KEY_ERROR_APP_WIDE_ALERT = @"Error";
NSString *const KEY_MESSAGE_APP_WIDE_ALERT = @"Message";
NSString *const GIMBAL_API_KEY = @"ba6c77f3-52d6-46f4-ade9-371add3c96b9";
NSString *const BEACON_LADDER_ROOM = @"Ladder Room";
NSString *const BEACON_RECEPTION = @"Reception";
NSString *const BEACON_UUID = @"96C87DF2-DE79-4436-A189-F86FD6C21F3A";
NSString *const DEFAULTS_USER_ID = @"USER_ID";

// cloud kit
NSString *const RECORD_TYPE_PERSON_ACTIVITY = @"PersonActivity";
NSString *const FIELD_NAME = @"Name";
NSString *const FIELD_ACTIVITY = @"Activity";
NSString *const FIELD_BEACON_REGION = @"Region";
NSString *const FIELD_DATE_ADDED = @"DateAdded";
NSString *const ACTIVITY_ENTERED = @"Entered";
NSString *const ACTIVITY_EXITED = @"Exited";

NSString *const RECORD_TYPE_MESSAGE = @"Message";
NSString *const FIELD_MESSAGE = @"Message";
NSString *const FIELD_FROM_NAME = @"From";
NSString *const FIELD_TO_NAME = @"To";
NSString *const FIELD_DATE_SENT = @"DateSent";

NSString *const RECORD_TYPE_ORDER = @"Order";
NSString *const FIELD_DATE_REQUESTED = @"DateTimeRequested";

NSString *const RECORD_TYPE_PERSON_STATUS = @"Person";
NSString *const FIELD_STATUS = @"Status";
NSString *const FIELD_DATE = @"Date";

NSString *const SUBSCRIPTION_ADD_ACTIVITY = @"SubscriptionAddActivity";
NSString *const SUBSCRIPTION_ADD_MESSAGE = @"SubscriptionAddMessage";
NSString *const SUBSCRIPTION_STATUS_UPDATE = @"SubscriptionStatusUpdate";

NSString *const DEFAULTS_RESEND_QUEUE = @"Resend Queue";

NSString *const SIGNED_IN = @"Signed In";
NSString *const SIGNED_OUT = @"Signed Out";

@implementation HDConstants

@end
