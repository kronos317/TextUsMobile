//
//  LoginViewController.h
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString *kPasswordResetUrl = @"https://app.textus.com/users/password/new";

@interface LoginViewController : UIViewController <UITextFieldDelegate> {
    __strong UIScrollView *_scrollView;
    __strong UIView *_containerView;
    __strong UIActivityIndicatorView *_spinner;
    __strong UIButton *_submitButton;
    __strong UITextField *_usernameField;
    __strong UITextField *_passwordField;
}

@end
