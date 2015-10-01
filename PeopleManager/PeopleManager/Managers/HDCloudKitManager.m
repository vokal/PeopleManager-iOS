//
//  HDCloudKitManager.m
//  PeopleManager
//
//  Created by Scott Rasche on 9/24/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import "HDCloudKitManager.h"
#import "HDConstants.h"

@interface HDCloudKitManager()

@property (readonly) CKContainer *container;
@property (readonly) CKDatabase *databaseToUse;
@property (assign) CKApplicationPermissionStatus permissionStatus;

@end

@implementation HDCloudKitManager

+ (HDCloudKitManager *)sharedInstance
{
    static HDCloudKitManager *cloudManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cloudManager = [[HDCloudKitManager alloc] init];
        [cloudManager privateInit];
    });
    return cloudManager;
}

- (void)privateInit
{
    _container = [CKContainer defaultContainer];
    [_container requestApplicationPermission:CKApplicationPermissionUserDiscoverability completionHandler:^(CKApplicationPermissionStatus applicationPermissionStatus, NSError *error) {
        self.permissionStatus = applicationPermissionStatus;
    }];
    _databaseToUse = [_container publicCloudDatabase];
    [self subscribe];
}

#pragma mark - save

- (void)saveRecords:(NSArray *)records withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    CKModifyRecordsOperation *modOp = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:records recordIDsToDelete:nil];
    modOp.qualityOfService = NSQualityOfServiceUserInitiated;

    modOp.perRecordCompletionBlock = ^(CKRecord *record, NSError *error){
        if (error) {
            NSLog(@"Error saving record : %@", error.localizedDescription);
        }
    };
    modOp.modifyRecordsCompletionBlock = ^(NSArray *savedRecords, NSArray *deletedRecordIDs, NSError *operationError)
    {
        NSLog(@"Completed saving %lu records with error = %@", (unsigned long)savedRecords.count,operationError.localizedDescription);
        if (operationError) {
            NSLog(@"Error saving record to cloud : %@", operationError.localizedDescription);
            if (savedRecords && savedRecords.count>0) {
                NSLog(@"Some records were saved : %ld", (unsigned long)savedRecords.count);
            }
//            NSMutableArray *resendQueue = [[[NSUserDefaults standardUserDefaults] objectForKey:DEFAULTS_RESEND_QUEUE] mutableCopy];
            // TODO: implement resendQueue
//            NSLog(@"Resend queue = \n%@",resendQueue);
//            [[NSUserDefaults standardUserDefaults] setObject:resendQueue forKey:DEFAULTS_RESEND_QUEUE];
//            [[NSUserDefaults standardUserDefaults] synchronize];
            
        }
        if (completionHandler) {
            completionHandler(savedRecords, operationError);
        }
    };
    [self.databaseToUse addOperation:modOp];
}

#pragma mark - add

- (void)enteredRegion:(BOOL)entered
           regionName:(NSString *)regionName
           withPerson:(NSString *)name
               onDate:(NSDate *)date
withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    CKRecord *record = [[CKRecord alloc] initWithRecordType:RECORD_TYPE_PERSON_ACTIVITY];
    record[FIELD_ACTIVITY] = entered ? ACTIVITY_ENTERED : ACTIVITY_EXITED;
    record[FIELD_BEACON_REGION] = regionName;
    record[FIELD_NAME] = name;
    record[FIELD_DATE_ADDED] = date;
    
    [self saveRecords:@[record] withCompletionHandler:^(NSArray *records, NSError *error) {
        if (completionHandler) {
            completionHandler(records, error);
        }
    }];
    
}

- (void)sendMessage:(NSString *)message
         fromPerson:(NSString *)fromPerson
           toPerson:(NSString *)toPerson
             onDate:(NSDate *)date
withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    CKRecord *record = [[CKRecord alloc] initWithRecordType:RECORD_TYPE_MESSAGE];
    record[FIELD_MESSAGE] = message;
    record[FIELD_FROM_NAME] = fromPerson;
    record[FIELD_TO_NAME] = toPerson;
    record[FIELD_DATE_SENT] = date;
    
    [self saveRecords:@[record] withCompletionHandler:^(NSArray *records, NSError *error) {
        if (completionHandler) {
            completionHandler(records, error);
        }
    }];
}

- (void)tellPerson:(NSString *)person
      gotoLocation:(NSString *)location
            onDate:(NSDate *)date
withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    CKRecord *record = [[CKRecord alloc] initWithRecordType:RECORD_TYPE_ORDER];
    record[FIELD_BEACON_REGION] = location;
    record[FIELD_NAME] = person;
    record[FIELD_DATE_REQUESTED] = date;
    
    [self saveRecords:@[record] withCompletionHandler:^(NSArray *records, NSError *error) {
        if (completionHandler) {
            completionHandler(records, error);
        }
    }];
}

- (void)signIn:(BOOL)signingIn withPerson:(NSString *)person onDate:(NSDate *)date withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler;
{
    CKRecord *record = [[CKRecord alloc] initWithRecordType:RECORD_TYPE_PERSON_STATUS];
    record[FIELD_NAME] = person;
    record[FIELD_STATUS] = signingIn ? SIGNED_IN : SIGNED_OUT;
    record[FIELD_DATE] = date;
    
    [self saveRecords:@[record] withCompletionHandler:^(NSArray *records, NSError *error) {
        if (completionHandler) {
            completionHandler(records, error);
        }
    }];
}

#pragma mark - fetch

- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(HDCloudRecordCompletionHandler)completionHandler
{
    CKRecordID *current = [[CKRecordID alloc] initWithRecordName:recordID];
    [self.databaseToUse fetchRecordWithID:current completionHandler:^(CKRecord *record, NSError *error) {
        if (error) {
            // In your app, handle this error gracefully.
            NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
            completionHandler(nil, error);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                completionHandler(record, error);
            });
        }
    }];
}

- (void)fetchRecordsForPerson:(NSString *)person withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", FIELD_NAME, person];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:RECORD_TYPE_PERSON_ACTIVITY predicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:FIELD_DATE_ADDED ascending:NO]; // most current on first
    query.sortDescriptors = @[sort];
    
    NSMutableArray *results = [NSMutableArray array];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    };
    [self.databaseToUse addOperation:queryOperation];
}

- (void)fetchMessagesToPerson:(NSString *)person withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", FIELD_TO_NAME, person];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:RECORD_TYPE_MESSAGE predicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:FIELD_DATE_SENT ascending:NO]; // most current on first
    query.sortDescriptors = @[sort];
    
    NSMutableArray *results = [NSMutableArray array];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    };
    [self.databaseToUse addOperation:queryOperation];
}

- (void)fetchMessagesFromPerson:(NSString *)person withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", FIELD_FROM_NAME, person];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:RECORD_TYPE_MESSAGE predicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:FIELD_DATE_SENT ascending:NO]; // most current on first
    query.sortDescriptors = @[sort];
    
    NSMutableArray *results = [NSMutableArray array];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    };
    [self.databaseToUse addOperation:queryOperation];
}

- (void)fetchEntrancesToBeaconRegion:(NSString *)beaconRegion withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", FIELD_BEACON_REGION, beaconRegion];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:RECORD_TYPE_PERSON_ACTIVITY predicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:FIELD_DATE_ADDED ascending:NO]; // most current on first
    query.sortDescriptors = @[sort];
    
    NSMutableArray *results = [NSMutableArray array];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    };
    [self.databaseToUse addOperation:queryOperation];
}

- (void)fetchPersonStatus:(NSString *)person withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", FIELD_NAME, person];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:RECORD_TYPE_PERSON_STATUS predicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:FIELD_DATE ascending:NO]; // most current on first
    query.sortDescriptors = @[sort];
    
    NSMutableArray *results = [NSMutableArray array];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    };
    [self.databaseToUse addOperation:queryOperation];
}

- (void)fetchOrdersForPerson:(NSString *)person onDate:(NSDate *)date withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    // make a date range
    unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:flags fromDate:date];
    NSDate *startDate = [calendar dateFromComponents:components];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterFullStyle;
    NSDate *endDate = [startDate dateByAddingTimeInterval:60* 60* 24];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K >= %@ && %K < %@ && %K == %@", FIELD_DATE_REQUESTED, startDate, FIELD_DATE_REQUESTED, endDate , FIELD_NAME, person];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:RECORD_TYPE_ORDER predicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:FIELD_DATE_REQUESTED ascending:NO]; // most current on first
    query.sortDescriptors = @[sort];
    
    NSMutableArray *results = [NSMutableArray array];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        [results addObject:record];
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    };
    [self.databaseToUse addOperation:queryOperation];
}

- (void)fetchSignedInPeopleWithCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", FIELD_STATUS, SIGNED_IN];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:RECORD_TYPE_PERSON_STATUS predicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:FIELD_NAME ascending:YES];
    query.sortDescriptors = @[sort];
    
    NSMutableArray *results = [NSMutableArray array];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        if (![results containsObject:record]) {
            [results addObject:record];
        }
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    };
    [self.databaseToUse addOperation:queryOperation];
}

- (void)fetchLocationsForPeople:(NSArray *)people withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K IN %@", FIELD_NAME, people];
    //NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", FIELD_NAME, @"Frank"];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:RECORD_TYPE_PERSON_ACTIVITY predicate:predicate];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:FIELD_NAME ascending:YES];
    NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:FIELD_DATE_ADDED ascending:NO];
    query.sortDescriptors = @[sort, sort2];
    
    NSMutableArray *results = [NSMutableArray array];
    
    CKQueryOperation *queryOperation = [[CKQueryOperation alloc] initWithQuery:query];
    queryOperation.qualityOfService = NSQualityOfServiceUserInteractive;
    
    NSMutableSet *foundPeople = [NSMutableSet set];
    
    queryOperation.recordFetchedBlock = ^(CKRecord *record) {
        if (![foundPeople containsObject:record[FIELD_NAME]]) {
            [results addObject:record];
            [foundPeople addObject:record[FIELD_NAME]];
        }
    };
    
    queryOperation.queryCompletionBlock = ^(CKQueryCursor *cursor, NSError *error) {
        if (completionHandler) {
            completionHandler(results, error);
        }
    };
    [self.databaseToUse addOperation:queryOperation];
}

#pragma mark - delete

- (void)deleteSignedInStatusForPerson:(NSString *)person withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    [self fetchPersonStatus:person withCompletionHandler:^(NSArray *records, NSError *error) {
        
        if (records.count) {
            for (CKRecord *record in records) {
                [self.databaseToUse deleteRecordWithID:record.recordID completionHandler:^(CKRecordID *_Nullable recordID, NSError *_Nullable error) {
                    
                }];
            }
        }
        completionHandler(records, error);
    }];
}

#pragma mark - subscribing

- (void)subscribe
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([self isSubscribed] == NO) {
        
        NSPredicate *truePredicate = [NSPredicate predicateWithValue:YES];
        
        CKSubscription *activitySubscriptionCreate = [[CKSubscription alloc] initWithRecordType:RECORD_TYPE_PERSON_ACTIVITY
                                                                                      predicate:truePredicate
                                                                                 subscriptionID:SUBSCRIPTION_ADD_ACTIVITY
                                                                                        options:CKSubscriptionOptionsFiresOnRecordCreation|CKSubscriptionOptionsFiresOnRecordUpdate];
        
        CKNotificationInfo *notification = [[CKNotificationInfo alloc] init];
        notification.alertBody = @"Activity occurred!";
        notification.shouldSendContentAvailable = YES; // this allows to process in the background
        notification.shouldBadge = YES;
        activitySubscriptionCreate.notificationInfo = notification;
        
        
        CKSubscription *messageSubscriptionCreate = [[CKSubscription alloc] initWithRecordType:RECORD_TYPE_MESSAGE
                                                                                     predicate:truePredicate
                                                                                subscriptionID:SUBSCRIPTION_ADD_MESSAGE
                                                                                     options:CKSubscriptionOptionsFiresOnRecordCreation|CKSubscriptionOptionsFiresOnRecordUpdate];
        
        CKNotificationInfo *notificationMessage = [[CKNotificationInfo alloc] init];
        notificationMessage.alertBody = @"Message sent!";
        notificationMessage.shouldSendContentAvailable = YES;
        messageSubscriptionCreate.notificationInfo = notificationMessage;
        
        CKSubscription *personStatusUpdated = [[CKSubscription alloc] initWithRecordType:RECORD_TYPE_PERSON_STATUS
                                                                               predicate:truePredicate
                                                                          subscriptionID:SUBSCRIPTION_STATUS_UPDATE
                                                                                 options:CKSubscriptionOptionsFiresOnRecordCreation|CKSubscriptionOptionsFiresOnRecordUpdate];
        
        CKNotificationInfo *notificationStatus = [[CKNotificationInfo alloc] init];
        notificationStatus.alertBody = @"Status updated";
        notificationStatus.shouldSendContentAvailable = YES;
        personStatusUpdated.notificationInfo = notificationStatus;
        
        
        CKSubscription *orderMade = [[CKSubscription alloc] initWithRecordType:RECORD_TYPE_ORDER
                                                                               predicate:truePredicate
                                                                          subscriptionID:SUBSCRIPTION_ORDER
                                                                                 options:CKSubscriptionOptionsFiresOnRecordCreation|CKSubscriptionOptionsFiresOnRecordUpdate];
        
        CKNotificationInfo *notificationStatusOrder = [[CKNotificationInfo alloc] init];
        notificationStatusOrder.alertBody = @"Order Received";
        notificationStatusOrder.shouldSendContentAvailable = YES;
        orderMade.notificationInfo = notificationStatus;
        
        
        
        
        CKModifySubscriptionsOperation *subscriptionsOp = [[CKModifySubscriptionsOperation alloc]
                                                           initWithSubscriptionsToSave:@[
                                                                                         activitySubscriptionCreate,
                                                                                         personStatusUpdated,
                                                                                         orderMade
                                                                                         ]
                                                           subscriptionIDsToDelete:nil];
        subscriptionsOp.qualityOfService = NSQualityOfServiceUtility;
        subscriptionsOp.modifySubscriptionsCompletionBlock = ^(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *error) {
            if (savedSubscriptions) {
                for (CKSubscription *subscription in savedSubscriptions) {
                    NSLog(@"Subscribed to : %@", subscription.subscriptionID);
                    if ([subscription.subscriptionID isEqualToString:SUBSCRIPTION_ADD_ACTIVITY]) {
                        [defaults setObject:subscription.subscriptionID forKey:SUBSCRIPTION_ADD_ACTIVITY];
                    } else if ([subscription.subscriptionID isEqualToString:SUBSCRIPTION_ADD_MESSAGE]) {
                        [defaults setObject:subscription.subscriptionID forKey:SUBSCRIPTION_ADD_MESSAGE];
                    } else if ([subscription.subscriptionID isEqualToString:SUBSCRIPTION_STATUS_UPDATE]) {
                        [defaults setObject:subscription.subscriptionID forKey:SUBSCRIPTION_STATUS_UPDATE];
                    } else if ([subscription.subscriptionID isEqualToString:SUBSCRIPTION_ORDER]) {
                        [defaults setObject:subscription.subscriptionID forKey:SUBSCRIPTION_ORDER];
                    }
                }
                [defaults synchronize];
            }
            if (error) {
                NSLog(@"Error subscribing %@", error.localizedDescription);
            }
        };
        [self.databaseToUse addOperation:subscriptionsOp];
    } else {
        [self.databaseToUse fetchAllSubscriptionsWithCompletionHandler:^(NSArray *subscriptions, NSError *error) {
            if (error) {
                NSLog(@"Subscription error = %@", error.localizedDescription);
            } else {
                NSLog(@"Subscribed : %@", subscriptions);
                //                for (CKSubscription *sub in subscriptions)
                //                {
                //                    NSLog(@"Sub : %@",sub.subscriptionID);
                //                }
            }
        }];
    }
}

- (void)unsubscribe
{
    if ([self isSubscribed] == YES) {
        NSMutableArray *keys = [@[] mutableCopy];
        NSString *subscriptionAddActivity = [[NSUserDefaults standardUserDefaults] objectForKey:SUBSCRIPTION_ADD_ACTIVITY];
        if (subscriptionAddActivity) {
            [keys addObject:subscriptionAddActivity];
        }
        NSString *subscriptionAddMessage = [[NSUserDefaults standardUserDefaults] objectForKey:SUBSCRIPTION_ADD_MESSAGE];
        if (subscriptionAddMessage) {
            [keys addObject:subscriptionAddMessage];
        }
        NSString *subscriptionStatus = [[NSUserDefaults standardUserDefaults] objectForKey:SUBSCRIPTION_STATUS_UPDATE];
        if (subscriptionStatus) {
            [keys addObject:subscriptionStatus];
        }
        NSString *subscriptionOrder = [[NSUserDefaults standardUserDefaults] objectForKey:SUBSCRIPTION_ORDER];
        if (subscriptionOrder) {
            [keys addObject:subscriptionOrder];
        }

        NSLog(@"Keys to unsubscribe from : %@", keys);
        CKModifySubscriptionsOperation *modifyOperation = [[CKModifySubscriptionsOperation alloc] init];
        modifyOperation.qualityOfService = NSQualityOfServiceUtility;
        modifyOperation.subscriptionIDsToDelete = keys;
        
        modifyOperation.modifySubscriptionsCompletionBlock = ^(NSArray *savedSubscriptions, NSArray *deletedSubscriptionIDs, NSError *error) {
            if (error) {
                // In your app, handle this error beautifully.
                NSLog(@"An error occured in %@: %@", NSStringFromSelector(_cmd), error);
                abort();
            } else {
                for (NSString *subscriptionId in deletedSubscriptionIDs) {
                    NSLog(@"Unsubscribed to Item : %@", subscriptionId);
                    
                }
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:subscriptionAddActivity];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:subscriptionAddMessage];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:subscriptionStatus];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        };
        [self.databaseToUse addOperation:modifyOperation];
    }
}

- (BOOL)isSubscribed
{
    NSString *value = [[NSUserDefaults standardUserDefaults] objectForKey:SUBSCRIPTION_ADD_ACTIVITY];
    return value!=nil;
}

@end
