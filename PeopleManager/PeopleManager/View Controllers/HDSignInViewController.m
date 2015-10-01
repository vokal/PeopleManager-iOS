//
//  HDSignInViewController.m
//  PeopleManager
//
//  Created by Scott Rasche on 9/25/15.
//  Copyright © 2015 vokal. All rights reserved.
//

#import "HDSignInViewController.h"
#import "HDCloudKitManager.h"
#import "HDConstants.h"
#import "HDUtilities.h"

@interface HDSignInViewController () <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UIButton *buttonEnter;
@property (strong, nonatomic) IBOutlet UITextField *textFieldSignIn;

@property (strong, nonatomic) HDCloudKitManager *cloudManager;

@end

@implementation HDSignInViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.buttonEnter.enabled = NO;
    self.cloudManager = [HDCloudKitManager sharedInstance];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.textFieldSignIn.text = @"";
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{

}

#pragma mark - IBActions

- (IBAction)enterPressed:(UIButton *)sender
{
    [self.textFieldSignIn resignFirstResponder];
    NSString *userName = [self.textFieldSignIn.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [[NSUserDefaults standardUserDefaults] setObject:userName forKey:DEFAULTS_USER_ID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.cloudManager signIn:YES
                   withPerson:userName
                       onDate:[NSDate date]
        withCompletionHandler:^(NSArray *records, NSError *error) {
            if (!error) {
                [HDUtilities showSystemWideAlertWithError:NO message:@"Welcome!"];
            } else {
                [HDUtilities showSystemWideAlertWithError:YES message:error.localizedDescription];
            }
        }];
    
    [self performSegueWithIdentifier:@"segueWork" sender:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *text = [textField.text stringByAppendingString:string];
    if (text.length) {
        self.buttonEnter.enabled = YES;
    } else {
        self.buttonEnter.enabled = NO;
    }
    
    return YES;
}

@end
