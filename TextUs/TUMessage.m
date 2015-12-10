//
//  TUMessage.m
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "TUMessage.h" //application/vnd.textus-v2+json
#import "Utils.h"

@implementation TUMessage

@synthesize content;
@synthesize read;
@synthesize broadcastId;
@synthesize idStr;
@synthesize status;
@synthesize createdDate;
@synthesize updatedDate;
@synthesize senderIdStr;
@synthesize senderType;
@synthesize senderPhone;
@synthesize receiverIdStr;
@synthesize receiverType;
@synthesize receiverPhone;
@synthesize createdDateStr;
@synthesize updatedDateStr;

- (id)initWithDict:(NSDictionary*)dataDict {
    self = [super init];
    if (self) {
        
        self.content = [Utils checkObjectForNull:[dataDict objectForKey:kMessageContentKey]];
        self.read = [[Utils checkObjectForNull:[dataDict objectForKey:kMessageReadKey]] boolValue];
        self.broadcastId = [[Utils checkObjectForNull:[dataDict objectForKey:kMessageBroadcastIdKey]] stringValue];
        self.idStr = [[Utils checkObjectForNull:[dataDict objectForKey:kMessageIdKey]] stringValue];
        self.status = [Utils checkObjectForNull:[dataDict objectForKey:kMessageStatusKey]];
        self.createdDateStr = [Utils checkObjectForNull:[dataDict objectForKey:kMessageCreateDateKey]];
        self.updatedDateStr = [Utils checkObjectForNull:[dataDict objectForKey:kMessageUpdateDateKey]];
        self.senderIdStr = [[Utils checkObjectForNull:[dataDict objectForKey:kMessageSenderIdKey]] stringValue];
        self.senderType = [Utils checkObjectForNull:[dataDict objectForKey:kMessageSenderTypeKey]];
        self.senderPhone = [Utils checkObjectForNull:[dataDict objectForKey:kMessageSenderPhoneKey]];
        self.receiverIdStr = [[Utils checkObjectForNull:[dataDict objectForKey:kMessageReceiverIdKey]] stringValue];
        self.receiverType = [Utils checkObjectForNull:[dataDict objectForKey:kMessageReceiverTypeKey]];
        self.receiverPhone = [Utils checkObjectForNull:[dataDict objectForKey:kMessageReceiverPhoneKey]];
        
        self.receiverName = [Utils checkObjectForNull:[dataDict objectForKey:kMessageReceiverNameKey]];
        self.senderName = [Utils checkObjectForNull:[dataDict objectForKey:kMessageSenderNameKey]];
        
        self.createdDate = [Utils dateForDateString:self.createdDateStr];
        self.updatedDate = [Utils dateForDateString:self.updatedDateStr];
        
        if (!self.createdDate || ![self.createdDate isKindOfClass:[NSDate class]]) {
            self.createdDate = [NSDate date];
        }
    }
    return self;
}


@end
