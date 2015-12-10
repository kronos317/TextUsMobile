//
//  ContactDetailsViewController.h
//  TextUs
//
//  Created by Josh Bruhin on 11/16/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TUContact.h"
#import "NewContactViewController.h"

@class ContactDetailsViewController;
@protocol ContactDetailViewControllerDelegate <NSObject>

@required
- (void)ContactDetailsViewController:(ContactDetailsViewController*)controller deletedContact:(TUContact*)contact;
@end

@interface ContactDetailsViewController : UIViewController <NewContactViewControllerDelegate> {
    
    __weak IBOutlet UILabel *_nameLabel;
    __weak IBOutlet UILabel *_phoneLabel;
    __weak IBOutlet UILabel *_businessNameLabel;
    __weak IBOutlet UISwitch *_optInSwitch;
    
    BOOL _optedOut;
    __strong NSString *_optOutId;
    
    
    __weak IBOutlet UIActivityIndicatorView *_spinner;
}

@property (nonatomic, unsafe_unretained) id<ContactDetailViewControllerDelegate> delegate;
@property (nonatomic, strong)   TUContact   *contact;
@property (assign)              BOOL optedOut;

@end
