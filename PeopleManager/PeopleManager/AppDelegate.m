//
//  AppDelegate.m
//  PeopleManager
//
//  Created by Scott Rasche on 9/24/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import "AppDelegate.h"
#import "HDBeaconManager.h"
#import "HDConstants.h"
#include <assert.h>
#include <stdbool.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/sysctl.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //TODO: Override point for customization after application launch.
    [self redirectConsoleLogToDocumentFolder];
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound) categories:nil];
    [application registerUserNotificationSettings:notificationSettings];
    [application registerForRemoteNotifications];
    //[self performSelector:@selector(testLocalNotification) withObject:nil afterDelay:5.0];
    return YES;
}

- (void)redirectConsoleLogToDocumentFolder
{
    if ([self isDebuggerAttached]) {
        return;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                         NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd_HH-mm-ss"]; // 2009-02-01 19:50:41 PST
    NSDate *now = [NSDate date];
    NSString *logString = [NSString stringWithFormat:@"console_%@.log", [dateFormat stringFromDate:now]];
    
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:logString];
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding], "a+",stderr);
}

- (BOOL)isDebuggerAttached
{
    // Returns true if the current process is being debugged (either
    // running under the debugger or has a debugger attached post facto).
    int junk;
    int mib[4];
    struct kinfo_proc info;
    size_t size;
    
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    
    // We're being debugged if the P_TRACED flag is set.
    
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}

#pragma mark - notifications

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"didReceiveLocalNotification = %@", notification);
    
}

 - (void)testLocalNotification
{
    UILocalNotification *note1 = [[UILocalNotification alloc] init];
    note1.alertBody = [NSString stringWithFormat:@"This is a test"];
    note1.alertAction = @"Entered Test";
    note1.soundName = SOUND_ENTERED_REGION;
    note1.userInfo = [NSDictionary dictionaryWithObject:@"TEST" forKey:NOTIFICATION_IDENTIFIER_ENTER];
    [[UIApplication sharedApplication] presentLocalNotificationNow:note1];
    NSLog(@"Notification : %@", note1);
    note1.applicationIconBadgeNumber = 0;
}

@end
