//
//  HDMainIPadViewController.m
//  PeopleManager
//
//  Created by Scott Rasche on 9/24/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import "HDMainIPadViewController.h"
#import "HDCloudKitManager.h"
#import "HDConstants.h"
#import "HDPersonView.h"
#import "HDUtilities.h"

@interface HDMainIPadViewController ()

@property (nonatomic, strong) HDCloudKitManager *cloudManager;
@property (strong, nonatomic) IBOutlet UIView *ladderView;
@property (strong, nonatomic) IBOutlet UIView *receptionView;
@property (strong, nonatomic) IBOutlet UIView *statusView;
@property (strong, nonatomic) IBOutlet UITextView *textViewPeople;
@property (strong, nonatomic) IBOutlet UIImageView *floorPlan;
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (assign) CGRect ladderRoomRect;
@property (assign) CGRect receptionRect;
@property (strong, nonatomic) NSMutableArray *rectsInLadderRoom;
@property (strong, nonatomic) NSMutableArray *rectsInReception;
@property (strong, nonatomic) NSMutableArray *people;

@end

@implementation HDMainIPadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.cloudManager = [HDCloudKitManager sharedInstance];
    self.textViewPeople.text = @"";
    self.receptionView.alpha = 0.0;
    self.ladderView.alpha = 0.0;
    self.formatter = [[NSDateFormatter alloc] init];
    self.formatter.timeStyle = NSDateFormatterShortStyle;
    self.formatter.dateStyle = NSDateFormatterNoStyle;
    self.ladderRoomRect = self.ladderView.frame;
    self.receptionRect = self.receptionView.frame;
    self.rectsInLadderRoom = [NSMutableArray array];
    self.rectsInReception = [NSMutableArray array];
    self.people = [NSMutableArray array];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshWhosHere:)
                                                 name:NOTIFICATION_SIGNED_IN
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshWhosHere:)
                                                 name:NOTIFICATION_ACTIVITY
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self findPeople];
}

- (CGRect)rectForPersonInLocation:(NSString *)location frame:(CGRect)frame
{
    if ([location isEqualToString:BEACON_LADDER_ROOM]) {
        NSLog(@"Getting Rect for ladder");
        if (self.rectsInLadderRoom.count) {
            CGRect lastRect = [self.rectsInLadderRoom.lastObject CGRectValue];
            CGRect myRect = CGRectMake(lastRect.origin.x,
                                       lastRect.origin.y + lastRect.size.height + 4,
                                       lastRect.size.width,
                                       lastRect.size.height);
            [self.rectsInLadderRoom addObject:[NSValue valueWithCGRect:myRect]];
            return myRect;
        } else {
            CGRect myRect = CGRectMake(self.ladderRoomRect.origin.x,
                                       self.ladderRoomRect.origin.y,
                                       frame.size.width,
                                       frame.size.height);
            [self.rectsInLadderRoom addObject:[NSValue valueWithCGRect:myRect]];
            return myRect;

        }
    } else {
        NSLog(@"Getting rect for reception");
        if (self.rectsInReception.count) {
            CGRect lastRect = [self.rectsInReception.lastObject CGRectValue];
            CGRect myRect = CGRectMake(lastRect.origin.x,
                                       lastRect.origin.y + lastRect.size.height + 4,
                                       lastRect.size.width,
                                       lastRect.size.height);
            [self.rectsInReception addObject:[NSValue valueWithCGRect:myRect]];
            return myRect;
        } else {
            CGRect myRect = CGRectMake(self.receptionRect.origin.x,
                                       self.receptionRect.origin.y,
                                       frame.size.width,
                                       frame.size.height);
            [self.rectsInReception addObject:[NSValue valueWithCGRect:myRect]];
            return myRect;
        }
    }
    return CGRectZero;
}

- (HDPersonView *)findPerson:(NSString *)personName
{
    if (self.people.count) {
        for (HDPersonView *person in self.people) {
            if ([person.name isEqualToString:personName]) {
                return person;
            }
        }
    }
    return nil;
}
- (HDPersonView *)createPerson
{
    NSString *cellIdentifier = NSStringFromClass ([HDPersonView class]);
    
    NSArray *nibContents = [[NSBundle mainBundle]
                            loadNibNamed:cellIdentifier
                            owner:self
                            options:NULL];
    NSEnumerator *nibEnumerator = [nibContents objectEnumerator];
    id createdView = nil;
    NSObject *nibItem = nil;
    while ( (nibItem = [nibEnumerator nextObject]) != nil) {
        if ( [nibItem isKindOfClass: [HDPersonView class]]) {
            createdView = nibItem;
            break;
        }
    }
    return createdView;
}

- (void)popView:(UIView *)view
{
    [UIView animateWithDuration:0.3/1.5 animations:^{
        view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.1, 1.1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3/2 animations:^{
            view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.9, 0.9);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3/2 animations:^{
                view.transform = CGAffineTransformIdentity;
            }];
        }];
    }];
}
/*
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
*/

#pragma mark - Panning

- (void)panMe:(UIPanGestureRecognizer *)pgr
{
    HDPersonView *panningView = (HDPersonView *)pgr.view;
    if (pgr.state == UIGestureRecognizerStateChanged) {
        CGPoint center = panningView.center;
        CGPoint translation = [pgr translationInView:panningView];
        center = CGPointMake(center.x + translation.x,
                             center.y + translation.y);
        panningView.center = center;
        [pgr setTranslation:CGPointZero inView:panningView];
    } else if (pgr.state == UIGestureRecognizerStateEnded) {
        if (CGRectContainsPoint(self.receptionRect, panningView.center)) {
            NSLog(@"I AM IN RECEPTION NOW");
            [self popView:panningView];
            [self.cloudManager tellPerson:panningView.name
                             gotoLocation:BEACON_RECEPTION
                                   onDate:[NSDate date]
                    withCompletionHandler:^(NSArray *records, NSError *error) {
                        
                    }];
        } else if (CGRectContainsPoint(self.ladderRoomRect, panningView.center)) {
            NSLog(@"I AM IN LADDER ROOM NOW");
            [self popView:panningView];
            [self.cloudManager tellPerson:panningView.name
                             gotoLocation:BEACON_LADDER_ROOM
                                   onDate:[NSDate date]
                    withCompletionHandler:^(NSArray *records, NSError *error) {
                        
                    }];
        } else {
            NSLog(@"I AM LOST");
        }
    }
}

#pragma mark - notifications

- (void)refreshWhosHere:(NSNotification *)notification
{
    [self findPeople];
}

#pragma mark - cloud

- (void)findPeople
{
    [self.cloudManager fetchSignedInPeopleWithCompletionHandler:^(NSArray *records, NSError *error) {
        if (records.count) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                for (HDPersonView *person in self.people) {
                    [person removeFromSuperview];
                }
            }];
            [self.rectsInReception removeAllObjects];
            [self.rectsInLadderRoom removeAllObjects];

            NSMutableArray *namesArray = [NSMutableArray array];
            NSMutableString *names = [[NSMutableString alloc] initWithString:@""];
            for (CKRecord *record in records) {
                NSString *name = record[FIELD_NAME];
                if (![namesArray containsObject:name]) {
                    [namesArray addObject:name];
                }
                [names appendFormat:@"%@\n", name];
            }
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.textViewPeople.text = names;
            }];
            [self.cloudManager fetchLocationsForPeople:namesArray withCompletionHandler:^(NSArray *records, NSError *error) {
                if (records.count) {
                    NSLog(@"I have records!!!");
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        for (CKRecord *record in records) {
                            NSLog(@"Record = %@", record);
                            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                                  action:@selector(panMe:)];
                            NSString *name = record[FIELD_NAME];
                            HDPersonView *person = [self findPerson:name];//[self createPerson];
                            if (!person) {
                                person = [self createPerson];
                            }
                            person.labelName.text = record[FIELD_NAME];
                            person.name = record[FIELD_NAME];
                            NSDate *entered = record[FIELD_DATE_ADDED];
                            person.labelHereSince.text = [@"Arrived : " stringByAppendingString:[self.formatter stringFromDate:entered]];
                            NSString *location = record[FIELD_BEACON_REGION];
                            
                            CGRect personsRect = [self rectForPersonInLocation:location frame:person.frame];
                            NSLog(@"Rect = %@", NSStringFromCGRect(personsRect));
                            person.frame = personsRect;
                            [person addGestureRecognizer:pan];
                            person.alpha = 0.0;
                            [self.view addSubview:person];
                            [self.people addObject:person];
                            [UIView animateWithDuration:0.5
                                             animations:^{
                                                 person.alpha = 1.0;
                                                 self.floorPlan.alpha = .5;
                                             }];
                            
                        }
                    }];
                    
                }
            }];
        } else { // no ones here!
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                for (HDPersonView *person in self.people) {
                    [person removeFromSuperview];
                }
                [self.people removeAllObjects];
                [self.rectsInLadderRoom removeAllObjects];
                [self.rectsInReception removeAllObjects];
                self.textViewPeople.text = @"No One Here";
            }];
        }
    }];
}

@end
