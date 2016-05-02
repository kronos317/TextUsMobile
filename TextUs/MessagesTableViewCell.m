//
//  MessagesTableViewCell.m
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "MessagesTableViewCell.h"
#import "Utils.h"
#import "UIColor+TU.h"
#import "AppDelegate.h"

static CGFloat kMessageLabelMaxHeight = 40;

@implementation MessagesTableViewCell

@synthesize messageLabel = _messageLabel;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (TUMessage*)message {
    return _message;
}
- (void)setMessage:(TUMessage *)message {
    _message = message;
    
    [self populateView];
}

- (void)populateView {
    [self setupDateLabel];
    [self setupMessageLabel];
    [self setupNameLabel];
}

- (void)setupDateLabel {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"h:mm a"];
    _dateLabel.text = [formatter stringFromDate:self.message.createdDate];
    
    UIColor *color = self.message.read ? [UIColor tuBlueColor] : [UIColor whiteColor];
    _dateLabel.textColor = color;
}

- (void)setupMessageLabel {
    
    CGRect frame = _messageLabel.frame;
    frame.size.height = [self heightForMessageLabelForMessage:self.message];
    _messageLabel.frame = frame;
    
    _messageLabel.numberOfLines = 0;
    _messageLabel.text = self.message.content;
    
    UIColor *color = self.message.read ? [UIColor blackColor] : [UIColor whiteColor];
    _messageLabel.textColor = color;
}

- (CGFloat)heightForMessageLabelForMessage:(TUMessage*)msg {
    
    CGFloat rightMargin = 50.0;
    CGFloat msgLabelWidth = self.frame.size.width - _messageLabel.frame.origin.x - rightMargin;
    CGFloat height = [Utils heightForString:msg.content withFont:_messageLabel.font forWith:msgLabelWidth];
    
    
    height = height < kMessageLabelMaxHeight ? height : kMessageLabelMaxHeight;
    return height;
}

- (CGFloat)heightForCellForMessage:(TUMessage*)msg {
    return _messageLabel.frame.origin.y + [self heightForMessageLabelForMessage:msg] + 15.0;
}

- (void)setupNameLabel {
    

    NSString *nameStr = self.message.senderName;

    if ([self.message.senderType isEqualToString:@"User"]) {
        nameStr = self.message.receiverName;
    }
    
    // if senderType = Contact then nameStr = self.message.se
    
    // the messages objects don't have different first and last namges, just 'name'
    // so we have to get the last word of the name
    
    __block NSString *lastWord = nil;
    __block NSRange boldedRange;
    
    [nameStr enumerateSubstringsInRange:NSMakeRange(0, [nameStr length]) options:NSStringEnumerationByWords | NSStringEnumerationReverse usingBlock:^(NSString *substring, NSRange subrange, NSRange enclosingRange, BOOL *stop) {
        lastWord = substring;
        boldedRange = subrange;
        *stop = YES;
    }];
    
    
    UIFont *boldedFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:19];
//    NSRange boldedRange = [self.message.senderName rangeOfString:lastWord];
    
    UIColor *color = self.message.read ? [UIColor blackColor] : [UIColor colorWithWhite:1.0 alpha:1.0];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:nameStr attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:19], NSForegroundColorAttributeName:color}];
    
    [attrString beginEditing];
    [attrString addAttribute:NSFontAttributeName
                       value:boldedFont
                       range:boldedRange];
    
    [attrString endEditing];
    
    _nameLabel.attributedText = attrString;

}

@end
