//
//  HDPersonView.m
//  PeopleManager
//
//  Created by Scott Rasche on 9/25/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import "HDPersonView.h"
#import <QuartzCore/QuartzCore.h>

@implementation HDPersonView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.layer.cornerRadius = 50.0;
    //self.layer.masksToBounds = YES;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(50.0f, 10.0f);
    //self.layer.masksToBounds = NO;
    self.layer.shadowRadius = 10.0f;
}

@end
