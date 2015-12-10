//
//  TUUser.m
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "TUUser.h"
#import "Utils.h"

@implementation TUUser

@synthesize email;
@synthesize firstName;
@synthesize lastName;
@synthesize lastSignInDate;
@synthesize shouldPlayAudio;
@synthesize forwardMessages;
@synthesize idStr;
@synthesize createdDate;
@synthesize updatedDate;
@synthesize accountIdStr;
@synthesize username;
@synthesize password;

- (id)initWithDict:(NSDictionary*)dataDict {
    self = [super init];
    if (self) {
        self.email = [dataDict objectForKey:kUserEmailKey];
        self.firstName = [dataDict objectForKey:kUserFirstNameKey];
        self.lastName = [dataDict objectForKey:kUserLastNameKey];
        self.lastSignInDate = [dataDict objectForKey:kUserLastSignInKey];
        self.shouldPlayAudio = [[Utils checkObjectForNull:[dataDict objectForKey:kUserPlayAudioKey]] boolValue];
        self.forwardMessages = [dataDict objectForKey:kUserForwardMessagesKey];
        self.idStr = [[Utils checkObjectForNull:[dataDict objectForKey:kUserIdKey]] stringValue];
        self.createdDate = [dataDict objectForKey:kUserCreateDateKey];
        self.updatedDate = [dataDict objectForKey:kUserUpdateDateKey];
        self.accountIdStr = [[Utils checkObjectForNull:[dataDict objectForKey:kUserAccountIdKey]] stringValue];
    }
    return self;
}

@end
