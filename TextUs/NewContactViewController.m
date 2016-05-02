//
//  NewContactViewController.m
//  TextUs
//
//  Created by Josh Bruhin on 11/16/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "NewContactViewController.h"
#import "AuthAPIClient.h"
#import "Utils.h"

@interface NewContactViewController ()

@end

@implementation NewContactViewController

@synthesize contactToEdit;
@synthesize delegate;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    if (self.contactToEdit) {
        [self setupContactToEdit];
    }
    
    [self setupNavbar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [_firstNameField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [_firstNameField resignFirstResponder];
    [_lastNameField resignFirstResponder];
    [_phoneField resignFirstResponder];
    [_businessNameField resignFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupContactToEdit {
    _firstNameField.text = self.contactToEdit.firstName;
    _lastNameField.text = self.contactToEdit.lastName;
    _phoneField.text = self.contactToEdit.phone;
    _businessNameField.text = self.contactToEdit.businessName;
}

- (void)setupNavbar {
    self.title = self.contactToEdit ? [NSString stringWithFormat:@"%@ %@", self.contactToEdit.firstName, self.contactToEdit.lastName] : @"New Contact";
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveContactHit:)];
    self.navigationItem.rightBarButtonItem = button;
}

- (void)setupViewBusy:(BOOL)busy {
    
    if (busy) {
        self.navigationItem.rightBarButtonItem = nil;
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        
        CGRect frame = _spinner.frame;
        frame.origin.y = (self.navigationController.navigationBar.frame.size.height - _spinner.frame.size.height) / 2;
        frame.origin.x = self.navigationController.navigationBar.frame.size.width - _spinner.frame.size.width - 15;
        _spinner.frame = frame;
        
        [_spinner startAnimating];
        
        [self.navigationController.navigationBar addSubview:_spinner];
    }
    else {
        [_spinner removeFromSuperview];
        [self setupNavbar];
    }
}

#pragma mark Actions

- (IBAction)saveContactHit:(id)sender {
    
    if (self.contactToEdit) {
        [self saveEditedContact];
    }
    else {
        [self saveNewContact];
    }
}

- (void)saveEditedContact {
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }

    [self setupViewBusy:YES];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@/%@", @"contacts", self.contactToEdit.idStr];
    id params = @{@"phone":_phoneField.text,
                  @"first_name":_firstNameField.text,
                  @"last_name":_lastNameField.text,
                  @"business_name":_businessNameField.text,
                  @"id":self.contactToEdit.idStr};
    
    [[AuthAPIClient sharedClient] PUT:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"ResponseObject: %@", responseObject);
        
        NSArray *contacts = [Utils processContactsResponse:@[responseObject]];
        TUContact *contact = [contacts objectAtIndex:0];

        if (self.delegate && [self.delegate respondsToSelector:@selector(NewContactViewController:editedContact:)]) {
            [self.delegate NewContactViewController:self editedContact:contact];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        
        [Utils handleGeneralError:error fromViewController:self];

        [self setupViewBusy:NO];
    }];
}

- (void)saveNewContact {
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }
    
    [self setupViewBusy:YES];

    
    // first, query server for the selected contact phone number. if it exists, show error to user
    
    // need to clean the phone string to remove all but numbers, then add a "1" to the front
    
    NSString *origString = _phoneField.text;
    NSString *newString = [[origString componentsSeparatedByCharactersInSet:
                            [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                           componentsJoinedByString:@""];
    
    // only add the "1" if it's not already there
    NSString *firstChar = [newString substringToIndex:1];
    if (![firstChar isEqualToString:@"1"]) {
        newString = [NSString stringWithFormat:@"1%@", newString];
    }
    
    NSString *urlStr = @"contacts";
    id params = @{@"q":newString};
    
    [[AuthAPIClient sharedClient] GET:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"ResponseObject: %@", responseObject);
        
        // iterate the contacts from the response and see if this phone number exists
        
        BOOL exists = NO;
        if (responseObject && [responseObject isKindOfClass:[NSArray class]] && ((NSArray*)responseObject).count > 0) {
            NSArray *contacts = [Utils processContactsResponse:responseObject];
            for (TUContact *contact in contacts) {
                if ([contact.phone isEqualToString:newString]) {
                    exists = YES;
                    break;
                }
            }
        }
       
        if (!exists) {
            
            // contact does not exist, so go ahead and post it to server
            NSString *urlStr = @"contacts";
            id params = @{@"phone":_phoneField.text, @"first_name":_firstNameField.text, @"last_name":_lastNameField.text, @"business_name":_businessNameField.text};
            
            [[AuthAPIClient sharedClient] POST:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                NSLog(@"ResponseObject: %@", responseObject);
                
                NSArray *contacts = [Utils processContactsResponse:@[responseObject]];
                TUContact *contact = [contacts objectAtIndex:0];
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(NewContactViewController:createdContact:)]) {
                    [self.delegate NewContactViewController:self createdContact:contact];
                }
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"Error: %@", error);
                
                [Utils handleGeneralError:error fromViewController:self];
                
                [self setupViewBusy:NO];
                
            }];
        }
        else {
            // contact exists, tell user
            [Utils showAlertWithTitle:@"Contact already exists" message:nil fromViewController:self];
            [self setupViewBusy:NO];
        }
        
        
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        
        [Utils handleGeneralError:error fromViewController:self];
    }];
}


- (void)toggleSubmitButtonActivePhoneText:(NSString*)phoneText firstNameText:(NSString*)firstNameText {
    // phone number must contain 10 or 11 digits
    NSString *numbers = [self extractNumberFromText:phoneText];
    self.navigationItem.rightBarButtonItem.enabled = ((numbers.length == 10 || numbers.length == 11) && firstNameText.length > 0);
}

- (NSString *)extractNumberFromText:(NSString *)text {
    NSCharacterSet *nonDigitCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [[text componentsSeparatedByCharactersInSet:nonDigitCharacterSet] componentsJoinedByString:@""];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark UITextField delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *newString;
    
    if (string.length == 0) {
        newString = [textField.text substringWithRange:NSMakeRange(0, textField.text.length - 1)];
    }
    else {
        newString = [NSString stringWithFormat:@"%@%@", textField.text, string];
    }

    if (textField == _phoneField) {
        [self toggleSubmitButtonActivePhoneText:newString firstNameText:_firstNameField.text];
    }
    else if (textField == _firstNameField) {
        [self toggleSubmitButtonActivePhoneText:_phoneField.text firstNameText:newString];
    }
    
    return YES;
}

@end
