//
//  HDUtilities.h
//  PeopleManager
//
//  Created by Scott Rasche on 9/25/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface HDUtilities : NSObject

+ (void)showSystemWideAlertWithError:(BOOL)error message:(NSString *)message;
+ (CGFloat)currentScreenWidth;
+ (BOOL)isIPAD;
+ (id)createNewCustomViewFromNib;
@end
