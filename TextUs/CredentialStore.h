//
//  CredentialStore.h
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CredentialStore : NSObject

- (BOOL)isLoggedIn;
- (void)clearSavedCredentials;

- (NSString *)authToken;
- (void)setAuthToken:(NSString *)authToken;

- (NSString *)username;
- (void)setUsername:(NSString *)username;

- (NSString *)pword;
- (void)setPword:(NSString *)pword;

@end
