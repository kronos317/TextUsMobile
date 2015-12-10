//
//  Utils.h
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Utils : NSObject

+ (UIView*)navBarTitleView;
+ (NSString *)localizedStringForDate:(NSDate*)date withTime:(BOOL)withTime withYear:(BOOL)withYear;
+ (NSInteger)heightForString:(NSString*)theStr withFont:(UIFont*)font forWith:(NSInteger)width;
+ (NSArray*)processMessagesResponse:(NSArray*)responseArray;
+ (NSArray*)processContactsResponse:(NSArray*)responseArray;
+ (id) checkObjectForNull:(id) object;
+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message fromViewController:(UIViewController*)vc;
+ (void)handleGeneralError:(NSError*)error fromViewController:(UIViewController*)vc;
+ (NSDate*)dateForDateString:(NSString*)dateString;
+ (BOOL)connected;
+ (BOOL)notConnectedShowAlert:(BOOL)showAlert fromVC:(UIViewController*)vc;

@end
