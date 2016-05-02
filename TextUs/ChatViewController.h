//
//  ChatViewController.h
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "JSQMessagesViewController.h"
#import "JSQMessages.h"
#import "DemoModelData.h"
#import "NSUserDefaults+DemoSettings.h"
#import "TUConversation.h"
#import "ContactDetailsViewController.h"
#import "TUContact.h"
#import "MessageTemplatesTableViewController.h"

@interface ChatViewController : JSQMessagesViewController <UIActionSheetDelegate, JSQMessagesComposerTextViewPasteDelegate, ContactDetailViewControllerDelegate, MessageTemplatesTableViewControllerDelegate> {
    __strong UIActivityIndicatorView *_spinner;
    __strong UIButton *_sendButton;
    BOOL _requestingData;
}

//@property (strong, nonatomic) DemoModelData *demoData;
@property (strong, nonatomic) NSMutableArray *JSQMessages;
@property (strong, nonatomic) NSMutableArray *messages;
//@property (strong, nonatomic) TUConversation *conversation;
@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (strong, nonatomic) TUContact *contact;
@property (strong, nonatomic) NSString *contactDisplayName;

//- (void)receiveMessagePressed:(UIBarButtonItem *)sender;

@end
