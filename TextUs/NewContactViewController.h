//
//  NewContactViewController.h
//  TextUs
//
//  Created by Josh Bruhin on 11/16/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TUContact.h"

@class NewContactViewController;
@protocol NewContactViewControllerDelegate <NSObject>

@optional
- (void)NewContactViewController:(NewContactViewController*)controller createdContact:(TUContact*)createdContact;
- (void)NewContactViewController:(NewContactViewController*)controller editedContact:(TUContact*)editedContact;

@end

@interface NewContactViewController : UIViewController <UITextFieldDelegate> {
    
    __weak IBOutlet UITextField *_firstNameField;
    __weak IBOutlet UITextField *_lastNameField;
    __weak IBOutlet UITextField *_phoneField;
    __weak IBOutlet UITextField *_businessNameField;
    
    __strong UIActivityIndicatorView *_spinner;
}

@property (nonatomic, strong) TUContact *contactToEdit;
@property (nonatomic, unsafe_unretained) id<NewContactViewControllerDelegate> delegate;

@end
