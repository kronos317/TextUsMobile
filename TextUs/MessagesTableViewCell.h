//
//  MessagesTableViewCell.h
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TUMessage.h"

@interface MessagesTableViewCell : UITableViewCell {
    
    __weak IBOutlet UILabel *_messageLabel;
    __weak IBOutlet UILabel *_nameLabel;
    __weak IBOutlet UILabel *_dateLabel;
    __strong TUMessage *_message;
}

@property (nonatomic, strong)   TUMessage   *message;
@property (nonatomic, weak) UILabel *messageLabel;


- (CGFloat)heightForCellForMessage:(TUMessage*)msg;


@end
