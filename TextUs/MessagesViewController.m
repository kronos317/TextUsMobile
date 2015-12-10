//
//  MessagesViewController.m
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "MessagesViewController.h"
#import "TUConversation.h"
#import "TUMessage.h"
#import "TUContact.h"
#import "ChatViewController.h"
#import "AppDelegate.h"

@interface MessagesViewController ()

@end

@implementation MessagesViewController

@synthesize isModal;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupObservers];
    [self initTemplateCell];
    _dirtyData = NO;
    _requestingData = NO;
}

- (void)setupObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNewMessageNotification:)
                                                 name:@"NewMessageReceived" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(requestData)
                                                 name:@"ApplicationDidBecomeActive" object:nil];
}

- (void)handleNewMessageNotification:(NSNotification*)notification {
    
    
    // if user is currently viewing chat for the contact, then we need to mark this message read
    // if the message is from the user, then mark it as read
    
    TUMessage *msg = notification.object;
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    BOOL fromUser = [msg.senderIdStr isEqualToString:appDelegate.currentUser.idStr];
    
    BOOL chatOpen = NO;
    if (!fromUser && [self.navigationController.topViewController isKindOfClass:[ChatViewController class]]) {

        BOOL messageFromUser = ([msg.senderIdStr isEqualToString:appDelegate.currentUser.idStr]);
        NSString *msgContactIdStr = messageFromUser ? msg.receiverIdStr : msg.senderIdStr;
        
        ChatViewController *vc = (ChatViewController*)[[self.navigationController viewControllers] lastObject];
        if ([vc.contact.idStr isEqualToString:msgContactIdStr]) {
            
            chatOpen = YES;
            [self postMessageRead:msg thenRequestData:YES];
        }
    }

    if (fromUser || chatOpen) {
        [self postMessageRead:msg thenRequestData:YES];
    }
    else {
        [self requestDataPlaySound:YES];
    }
}

- (void) initTemplateCell {
    
    NSArray *topLevel = [[NSBundle mainBundle] loadNibNamed:@"MessagesTableViewCell" owner:self options:nil];
    for (id currentObject in topLevel){
        if ([currentObject isKindOfClass:[MessagesTableViewCell class]]){
            _templateCell = (MessagesTableViewCell *)currentObject;
            break;
        }
    }
}

- (void)setupNavBar {
    self.navigationItem.titleView = [Utils navBarTitleView];
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"logoutButton"] style:UIBarButtonItemStylePlain target:self action:@selector(logoutHit:)];
    self.navigationItem.rightBarButtonItem = button;
}


#pragma mark Actions

- (void)logoutHit:(UIBarButtonItem*)sender {
    
    // if the user was not authenticated when launching app, then we have a login VC, so send notification
    // if not, then we create and present one
    
    if (self.isModal) {
        // send notification
        [[NSNotificationCenter defaultCenter] postNotificationName:@"logout" object:nil];
    }
    else {
        // need to make and present one
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"LoginViewController"];
        [self presentViewController:vc animated:YES completion:nil];
    }
    
    // clear our credentials
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    [appDelegate.credentialStore setUsername:nil];
    [appDelegate.credentialStore setPword:nil];
    
    appDelegate.currentUser = nil;
}

- (NSString*)siblingVCIdentifierStr {
    return @"ContactsViewController";
}

- (void)showDetailsForConversation:(TUConversation*)conversation {

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChatViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ChatViewController"];
    
    vc.senderId = appDelegate.currentUser.idStr;
    vc.senderDisplayName = [NSString stringWithFormat:@"%@ %@", appDelegate.currentUser.firstName, appDelegate.currentUser.lastName];
    
    vc.contact = conversation.contact;
    vc.contactDisplayName = [NSString stringWithFormat:@"%@ %@", conversation.contact.firstName, conversation.contact.lastName];

    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showDetailsForMessage:(TUMessage*)message {
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChatViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ChatViewController"];
    
    vc.senderId = appDelegate.currentUser.idStr;
    vc.senderDisplayName = [NSString stringWithFormat:@"%@ %@", appDelegate.currentUser.firstName, appDelegate.currentUser.lastName];
    
    // if the sender ID is the current user, then we use the receiver ID
    NSString *contactID = nil;
    NSString *contactName = nil;
    if ([message.senderIdStr isEqualToString:appDelegate.currentUser.idStr]) {
        contactID = message.receiverIdStr;
        contactName = message.receiverName;
    }
    else {
        contactID = message.senderIdStr;
        contactName = message.senderName;
    }

    TUContact *contact = [[TUContact alloc] init];
    contact.idStr = contactID;
    contact.isIdOnly = YES;
    
    vc.contact = contact;
    vc.contactDisplayName = contactName;
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma Data processing

- (NSString*)searchUrlStr {
    return @"messages";
}

- (id)searchParamsWithSearchStr:(NSString*)searchStr {
    return @{@"page":[NSNumber numberWithInteger:_searchPageCount], @"per_page":@"25", @"q":searchStr};
}

- (void)postMessageRead:(TUMessage*)message thenRequestData:(BOOL)thenRequestData {
    
    __block TUMessage *__message = message;
    
    NSString *urlStr = [NSString stringWithFormat:@"messages/%@", message.idStr];
    id params = @{@"read":@"1", @"id":message.idStr};
    
    [[AuthAPIClient sharedClient] PUT:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"ResponseObject: %@", responseObject);
        
        if (thenRequestData) {
            [self requestData];
        }
        else {
            
            __message.read = YES;
            [_tableView reloadData];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        
    }];
}

- (void)requestData {
    [self requestDataPlaySound:NO];
}

- (void)requestDataPlaySound:(BOOL)playSound {
    
    if (![Utils connected]) {
        return;
    }
    
    if (_requestingData) {
        return;
    }
    
    _requestingData = YES;
    
    __block BOOL __playSound = playSound;
    
    [_spinner startAnimating];
    
    NSString *urlStr = @"conversations";
    id params = @{@"page":@"1", @"per_page":@"25"};
        
    [[AuthAPIClient sharedClient] GET:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"ResponseObject: %@", responseObject);
        [self processConversationsResponse:responseObject];
        
        [_spinner stopAnimating];

        if (!self.isSearching) {
            if (_initialDataLoaded) {
                [_tableView reloadData];
            }
            else {
                [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
        
        if (__playSound) {
            [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
        }
        
        _requestingData = NO;

    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        [Utils handleGeneralError:error fromViewController:self];
        
        [_spinner stopAnimating];
        _requestingData = NO;
    }];
    
}

- (void)processSearchResonse:(id)responseObj {
    
    NSArray *messages = [Utils processMessagesResponse:(NSArray*)responseObj];
    
    if (!_searchDataArray) {
        _searchDataArray = [[NSMutableArray alloc] initWithCapacity:100];
    }

    [_searchDataArray addObjectsFromArray:messages];
}

- (void)processConversationsResponse:(NSArray*)responseArray {
    
    NSMutableArray *mConvArray = [[NSMutableArray alloc] initWithCapacity:responseArray.count];
    for (NSDictionary *dict in responseArray) {
        
        NSDictionary *contactDict = [dict objectForKey:@"contact"];
        TUContact *contact = [[TUContact alloc] initWithDict:contactDict];
        
        NSArray *msgResponseArray = [dict objectForKey:@"messages"];
        TUConversation *conversation = [[TUConversation alloc] init];
        conversation.contact = contact;
        conversation.messages = [Utils processMessagesResponse:msgResponseArray];
        
        [mConvArray addObject:conversation];
    }
    
    _defaultDataArray = [NSArray arrayWithArray:mConvArray];
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    TUMessage *msg = [self messageForIndexPath:indexPath];
    cell.backgroundColor = msg.read ? [UIColor whiteColor] : [UIColor redColor];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // if were searching, then we hve TUMessages. if we're not searching, then we have TUConversations
    
    TUMessage *msg = [self messageForIndexPath:indexPath];
    if (self.isSearching) {
        [self showDetailsForMessage:msg];
    }
    else {
        [self showDetailsForConversation:[self conversationForIndexPath:indexPath]];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (!msg.read) {
        [self postMessageRead:msg thenRequestData:NO];
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MessagesTableViewCell *cell = (MessagesTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"MessagesTableViewCell"];
    TUMessage *msg = [self messageForIndexPath:indexPath];
    cell.message = msg;
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return [_templateCell heightForCellForMessage:[self messageForIndexPath:indexPath]];
}

- (TUConversation*)conversationForIndexPath:(NSIndexPath*)indexPath {
    return [_defaultDataArray objectAtIndex:indexPath.row];
}

- (TUMessage*)messageForIndexPath:(NSIndexPath*)indexPath {
    
    TUMessage *msg = nil;
    if (_isSearching) {
        msg = [_searchDataArray objectAtIndex:indexPath.row];
    }
    else {
        
        TUConversation *conv = [_defaultDataArray objectAtIndex:indexPath.row];
        msg = [conv.messages objectAtIndex:0];
        
//        // find first message that is not the users
//        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
//        for (TUMessage *eMsg in conv.messages) {
//            if (![eMsg.senderIdStr isEqualToString:appDelegate.currentUser.idStr]) {
//                msg = eMsg;
//                break;
//            }
//        }
//        if (!msg) {
//            msg = [conv.messages objectAtIndex:0];
//        }
    }
    return msg;
}

@end
