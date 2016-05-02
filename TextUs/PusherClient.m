//
//  PusherClient.m
//  TextUs
//
//  Created by Josh Bruhin on 11/24/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "PusherClient.h"
#import "AppDelegate.h"
#import "TUMessage.h"
#import "AFNetworkReachabilityManager.h"
#import "Utils.h"

//static NSInteger kSubscriptionRetryAmount = 5;

@implementation PusherClient

@synthesize client;

+ (id)sharedClient {
    static PusherClient *__instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __instance = [[PusherClient alloc] init];
    });
    return __instance;
}

- (id)init {
    self = [super init];
    if (self) {
        
        _subscriptionRetryCount = 0;
        self.client = [PTPusher pusherWithKey:kPUSHER_APP_KEY delegate:self];
        self.client.delegate = self;
        self.client.authorizationURL = [NSURL URLWithString:kPUSHER_AUTH_URL];
        [self.client connect];
        
        [self subscribeToAccountChannel];
        
        [self subscribeToUserChannel]; // do this so server can track if user is connected or not
    }
    return self;
}

- (void)handleChannelSubscriptionFailureChannel:(PTPusherChannel*)channel {
    
    if ([[AFNetworkReachabilityManager sharedManager] isReachable]) {
        
        if (channel == _pusherAccountChannel) {
            [self.client removeAllBindings];
            _pusherAccountBinding = nil;
            [self subscribeToAccountChannel];
        }
        else {
            [self subscribeToUserChannel];
        }
    }
}

- (void)subscribeToAccountChannel {
    _pusherAccountChannel = [self.client subscribeToChannelNamed:[self channelNameAccount]];
    _pusherAccountBinding = [_pusherAccountChannel bindToEventNamed:kPUSHER_EVENT_NAME handleWithBlock:^(PTPusherEvent *channelEvent) {
        // channelEvent.data is a NSDictianary of the JSON object received
        NSLog(@"channelEvent: %@", channelEvent);
        
        [self handleNewMessageResponse:channelEvent.data];
        
    }];
}

- (void)subscribeToUserChannel {
    _pusherUserChannel = [self.client subscribeToChannelNamed:[self channelNameUser]];
}

- (NSString*)channelNameAccount {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [NSString stringWithFormat:@"%@%@", kPUSHER_CHANNEL_PREFIX, appDelegate.currentUser.accountIdStr];
}

- (NSString*)channelNameUser {
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    return [NSString stringWithFormat:@"%@%@", kPUSHER_USER_CHANNEL_PREFIX, appDelegate.currentUser.idStr];
}

- (void)handleNewMessageResponse:(id)responseObject {
    
    NSDictionary *cDict = [responseObject objectForKey:@"content"];
    if (cDict && [cDict isKindOfClass:[NSDictionary class]]) {
        NSDictionary *mDict = [cDict objectForKey:@"message"];
        if (mDict && [mDict isKindOfClass:[NSDictionary class]]) {
            
            TUMessage *msg = [[TUMessage alloc] initWithDict:mDict];
            [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:@"NewMessageReceived" object:msg]];
            
        }
    }
}

- (void)handleConnectionFailure {
    // if we have no connection, appDelegate will handle reconnecting after connection state change notif
    if ([[AFNetworkReachabilityManager sharedManager] isReachable]) {
        [self.client connect];
    }
}

#pragma mark - Pusher delegate

- (BOOL)pusherConnectionWillConnect:(PTPusherConnection *)connection {
    return YES;
}


- (void)pusherConnection:(PTPusherConnection *)connection didFailWithError:(NSError *)error wasConnected:(BOOL)wasConnected {
    NSLog(@"pusher did fail: %@", error);
    [self handleConnectionFailure];
}

- (void)pusherConnection:(PTPusherConnection *)connection didReceiveEvent:(PTPusherEvent *)event {
    NSLog(@"pusher event: %@", event);
}

- (void)pusherConnectionDidConnect:(PTPusherConnection *)connection {
    NSLog(@"pusher connection: %@", connection);
}

- (void)pusherConnection:(PTPusherConnection *)connection didDisconnectWithCode:(NSInteger)errorCode reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSLog(@"pusher disconnect: %@", reason);
    [self handleConnectionFailure];
}

- (void)pusher:(PTPusher *)pusher didSubscribeToChannel:(PTPusherChannel *)channel {
    NSLog(@"pusher did subscribe: %@", channel);
    _subscriptionRetryCount = 0;
}

- (void)pusher:(PTPusher *)pusher didReceiveErrorEvent:(PTPusherErrorEvent *)errorEvent {
    NSLog(@"pusher did receive error event: %@", errorEvent);
}

- (void)pusher:(PTPusher *)pusher didFailToSubscribeToChannel:(PTPusherChannel *)channel withError:(NSError *)error {
    NSLog(@"pusher did fail to subscribe: %@", error);
    
//    if (_subscriptionRetryCount < kSubscriptionRetryAmount) {
//        [self handleChannelSubscriptionFailure];
        [self performSelector:@selector(handleChannelSubscriptionFailureChannel:) withObject:channel afterDelay:5.0];
        _subscriptionRetryCount ++;
//    }
}

- (void)pusher:(PTPusher *)pusher connectionDidConnect:(PTPusherConnection *)connection {
    NSLog(@"pusher did connect: %@", connection);
    
    NSString *title = @"pusher did connect";
    id infoDict = @{@"title":title, @"message":@""};
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PusherConnectionFailed" object:infoDict];
}

- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection failedWithError:(NSError *)error {
    NSLog(@"pusher did fail: %@", error);
    [self handleConnectionFailure];
}

- (void)pusher:(PTPusher *)pusher connection:(PTPusherConnection *)connection didDisconnectWithError:(NSError *)error willAttemptReconnect:(BOOL)willAttemptReconnect {
    NSLog(@"pusher did fail: %@", error);
    
    if (!willAttemptReconnect) {
        [self handleConnectionFailure];
    }
}

- (void)pusher:(PTPusher *)pusher willAuthorizeChannel:(PTPusherChannel *)channel withRequest:(NSMutableURLRequest *)request {
    
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (!appDelegate.currentUser.username || !appDelegate.currentUser.password) {
        NSLog(@"username or password is nil");
    }
    
    NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", appDelegate.currentUser.username, appDelegate.currentUser.password];
    
    NSData *nsdata = [basicAuthCredentials dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64Encoded = [nsdata base64EncodedStringWithOptions:0];
    
    [request setValue:[NSString stringWithFormat:@"Basic %@", base64Encoded] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/vnd.textus-v2+json" forHTTPHeaderField:@"Accept"];
}

@end
