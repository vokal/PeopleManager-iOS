//
//  HDCloudKitManager.h
//  PeopleManager
//
//  Created by Scott Rasche on 9/24/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CloudKit/CloudKit.h>

typedef void(^HDCloudRecordCompletionHandler)(CKRecord *record, NSError *error);
typedef void(^HDCloudRecordsCompletionHandler)(NSArray *records, NSError *error);

@interface HDCloudKitManager : NSObject

+ (HDCloudKitManager *)sharedInstance;
// save
- (void)saveRecords:(NSArray *)records withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler;

// add
- (void)enteredRegion:(BOOL)entered
           regionName:(NSString *)regionName
           withPerson:(NSString *)name
               onDate:(NSDate *)date
withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler;

- (void)sendMessage:(NSString *)message
         fromPerson:(NSString *)fromPerson
           toPerson:(NSString *)toPerson
             onDate:(NSDate *)date
withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler;

// fetch
- (void)fetchRecordWithID:(NSString *)recordID completionHandler:(HDCloudRecordCompletionHandler)completionHandler;
- (void)fetchRecordsForPerson:(NSString *)person withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler;
- (void)fetchMessagesToPerson:(NSString *)person withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler;
- (void)fetchMessagesFromPerson:(NSString *)person withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler;
- (void)fetchEntrancesToBeaconRegion:(NSString *)beaconRegion withCompletionHandler:(HDCloudRecordsCompletionHandler)completionHandler;

// delete
@end
