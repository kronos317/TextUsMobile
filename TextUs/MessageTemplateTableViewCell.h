//
//  MessageTemplateTableViewCell.h
//  TextUs
//
//  Created by Josh Bruhin on 4/15/16.
//  Copyright © 2016 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TUMessageTemplate.h"

@interface MessageTemplateTableViewCell : UITableViewCell

- (CGFloat)heightForCellForTemplate:(TUMessageTemplate*)msg;

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIView *borderView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
