//
//  AuthAPIClient.h
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "AFHTTPSessionManager.h"

#define API_KEY @"3Nm3zqxSiurlEMCql9cn6vWdrE0";
#define BASE_URL @"https://app.textus.com/api/"

@interface AuthAPIClient : AFHTTPSessionManager

+ (id)sharedClient;

- (void)setAuthorizationHeaderWithUsername:(NSString*)username password:(NSString*)password;

@end
