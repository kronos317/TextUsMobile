//
//  MessageTemplatesTableViewController.h
//  TextUs
//
//  Created by Josh Bruhin on 4/15/16.
//  Copyright © 2016 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MessageTemplateTableViewCell.h"
#import "TUMessageTemplate.h"

@class MessageTemplatesTableViewController;
@protocol MessageTemplatesTableViewControllerDelegate <NSObject>

@optional
- (void)MessageTemplatesTableViewController:(MessageTemplatesTableViewController*)controller doneWithTemplate:(TUMessageTemplate*)messageTemplate;

@end

@interface MessageTemplatesTableViewController : UITableViewController {
    BOOL _requestingData;
    __strong MessageTemplateTableViewCell *_templateCell;
    __strong NSMutableArray *_dataArray;
    __strong UIActivityIndicatorView *_spinner;
}

@property (nonatomic, unsafe_unretained) id<MessageTemplatesTableViewControllerDelegate> delegate;

@end
