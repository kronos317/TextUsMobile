//
//  AuthAPIClient.m
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "AuthAPIClient.h"
#import "CredentialStore.h"
#import "AppDelegate.h"

@implementation AuthAPIClient

+ (id)sharedClient {
    static AuthAPIClient *__instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseUrl = [NSURL URLWithString:BASE_URL];
        __instance = [[AuthAPIClient alloc] initWithBaseURL:baseUrl];
    });
    return __instance;
}

- (id)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (self) {
        
        
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        self.responseSerializer = [AFJSONResponseSerializer serializer];
        
        //        [self registerHTTPOperationClass:[AFHTTPSessionManager class]];
        
        [self setAPIVersionTwoHeader];
        [self setAuthorizationHeader];
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tokenChanged:)
                                                     name:@"token-changed"
                                                   object:nil];
    }
    return self;
}

- (void)setAPIVersionTwoHeader {
    [self.requestSerializer setValue:@"application/vnd.textus-v2+json" forHTTPHeaderField:@"Accept"];
}

//- (void)setApiKey {
//    [self.requestSerializer setValue:@"rw_HC4cffv1fVuUciwA6DuVqmnk" forHTTPHeaderField:@"Authorization"];
//}

- (void)setAuthorizationHeader {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self setAuthorizationHeaderWithUsername:appDelegate.currentUser.username password:appDelegate.currentUser.password];
}

- (void)setAuthorizationHeaderWithUsername:(NSString*)username password:(NSString*)password {
    [self.requestSerializer setAuthorizationHeaderFieldWithUsername:username password:password];
}

//- (void)setAuthTokenHeader {
//    
//    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
//    NSString *authToken = [appDelegate.credentialStore authToken];
//    //[self setDefaultHeader:@"auth_token" value:authToken];
//    
//    [self.requestSerializer setAuthorizationHeaderFieldWithToken:authToken];
//}
//
//- (void)tokenChanged:(NSNotification *)notification {
//    [self setAuthTokenHeader];
//}


@end
