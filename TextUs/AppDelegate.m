//
//  AppDelegate.m
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "AppDelegate.h"
#import "UIColor+TU.h"
#import <Parse/Parse.h>
#import "PusherClient.h"
#import "AFNetworkReachabilityManager.h"
#import "AuthAPIClient.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize credentialStore;

- (void)customizeAppearance {
//    [[UIBarButtonItem appearance] setTintColor:[UIColor tuBlueColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor tuBlueColor]];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self setupCredentialStore];
    [self setupCurrentUser];
    [self customizeAppearance];
    [self setupParse];
    [self setupPusher];
    [self setupPushNotifications];
    [self setupFirstView];
    [self setupNetworkMonitoring];
        
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:deviceToken];
    NSString *channelStr = [NSString stringWithFormat:@"private-user_%@", self.currentUser.idStr];
    currentInstallation.channels = @[channelStr]; // private-user_{user_id}
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    // this method called when app active. we don't want to show the message or do anything for now
//    [PFPush handlePush:userInfo];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    // so messages screen can refresh data
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ApplicationDidBecomeActive" object:nil];
    
    // clear our badge count
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    // check if pusher is connected
    if (self.currentUser) {
        PusherClient *pusher = [PusherClient sharedClient];
        if (!pusher.client.connection.connected) {
            [pusher.client connect];
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)setupCredentialStore {
    
    CredentialStore *store = [[CredentialStore alloc] init];
    self.credentialStore = store;
}

- (void)setupParse {
    [Parse setApplicationId:@"M7ZSGoOhx1u2GPUO8v8ZG9E9AXq6YRJyvW51eHda"
                  clientKey:@"DdqnP2Ea5MSgHo57Yv313XfVgMSoXO84QXnWXwlP"];
}

- (void)setupCurrentUser {
    
    self.currentUser = nil;
    
    NSString *username = self.credentialStore.username;
    NSString *password = self.credentialStore.pword;
    NSDictionary *userDict = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentUserDict"];

    if (username && password && userDict) {
        self.currentUser = [[TUUser alloc] initWithDict:userDict];
        self.currentUser.username = username;
        self.currentUser.password = password;
    }
}

- (void)setupPusher {
    if (self.currentUser) {
        [PusherClient sharedClient];
    }
}

- (void)setupPushNotifications {
    
    if (!self.currentUser.idStr) {
        return;
    }
    

    UIApplication *application = [UIApplication sharedApplication];
    
    UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert |
                                                    UIUserNotificationTypeBadge |
                                                    UIUserNotificationTypeSound);
    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes
                                                                             categories:nil];
    [application registerUserNotificationSettings:settings];
    [application registerForRemoteNotifications];
    
}

- (void)setupFirstView {
    
    // if they're logged in, go straight to messages
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *viewController;
    if (self.currentUser) {
        viewController = [sb instantiateViewControllerWithIdentifier:@"MessagesNavigationController"];
    }
    else {
        viewController = [sb instantiateViewControllerWithIdentifier:@"LoginNavigationController"];
    }
    
    self.window.rootViewController = viewController;
    [self.window makeKeyAndVisible];

}

- (void)setupNetworkMonitoring {
    
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        BOOL connected = NO;
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"No Internet Connection");
                connected = NO;
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"WIFI");
                
                connected = YES;
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"3G");
                connected = YES;
                break;
            default:
                NSLog(@"Unkown network status");
                connected = NO;
                break;
        }
        
        NSString *notifStr;
        if (connected) {
            
            notifStr = @"NetworkRestored";
            if (self.currentUser) {
                PusherClient *pusher = [PusherClient sharedClient];
                [pusher.client connect];
            }
        }
        else {
            notifStr = @"NetworkLost";
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:notifStr object:nil];

    }];
}

@end
