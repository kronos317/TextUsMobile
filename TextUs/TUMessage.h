//
//  TUMessage.h
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kMessageContentKey = @"content";
static NSString *kMessageReadKey = @"read";
static NSString *kMessageBroadcastIdKey = @"broadcast_id";
static NSString *kMessageIdKey = @"id";
static NSString *kMessageStatusKey = @"status";
static NSString *kMessageCreateDateKey = @"created_at";
static NSString *kMessageUpdateDateKey = @"updated_at";
static NSString *kMessageSenderIdKey = @"sender_id";
static NSString *kMessageSenderTypeKey = @"sender_type";
static NSString *kMessageSenderPhoneKey = @"sender_phone";
static NSString *kMessageReceiverIdKey = @"receiver_id";
static NSString *kMessageReceiverTypeKey = @"receiver_type";
static NSString *kMessageReceiverPhoneKey = @"receiver_phone";
static NSString *kMessageReceiverNameKey = @"receiver_name";
static NSString *kMessageSenderNameKey = @"sender_name";

@interface TUMessage : NSObject

- (id)initWithDict:(NSDictionary*)dataDict;

@property (nonatomic, strong) NSString  *content;
@property (assign)            BOOL      read;
@property (nonatomic, strong) NSString  *broadcastId;
@property (nonatomic, strong) NSString  *idStr;
@property (nonatomic, strong) NSString  *status;
@property (nonatomic, strong) NSString  *createdDateStr;
@property (nonatomic, strong) NSString  *updatedDateStr;
@property (nonatomic, strong) NSString  *senderIdStr;
@property (nonatomic, strong) NSString  *senderType;
@property (nonatomic, strong) NSString  *senderPhone;
@property (nonatomic, strong) NSString  *receiverIdStr;
@property (nonatomic, strong) NSString  *receiverType;
@property (nonatomic, strong) NSString  *receiverPhone;

@property (nonatomic, strong) NSString  *receiverName;
@property (nonatomic, strong) NSString  *senderName;

@property (nonatomic, strong) NSDate  *createdDate;
@property (nonatomic, strong) NSDate  *updatedDate;

@end
