//
//  HDUtilities.m
//  PeopleManager
//
//  Created by Scott Rasche on 9/25/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import "HDUtilities.h"
#import "HDConstants.h"

@implementation HDUtilities

+ (void)showSystemWideAlertWithError:(BOOL)error message:(NSString *)message
{
    NSLog(@"showSystemWideAlertWithError : %@", message);
    NSDictionary *userInfo;
    if (!error) {
        userInfo = @{KEY_ERROR_APP_WIDE_ALERT : @(NO), KEY_MESSAGE_APP_WIDE_ALERT : message};
    } else {
        userInfo = @{KEY_ERROR_APP_WIDE_ALERT : @(YES), KEY_MESSAGE_APP_WIDE_ALERT : message};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_APP_WIDE_ALERT object:nil userInfo:userInfo];
}

+ (CGFloat)currentScreenWidth
{
    
//    CGSize screenSize = [UIScreen mainScreen].currentMode.size;
    CGRect bounds = [[UIScreen mainScreen] bounds];
//    CGFloat scale = [[UIScreen mainScreen] scale];

    return bounds.size.width;
}

+ (BOOL)isIPAD
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return NO;
    }
}

+ (id)createNewCustomViewFromNib
{
    NSString *cellIdentifier = NSStringFromClass ([self class]);
    
    NSArray* nibContents = [[NSBundle mainBundle]
                            loadNibNamed:cellIdentifier owner:self options:NULL];
    NSEnumerator *nibEnumerator = [nibContents objectEnumerator];
    id createdView = nil;
    NSObject* nibItem = nil;
    while ( (nibItem = [nibEnumerator nextObject]) != nil) {
        if ( [nibItem isKindOfClass: [self class]]) {
            createdView = nibItem;
            break;
        }
    }
    return createdView;
}
@end
