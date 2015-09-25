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
    
}

- (void)fetchMessagesToPerson:(NSString *)person withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    
}

- (void)fetchMessagesFromPerson:(NSString *)person withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    
}

- (void)fetchEntrancesToBeaconRegion:(NSString *)beaconRegion withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler
{
    
}

#pragma mark - delete
#pragma mark - subscribing

- (void)subscribe
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([self isSubscribed] == NO) {
        
        NSPredicate *truePredicate = [NSPredicate predicateWithValue:YES];
        
        CKSubscription *activitySubscriptionCreate = [[CKSubscription alloc] initWithRecordType:RECORD_TYPE_PERSON_ACTIVITY
                                                                                      predicate:truePredicate
                                                                                 subscriptionID:SUBSCRIPTION_ADD_ACTIVITY
                                                                                        options:CKSubscriptionOptionsFiresOnRecordCreation];
        
        CKNotificationInfo *notification = [[CKNotificationInfo alloc] init];
        notification.alertBody = @"Activity occurred!";
        notification.shouldSendContentAvailable = YES; // this allows to process in the background
        notification.shouldBadge = YES;
        activitySubscriptionCreate.notificationInfo = notification;
        
        
        CKSubscription *messageSubscriptionCreate = [[CKSubscription alloc] initWithRecordType:RECORD_TYPE_MESSAGE
                                                                                     predicate:truePredicate
                                                                                subscriptionID:SUBSCRIPTION_ADD_MESSAGE
                                                                                     options:CKSubscriptionOptionsFiresOnRecordCreation];
        
        CKNotificationInfo *notificationMessage = [[CKNotificationInfo alloc] init];
        notificationMessage.alertBody = @"Message sent!";
        messageSubscriptionCreate.notificationInfo = notificationMessage;
        
        CKModifySubscriptionsOperation *subscriptionsOp = [[CKModifySubscriptionsOperation alloc]
                                                           initWithSubscriptionsToSave:@[activitySubscriptionCreate, messageSubscriptionCreate]
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
