//
//  HDPersonView.h
//  PeopleManager
//
//  Created by Scott Rasche on 9/25/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface HDPersonView : UIView

@property (strong, nonatomic) IBOutlet UIImageView *personImageView;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) IBOutlet UILabel *labelName;
@property (strong, nonatomic) IBOutlet UILabel *labelHereSince;

@end
