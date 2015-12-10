//
//  AddContactsViewController.h
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddContactsViewController : UIViewController {
    __strong UILocalizedIndexedCollation *_collation; // the list so we can have A-Z order
    __strong NSArray *_sectionsArray;
    __strong NSArray *_contacsArray;
}

@end
