//
//  PusherClient.h
//  TextUs
//
//  Created by Josh Bruhin on 11/24/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Pusher/Pusher.h>

#define kPUSHER_APP_KEY @"3c8939d731a24a81a6e6"
#define kPUSHER_CHANNEL_PREFIX @"private-account_"
#define kPUSHER_EVENT_NAME @"inbound-message"
#define kPUSHER_AUTH_URL @"https://app.textus.com/api/channels/authenticate"

@interface PusherClient : NSObject <PTPusherConnectionDelegate, PTPusherDelegate> {
    __strong PTPusherEventBinding *_pusherBinding;
    NSInteger _subscriptionRetryCount;
}

+ (id)sharedClient;

@property (nonatomic, strong)   PTPusher *client;

@end
