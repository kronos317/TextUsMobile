//
//  MessageTemplateTableViewCell.m
//  TextUs
//
//  Created by Josh Bruhin on 4/15/16.
//  Copyright © 2016 TextUs. All rights reserved.
//

#import "MessageTemplateTableViewCell.h"
#import "Utils.h"

static CGFloat horizPadding = 60.0; // defined in XIB
static CGFloat vertPadding = 25.0; // defined in XIB

@implementation MessageTemplateTableViewCell

- (void)awakeFromNib {
    // Initialization code
    self.borderView.layer.cornerRadius = 8.0;
    self.borderView.layer.masksToBounds = YES;
    self.borderView.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.borderView.layer.borderWidth = 1.0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (CGFloat)heightForCellForTemplate:(TUMessageTemplate*)msg {
    
    CGFloat labelWidth = [UIScreen mainScreen].bounds.size.width - horizPadding;
    CGFloat msgHeight = [Utils heightForString:msg.content withFont:_messageLabel.font forWith:labelWidth];
    
    CGFloat height = _messageLabel.frame.origin.y + msgHeight + vertPadding;
    // add a little for the text padding built into the label
    height += 5;
    
    return height;
}

@end
