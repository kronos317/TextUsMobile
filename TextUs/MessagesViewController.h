//
//  MessagesViewController.h
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewController.h"
#import "MessagesTableViewCell.h"

@interface MessagesViewController : MainViewController {
    __strong MessagesTableViewCell *_templateCell;
    BOOL _dirtyData;
    BOOL _requestingData;
}

@property (assign) BOOL isModal;

@end
