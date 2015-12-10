//
//  AppDelegate.h
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CredentialStore.h"
#import "TUUser.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) CredentialStore *credentialStore;
@property (strong, nonatomic) TUUser    *currentUser;

- (void)setupPushNotifications;

@end

