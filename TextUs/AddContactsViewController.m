//
//  AddContactsViewController.m
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "AddContactsViewController.h"
#import <AddressBook/AddressBook.h>
#import "Utils.h"

@import Contacts;

@interface AddContactsViewController ()

@end

@implementation AddContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
//    ABAddressBookRef addressBook = ABAddressBookCreate( );
//    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople( addressBook );
//    CFIndex nPeople = ABAddressBookGetPersonCount( addressBook );
//    
//    for ( int i = 0; i < nPeople; i++ )
//    {
//        ABRecordRef ref = CFArrayGetValueAtIndex( allPeople, i );
//        ...
//    }
    
    [self getContacts];
    
}

- (void)showAccessDeniedAlert {
    NSString *msg = @"Access to contacts denied. Please go to your device Settings and grant access to continue.";
    [Utils showAlertWithTitle:@"Access Denied" message:msg fromViewController:self];
}

- (void)getContacts {
    
    CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
    if (status == CNAuthorizationStatusDenied || status == CNAuthorizationStatusDenied) {
        [self showAccessDeniedAlert];
        return;
    }
    
    CNContactStore *store = [[CNContactStore alloc] init];
    [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        
        // make sure the user granted us access
        
        if (!granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAccessDeniedAlert];
            });
            return;
        }
        
        // build array of contacts
        
        NSMutableArray *contacts = [NSMutableArray array];
        
        NSError *fetchError;
//        CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactIdentifierKey, [CNContactFormatter descriptorForRequiredKeysForStyle:CNContactFormatterStyleFullName]]];
        
        CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactIdentifierKey, CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactOrganizationNameKey]];

        BOOL success = [store enumerateContactsWithFetchRequest:request error:&fetchError usingBlock:^(CNContact *contact, BOOL *stop) {
            [contacts addObject:contact];
        }];
        if (!success) {
            NSLog(@"error = %@", fetchError);
        }
        
        // you can now do something with the list of contacts, for example, to show the names
        
//        CNContactFormatter *formatter = [[CNContactFormatter alloc] init];
        
        for (CNContact *contact in contacts) {
//            NSString *string = [formatter stringFromContact:contact];
//            NSLog(@"contact = %@", string);
            NSLog(@"%@", contact.givenName);
            NSLog(@"%@", contact.familyName);
            
            NSArray <CNLabeledValue<CNPhoneNumber *> *> *phoneNumbers = contact.phoneNumbers;
            CNLabeledValue<CNPhoneNumber *> *firstPhone = [phoneNumbers firstObject];
            CNPhoneNumber *number = firstPhone.value;
            NSString *digits = number.stringValue; // 1234567890
            NSString *label = firstPhone.label; // Mobile

            NSLog(@"%@", digits);
            NSLog(@"%@", label);

        }
    }];
}

- (NSString*)firstNameForContact:(CNContact*)contact {
    return contact.givenName;
}

- (NSString*)lastNameForContact:(CNContact*)contact {
    return contact.familyName;
}

- (void)configureSections {
    
    // Get the current collation and keep a reference to it.
    _collation = [UILocalizedIndexedCollation currentCollation];
    
    //NSCharacterSet
    NSInteger index, sectionTitlesCount = [[_collation sectionTitles] count];
    
    NSMutableArray *newSectionsArray = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    
    // Set up the sections array: elements are mutable arrays that will contain the alphabetically for that section.
    
    for (index = 0; index < sectionTitlesCount; index++) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [newSectionsArray addObject:array];
    }
    
    // Segregate the CNContact person into the appropriate arrays.
    NSInteger numberRecords = [_contacsArray count];
    short gotOne = 0;
    for (NSInteger i = 0; i < numberRecords; i++) {
        
        CNContact *contact = [_contacsArray objectAtIndex:i];
        NSString *name = [self firstNameForContact:contact];
        if ([name length] != 0 ) {
            gotOne++;
        }
        
        // Ask the collation which section number the name belongs in, based on its lowercase.
        NSInteger sectionNumber = [_collation sectionForObject:name collationStringSelector:@selector(lowercaseString)];
        
        
        // Get the array for the section.
        NSMutableArray *sectionAlphabeticallyArray = [newSectionsArray objectAtIndex:sectionNumber];
        
        //  Add the person to the section.
        [sectionAlphabeticallyArray addObject:(NSObject *)contact];
    }
    
    
    _sectionsArray = newSectionsArray;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
