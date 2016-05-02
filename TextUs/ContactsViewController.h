//
//  ContactsViewController.h
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>

#import "MainViewController.h"
#import "ContactDetailsViewController.h"
#import "NewContactViewController.h"

@interface ContactsViewController : MainViewController <ContactDetailViewControllerDelegate, NewContactViewControllerDelegate, CNContactPickerDelegate> {

    __strong UILocalizedIndexedCollation *_collation; // the list so we can have A-Z order
//    __strong NSArray *_sectionsArray;
    
    __strong NSMutableArray *_contactsArray;
    __strong TUContact *_contactToImport;
    
    NSInteger _sectionsWithDataCount;
}

@end
