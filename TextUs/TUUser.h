//
//  TUUser.h
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kUserEmailKey = @"email";
static NSString *kUserFirstNameKey = @"first_name";
static NSString *kUserLastNameKey = @"last_name";
static NSString *kUserLastSignInKey = @"last_sign_in_at";
static NSString *kUserPlayAudioKey = @"should_play_audio";
static NSString *kUserForwardMessagesKey = @"forward_messages";
static NSString *kUserIdKey = @"id";
static NSString *kUserCreateDateKey = @"created_at";
static NSString *kUserUpdateDateKey = @"updated_at";
static NSString *kUserAccountIdKey = @"account_id";

@interface TUUser : NSObject

@property (nonatomic, strong)   NSString    *email;
@property (nonatomic, strong)   NSString    *firstName;
@property (nonatomic, strong)   NSString    *lastName;
@property (nonatomic, strong)   NSString    *lastSignInDate;
@property (assign)              BOOL        shouldPlayAudio;
@property (nonatomic, strong)   NSString    *forwardMessages;
@property (nonatomic, strong)   NSString    *idStr;
@property (nonatomic, strong)   NSString    *accountIdStr;
@property (nonatomic, strong)   NSDate      *createdDate;
@property (nonatomic, strong)   NSDate      *updatedDate;

// these populated from credentialStore upon app launch
@property (nonatomic, strong)   NSString    *username;
@property (nonatomic, strong)   NSString    *password;

- (id)initWithDict:(NSDictionary*)dataDict;

@end
