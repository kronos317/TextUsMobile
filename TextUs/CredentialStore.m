//
//  CredentialStore.m
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "CredentialStore.h"
#import "SSKeychain.h"

#define SERVICE_NAME @"TextUs-AuthClient"
#define AUTH_TOKEN_KEY @"auth_token"
#define PASSWORD_KEY @"password"
#define USERNAME_KEY @"username"

@implementation CredentialStore


- (BOOL)isLoggedIn {
    return [self authToken] != nil;
}

- (void)clearSavedCredentials {
    [self setAuthToken:nil];
    [self setUsername:nil];
    [self setPword:nil];
}

// auth token

- (NSString *)authToken {
    return [self secureValueForKey:AUTH_TOKEN_KEY];
}

- (void)setAuthToken:(NSString *)authToken {
    [self setSecureValue:authToken forKey:AUTH_TOKEN_KEY];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"token-changed" object:self];
}

// username

- (NSString *)username {
    return [self secureValueForKey:USERNAME_KEY];
}

- (void)setUsername:(NSString *)username {
    [self setSecureValue:username forKey:USERNAME_KEY];
}


// password

- (NSString *)pword {
    return [self secureValueForKey:PASSWORD_KEY];
}

- (void)setPword:(NSString *)pword {
    [self setSecureValue:pword forKey:PASSWORD_KEY];
}




- (void)setSecureValue:(NSString *)value forKey:(NSString *)key {
    if (value) {
        [SSKeychain setPassword:value
                     forService:SERVICE_NAME
                        account:key];
    } else {
        [SSKeychain deletePasswordForService:SERVICE_NAME account:key];
    }
}

- (NSString *)secureValueForKey:(NSString *)key {
    return [SSKeychain passwordForService:SERVICE_NAME account:key];
}


@end
