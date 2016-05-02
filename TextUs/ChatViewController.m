//
//  ChatViewController.m
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "ChatViewController.h"
#import "TUMessage.h"
#import "AuthAPIClient.h"
#import "Utils.h"
#import "ContactDetailsViewController.h"
#import "MessageTemplatesTableViewController.h"
#import "AppDelegate.h"

static NSString *kFirstNameTemplateKey = @"{{contact.first_name}}";
static NSString *kLastNameTemplateKey = @"{{contact.last_name}}";
static NSString *kBusinessNameTemplateKey = @"{{contact.business_name}}";

@interface ChatViewController ()

@end

@implementation ChatViewController

@synthesize messages;
@synthesize JSQMessages;

#pragma mark - View lifecycle

/**
 *  Override point for customization.
 *
 *  Customize your view.
 *  Look at the properties on `JSQMessagesViewController` and `JSQMessagesCollectionView` to see what is possible.
 *
 *  Customize your layout.
 *  Look at the properties on `JSQMessagesCollectionViewFlowLayout` to see what is possible.
 */
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.showLoadEarlierMessagesHeader = NO;
    self.title = self.contactDisplayName;
    _requestingData = NO;
    
    [self setupObservers];
    
    [self setupSpinner];

    [self setupInputToolbar];
    
    [self setupBubbleImages];
    
    [self setupNavBar];

    [self requestData];
    
    self.inputToolbar.contentView.textView.pasteDelegate = self;
    
    /**
     *  You can set custom avatar sizes
     */
    if (![NSUserDefaults incomingAvatarSetting]) {
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
    }
    
    if (![NSUserDefaults outgoingAvatarSetting]) {
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
    }
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage jsq_defaultTypingIndicatorImage]
//                                                                              style:UIBarButtonItemStyleBordered
//                                                                             target:self
//                                                                             action:@selector(receiveMessagePressed:)];
    
    /**
     *  Register custom menu actions for cells.
     */
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(customAction:)];
    [UIMenuController sharedMenuController].menuItems = @[ [[UIMenuItem alloc] initWithTitle:@"Custom Action"
                                                                                      action:@selector(customAction:)] ];
    
    /**
     *  OPT-IN: allow cells to be deleted
     */
    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
    
    /**
     *  Customize your toolbar buttons
     *
     *  self.inputToolbar.contentView.leftBarButtonItem = custom button or nil to remove
     *  self.inputToolbar.contentView.rightBarButtonItem = custom button or nil to remove
     */
    
    /**
     *  Set a maximum height for the input toolbar
     *
     *  self.inputToolbar.maximumHeight = 150;
     */
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.inputToolbar.contentView.textView becomeFirstResponder];
    
    [self scrollToBottomAnimated:YES];
    
    /**
     *  Enable/disable springy bubbles, default is NO.
     *  You must set this from `viewDidAppear:`
     *  Note: this feature is mostly stable, but still experimental
     */
//    self.collectionView.collectionViewLayout.springinessEnabled = [NSUserDefaults springinessSetting];
}



- (void)setupSpinner {
    
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    CGRect frame = _spinner.frame;
    frame.origin.x = (self.view.frame.size.width - _spinner.frame.size.width) / 2;
    frame.origin.y = (self.view.frame.size.height - _spinner.frame.size.height) / 3;
    _spinner.frame = frame;
    
    _spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    
    [_spinner startAnimating];
    
    [self.view addSubview:_spinner];
}

- (void)setupObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewMessageNotification:)
                                                 name:@"NewMessageReceived" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestData)
                                                 name:@"ApplicationDidBecomeActive" object:nil];
}

- (void)setupInputToolbar {
    
    UIButton *leftButton = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 40, 39)];
    [leftButton setImage:[UIImage imageNamed:@"templates-icon"] forState:UIControlStateNormal];
//    [leftButton addTarget:self action:@selector(showMessageTemplates:) forControlEvents:UIControlEventTouchUpInside];
    
    self.inputToolbar.contentView.leftBarButtonItem = leftButton;
    
    _sendButton = [[UIButton alloc] initWithFrame:self.inputToolbar.contentView.rightBarButtonItem.frame];
    [_sendButton setImage:[UIImage imageNamed:@"sendMessageButton"] forState:UIControlStateNormal];
    self.inputToolbar.contentView.rightBarButtonItem = _sendButton;
    
    // to disable emojis...
    self.inputToolbar.contentView.textView.keyboardType = UIKeyboardTypeASCIICapable;
}

- (void)setupSendingMessageBusy:(BOOL)busy {
    
    _sendButton.enabled = !busy;
    
    if (busy) {
        
        [_sendButton setImage:[UIImage imageNamed:@"SendMsgButton_blank"] forState:UIControlStateNormal];
        
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGRect frame = _spinner.frame;
        frame.origin.x = self.inputToolbar.contentView.frame.size.width - _spinner.frame.size.width - 20;
        frame.origin.y = (self.inputToolbar.contentView.frame.size.height - _spinner.frame.size.height) / 2;
        _spinner.frame = frame;
        [_spinner startAnimating];
        [self.inputToolbar.contentView addSubview:_spinner];
    }
    else {
        [_spinner removeFromSuperview];
        [_sendButton setImage:[UIImage imageNamed:@"sendMessageButton"] forState:UIControlStateNormal];
    }

}

- (void)setupNavBar {
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"Details" style:UIBarButtonItemStylePlain target:self action:@selector(showContactDetails:)];
    self.navigationItem.rightBarButtonItem = button;
}


- (void)setupBubbleImages {
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
    self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
}

- (void)requestData {
    
    if (_requestingData) {
        return;
    }
    
    _requestingData = YES;
    
    NSString *urlStr = [NSString stringWithFormat:@"messages/%@", self.contact.idStr];
    id params = @{@"page":@"1", @"per_page":@"25", @"contact_id":self.contact.idStr};
    
    [[AuthAPIClient sharedClient] GET:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"ResponseObject: %@", responseObject);
        
        [_spinner removeFromSuperview];
        _spinner = nil;
        
        self.messages = [NSMutableArray arrayWithArray:[Utils processMessagesResponse:(NSArray*)responseObject]];
        [self setupData];
        [self reloadData];
        
        _requestingData = NO;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        
        [_spinner removeFromSuperview];
        _spinner = nil;
        _requestingData = NO;

        [Utils handleGeneralError:error fromViewController:self];
    }];
    
}

- (void)setupData {
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:self.messages.count];
    for (TUMessage *msg in self.messages) {
        
        JSQMessage *jsqMsg = [[JSQMessage alloc] initWithSenderId:msg.senderIdStr senderDisplayName:msg.senderName date:msg.createdDate text:msg.content];
        
        // we want reverse order
        [mArray insertObject:jsqMsg atIndex:0];
    }
    self.JSQMessages = mArray;
}

- (void)reloadData {
    [self.collectionView reloadData];
    [self scrollToBottomAnimated:YES];
}

- (void)handleNewMessageNotification:(NSNotification*)notification {


//    // we first need to see if this message already exists. this will happen if the user sent a message from this view
//    // becuase Pusher sends us an event for that. so iterate our messages and look at id
//    
//    TUMessage *msg = [[TUMessage alloc] init];
//    msg.idStr = [Utils checkObjectForNull:[[msgDict objectForKey:@"id"] stringValue]];
//    msg.content = [[msgDict objectForKey:@"content"] objectForKey:@"body"];
//    msg.createdDateStr = [[msgDict objectForKey:@"content"] objectForKey:@"created_at"];
//    msg.createdDate = [Utils dateForDateString:msg.createdDateStr];
//    
//    // need to determine if this was from the current user or from the current contact. with current payload of
//    // pusher message, only way to do that is look at user_id field. if it's populated and equals current user id,
//    // then it's from user. otherwise, it's from contact, in which case we use the contact_id field
//    
//    BOOL fromUser = NO;
//    NSString *userIdStr = [[Utils checkObjectForNull:[[msgDict objectForKey:@"content"] objectForKey:@"user_id"]] stringValue];
//    if (userIdStr && userIdStr.length > 0 && [userIdStr isEqualToString:self.senderId]) {
//        msg.senderIdStr = userIdStr;
//        fromUser = YES;
//    }
//    else {
//        msg.senderIdStr = [[Utils checkObjectForNull:[[msgDict objectForKey:@"content"] objectForKey:@"contact_id"]] stringValue];
//    }
//
//    // payload from Pusher doesn't currently include sender names, so we need to figure them out. if the message
//    // is from the contact being viewed, we use our contactDisplayName, if not, we use our current user display name
//    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
//    if ([msg.senderIdStr isEqualToString:appDelegate.currentUser.idStr]) {
//        msg.senderName = [NSString stringWithFormat:@"%@ %@", appDelegate.currentUser.firstName, appDelegate.currentUser.lastName];
//    }
//    else {
//        msg.senderName = self.contactDisplayName;
//    }

    TUMessage *msg = notification.object;
    
    BOOL fromUser = NO;
    BOOL fromContact = NO;
    
//    if ([msg.senderIdStr isEqualToString:self.contact.idStr]) {
//        fromContact = YES;
//    }
//    else if ([msg.senderIdStr isEqualToString:self.senderId]) {
//        fromUser = YES;
//    }
    
    if ([msg.senderType isEqualToString:@"User"]) {
        fromUser = YES;
    }
    else if ([msg.senderType isEqualToString:@"Contact"]) {
        fromContact = YES;
    }

    if (fromUser || fromContact) {
        
        BOOL found = NO;
        for (TUMessage *eMsg in self.messages) {
            if ([eMsg.idStr isEqualToString:msg.idStr]) {
                found = YES;
                break;
            }
        }
        
        if (!found) {
            
            [self.messages addObject:msg];
            
            JSQMessage *jsqMsg = [[JSQMessage alloc] initWithSenderId:msg.senderIdStr senderDisplayName:msg.senderName date:msg.createdDate text:msg.content];
            [self.JSQMessages addObject:jsqMsg];
            
            if (fromUser) {
                [JSQSystemSoundPlayer jsq_playMessageSentSound];
            }
            else {
                [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
            }
            [self finishReceivingMessageAnimated:YES];
        }
    }
}

#pragma mark - Testing

- (void)pushMainViewController
{
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nc = [sb instantiateInitialViewController];
    [self.navigationController pushViewController:nc.topViewController animated:YES];
}


#pragma mark - Actions

- (IBAction)showContactDetails:(id)sender {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ContactDetailsViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ContactDetailsViewController"];
    vc.contact = self.contact;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showMessageTemplates:(id)sender {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nc = [sb instantiateViewControllerWithIdentifier:@"MessageTemplatesNavigationController"];
    MessageTemplatesTableViewController *vc = (MessageTemplatesTableViewController*)[nc.viewControllers objectAtIndex:0];
    vc.delegate = self;
    [self presentViewController:nc animated:YES completion:nil];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressAccessoryButton:(UIButton *)sender {
    
    [self.inputToolbar.contentView.textView resignFirstResponder];

    [self performSelector:@selector(showMessageTemplates:) withObject:sender afterDelay:0.3];
}

- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
    /**
     *  Sending a message. Your implementation of this method should do *at least* the following:
     *
     *  1. Play sound (optional)
     *  2. Add new id<JSQMessageData> object to your data source
     *  3. Call `finishSendingMessage`
     */
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }

    if (!text || text.length == 0) {
        return;
    }

    [self setupSendingMessageBusy:YES];
    
    NSString *urlStr = @"messages";
    id params = @{@"content":text, @"sender":senderId, @"receiver":self.contact.idStr};
    
    [[AuthAPIClient sharedClient] POST:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        NSLog(@"ResponseObject: %@", responseObject);

        // the posted message is sent to us via Pusher...actually before this block is called...so we don't process
        // here at all, just clear our text field
        
        self.inputToolbar.contentView.textView.text = nil;
        
        [self setupSendingMessageBusy:NO];

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        [Utils handleGeneralError:error fromViewController:self];
        
        [self setupSendingMessageBusy:NO];
    }];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.JSQMessages objectAtIndex:indexPath.item];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
    [self.JSQMessages removeObjectAtIndex:indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  You may return nil here if you do not want bubbles.
     *  In this case, you should set the background color of your collection view cell's textView.
     *
     *  Otherwise, return your previously created bubble image data objects.
     */
    
    JSQMessage *message = [self.JSQMessages objectAtIndex:indexPath.item];
    
    if ([message.senderId isEqualToString:self.senderId]) {
        return self.outgoingBubbleImageData;
    }
    
    return self.incomingBubbleImageData;
}

//- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    /**
//     *  Return `nil` here if you do not want avatars.
//     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
//     *
//     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
//     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
//     *
//     *  It is possible to have only outgoing avatars or only incoming avatars, too.
//     */
//    
//    /**
//     *  Return your previously created avatar image data objects.
//     *
//     *  Note: these the avatars will be sized according to these values:
//     *
//     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
//     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
//     *
//     *  Override the defaults in `viewDidLoad`
//     */
//    JSQMessage *message = [self.JSQMessages objectAtIndex:indexPath.item];
//    
//    if ([message.senderId isEqualToString:self.senderId]) {
//        if (![NSUserDefaults outgoingAvatarSetting]) {
//            return nil;
//        }
//    }
//    else {
//        if (![NSUserDefaults incomingAvatarSetting]) {
//            return nil;
//        }
//    }
//    
//    
//    return [self.demoData.avatars objectForKey:message.senderId];
//}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
     *  The other label text delegate methods should follow a similar pattern.
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        JSQMessage *message = [self.JSQMessages objectAtIndex:indexPath.item];
        return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
    }
    
    return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    JSQMessage *message = [self.JSQMessages objectAtIndex:indexPath.item];
    
    /**
     *  iOS7-style sender name labels
     */
    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.JSQMessages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:message.senderId]) {
            return nil;
        }
    }
    
    /**
     *  Don't specify attributes to use the defaults.
     */

    if ([message.senderId isEqualToString:self.senderId]) {
        return [[NSAttributedString alloc] initWithString:@"You"];
    }
    
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [self.JSQMessages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Override point for customizing cells
     */
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *msg = [self.JSQMessages objectAtIndex:indexPath.item];
    
    if (!msg.isMediaMessage) {
        
        if ([msg.senderId isEqualToString:self.senderId]) {
            cell.textView.textColor = [UIColor whiteColor];
        }
        else {
            cell.textView.textColor = [UIColor blackColor];
        }
        
        cell.textView.linkTextAttributes = @{ NSForegroundColorAttributeName : cell.textView.textColor,
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    }
    
    return cell;
}



#pragma mark - UICollectionView Delegate

#pragma mark - Custom menu items

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(customAction:)) {
        [self customAction:sender];
        return;
    }
    
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}

- (void)customAction:(id)sender
{
    NSLog(@"Custom action received! Sender: %@", sender);
    
    [[[UIAlertView alloc] initWithTitle:@"Custom Action"
                                message:nil
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil]
     show];
}



#pragma mark - JSQMessages collection view flow layout delegate

#pragma mark - Adjusting cell label heights

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
     */
    
    /**
     *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
     *  The other label height delegate methods should follow similarly
     *
     *  Show a timestamp for every 3rd message
     */
    if (indexPath.item % 3 == 0) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return 0.0f;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
    /**
     *  iOS7-style sender name labels
     */

    JSQMessage *currentMessage = [self.JSQMessages objectAtIndex:indexPath.item];

    if (indexPath.item - 1 > 0) {
        JSQMessage *previousMessage = [self.JSQMessages objectAtIndex:indexPath.item - 1];
        if ([[previousMessage senderId] isEqualToString:[currentMessage senderId]]) {
            return 0.0f;
        }
    }
    
    if ([[currentMessage senderId] isEqualToString:self.senderId]) {
        return kJSQMessagesCollectionViewCellLabelHeightDefault;
    }
    
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
    return 0.0f;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
    NSLog(@"Load earlier messages!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped avatar!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Tapped message bubble!");
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
}

#pragma mark MessageTemplatesVC delegate

- (void)MessageTemplatesTableViewController:(MessageTemplatesTableViewController *)controller doneWithTemplate:(TUMessageTemplate *)messageTemplate {
    
    if (messageTemplate && messageTemplate.content && messageTemplate.content.length) {
        
        // replace template fields with contact data
        NSMutableString *mStr = [NSMutableString stringWithString:messageTemplate.content];
        if (self.contact.firstName && self.contact.firstName.length) {
            [mStr replaceOccurrencesOfString:kFirstNameTemplateKey withString:self.contact.firstName options:NSLiteralSearch range:NSMakeRange(0, mStr.length)];
        }
        if (self.contact.lastName && self.contact.lastName.length) {
            [mStr replaceOccurrencesOfString:kLastNameTemplateKey withString:self.contact.lastName options:NSLiteralSearch range:NSMakeRange(0, mStr.length)];
        }
        if (self.contact.businessName && self.contact.businessName.length) {
            [mStr replaceOccurrencesOfString:kBusinessNameTemplateKey withString:self.contact.businessName options:NSLiteralSearch range:NSMakeRange(0, mStr.length)];
        }
        
        NSString *finalStr = [NSString stringWithString:mStr];

        // need to see difference in contentSize height after set the text then call Super
        // so it can update the view elements
        
        UITextView *textView = self.inputToolbar.contentView.textView;

        CGFloat oldHeight = textView.contentSize.height;

        [textView setText:finalStr];
        
        CGFloat newHeight = textView.contentSize.height;
        [textView setContentSize:CGSizeMake(textView.contentSize.width, newHeight)];
        
        [self changeInputToolbarTextViewHeightByAmount:newHeight - oldHeight];
        
        // enable our send button
        self.inputToolbar.contentView.rightBarButtonItem.enabled = YES;
        
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UITextView delegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    
    if ([textView isFirstResponder]) {
        if ([[[textView textInputMode] primaryLanguage] isEqualToString:@"emoji"] || ![[textView textInputMode] primaryLanguage]) {
            return NO;
        }
    }
    return YES;
}

#pragma mark ContactDetailsViewController 

- (void)ContactDetailsViewController:(ContactDetailsViewController *)controller deletedContact:(TUContact *)contact {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods

- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
{
    if ([UIPasteboard generalPasteboard].image) {
        // If there's an image in the pasteboard, construct a media item with that image and `send` it.
        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
                                                 senderDisplayName:self.senderDisplayName
                                                              date:[NSDate date]
                                                             media:item];
        [self.JSQMessages addObject:message];
        [self finishSendingMessage];
        return NO;
    }
    return YES;
}

@end
