//
//  LoginViewController.m
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "LoginViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <pop/POP.h>
#import "UIColor+TU.h"
#import "AppDelegate.h"
#import "AuthAPIClient.h"
#import "Utils.h"
#import "MessagesViewController.h"
#import "PusherClient.h"


@interface LoginViewController ()

@end

static CGFloat kLogoHeight = 60.0;
static CGFloat kMarginX = 20.0;

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationController setNavigationBarHidden:YES];
    
    [self addLogoutObserver];
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [self addKeyboardObservers]; // so we can scroll view up when keyboard shows
}

- (void)viewWillDisappear:(BOOL)animated {
    [self removeKeyboardObservers]; // so view doesn't scroll when we resign firstResponder
    [_usernameField resignFirstResponder];
    [_passwordField resignFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated {
    [self resetView];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UINavigationController *nc = segue.destinationViewController;
    MessagesViewController *vc = (MessagesViewController*)[nc.viewControllers objectAtIndex:0];
    vc.isModal = YES;
}

- (void)addLogoutObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(logout)
                                                 name:@"logout" object:nil];
}

- (void)addKeyboardObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrame:)
                                                 name:UIKeyboardDidHideNotification object:nil];
}

- (void)removeKeyboardObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

- (void)logout {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification*)aNotification {
    
    // only do this if keyboard is down and we're starting from 0
    if (_scrollView.contentOffset.y == 0) {
        NSDictionary* info = [aNotification userInfo];
        CGFloat kbOrigin = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
        [self scrollViewRelativeToKeyboardOrigin:kbOrigin];
    }
}

- (void)scrollViewRelativeToKeyboardOrigin:(CGFloat)kbOrigin {
    CGFloat offset = _containerView.frame.origin.y + _containerView.frame.size.height - kbOrigin + 15;
    offset = offset < 0 ? 0 : offset;
    [_scrollView setContentOffset:CGPointMake(0, offset) animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark Actions

- (void)forgotPasswordHit:(NSString*)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kPasswordResetUrl]];
}

- (void)loginHit:(UIButton*)sender {
    
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }
    
    POPSpringAnimation *scaleAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleAnimation.velocity = [NSValue valueWithCGSize:CGSizeMake(3.f, 3.f)];
    scaleAnimation.toValue = [NSValue valueWithCGSize:CGSizeMake(1.0, 1.0)];
    scaleAnimation.springBounciness = 20.0f;
    [sender.layer pop_addAnimation:scaleAnimation forKey:@"layerScaleSpringAnimation"];

    [self showSpinnerOverButton:sender];
    
    [self loginWithUsername:_usernameField.text password:_passwordField.text];
}

- (void)loginWithUsername:(NSString*)username password:(NSString*)password {
    
    // hardcoded
//    username = @"staging@textus.com";
//    password = @"changeme";
    
    __block NSString *__username = [username lowercaseString];
    __block NSString *__password = password;
    
    [[AuthAPIClient sharedClient] setAuthorizationHeaderWithUsername:__username password:__password];
    
    NSString *urlStr = @"users/current";
    
    [[AuthAPIClient sharedClient] GET:urlStr parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"ResponseObject: %@", responseObject);
        
        
        AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
        
        [appDelegate.credentialStore setUsername:__username];
        [appDelegate.credentialStore setPword:__password];
        
        TUUser *current = [[TUUser alloc] initWithDict:(NSDictionary*)responseObject];
        current.username = __username;
        current.password = __password;
        
        appDelegate.currentUser = current;
        
        [appDelegate setupPushNotifications];
        
        // now get pusher going
        [PusherClient sharedClient];
        
        // save to defaults
        [[NSUserDefaults standardUserDefaults] setObject:(NSDictionary*)responseObject forKey:@"CurrentUserDict"];
        
        [self performSegueWithIdentifier:@"SegueLoginSuccessful" sender:nil];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        
        [Utils handleGeneralError:error fromViewController:self];
        [self resetViewExceptUsername:YES];
    }];

}

- (void)showSpinnerOverButton:(UIButton*)button {
    
    [button setTitle:@"" forState:UIControlStateNormal];
    button.enabled = NO;
    
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _spinner.center = button.center;
    [button.superview addSubview:_spinner];
    [_spinner startAnimating];
}


#pragma mark View Setup

- (void)setupView {
    
    CGFloat marginY = 30.0;
    CGFloat contentWidth = self.view.frame.size.width - (2 * kMarginX);
    
    UIView *logoView = [self newLogoView];
    UIView *formView = [self newInputFormView];
    
    CGRect frame = formView.frame;
    frame.origin.y = logoView.frame.size.height + marginY;
    formView.frame = frame;
    
    CGFloat height = formView.frame.origin.y + formView.frame.size.height;
    
    _containerView = [[UIView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - contentWidth) / 2,
                                                                 (self.view.frame.size.height - height) / 3,
                                                                 contentWidth,
                                                                 height)];
    
    _containerView.backgroundColor = [UIColor clearColor];
    [_containerView addSubview:logoView];
    [_containerView addSubview:formView];
    
    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.backgroundColor = [UIColor tuGrayColor];
    [_scrollView addSubview:_containerView];
    
    [self.view addSubview:_scrollView];
}

- (UIView*)newLogoView {
    CGFloat marginX = 20.0;
    CGFloat contentWidth = self.view.frame.size.width - (2 * marginX);
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, contentWidth, kLogoHeight)];
    imgView.image = [UIImage imageNamed:@"logo_login"];
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    return imgView;
}

- (UIView*)newInputFormView {
    
    CGFloat contentWidth = self.view.frame.size.width - (2 * kMarginX);
    CGFloat marginY = 30.0;
    CGFloat marginX = 20.0;
    CGFloat padY = 15.0;
    CGFloat runY = marginY;
    CGFloat fieldWidth = contentWidth - (2 * marginX);
    CGFloat fieldHeight = 44.0;
    CGFloat buttonWidth = contentWidth - (4 * marginX);
    CGFloat buttonHeight = 44.0;
    
    // username field
    _usernameField = [[UITextField alloc] initWithFrame:CGRectMake((contentWidth - fieldWidth) / 2, runY, fieldWidth, fieldHeight)];
    _usernameField.delegate = self;
    _usernameField.placeholder = @"Email";
    _usernameField.borderStyle = UITextBorderStyleRoundedRect;
    _usernameField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _usernameField.keyboardType = UIKeyboardTypeEmailAddress;
    _usernameField.autocorrectionType = UITextAutocorrectionTypeNo;
    
    runY += _usernameField.frame.size.height;
    runY += padY;
    
    // password field
    _passwordField = [[UITextField alloc] initWithFrame:CGRectMake((contentWidth - fieldWidth) / 2, runY, fieldWidth, fieldHeight)];
    _passwordField.delegate = self;
    _passwordField.placeholder = @"Password";
    _passwordField.borderStyle = UITextBorderStyleRoundedRect;
    _passwordField.secureTextEntry = YES;
    _passwordField.keyboardType = UIKeyboardTypeASCIICapable;
    _passwordField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _passwordField.autocorrectionType = UITextAutocorrectionTypeNo;

    runY += _passwordField.frame.size.height;
    runY += marginY;

    // button
    _submitButton = [[UIButton alloc] initWithFrame:CGRectMake((contentWidth - buttonWidth) / 2, runY, buttonWidth, buttonHeight)];
    [_submitButton setTitle:[self submitButtonLabelStr] forState:UIControlStateNormal];
    [_submitButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _submitButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    _submitButton.backgroundColor = [UIColor tuLoginButton];
    _submitButton.layer.cornerRadius = 10.0;
    _submitButton.layer.masksToBounds = YES;
    [_submitButton addTarget:self action:@selector(loginHit:) forControlEvents:UIControlEventTouchUpInside];
    
    [self enableSubmitButtonEnabled:NO];
    
    runY += _submitButton.frame.size.height;
    runY += marginY;

    // rule - comment this for now, will add back later
//    UIView *rule = [[UIView alloc] initWithFrame:CGRectMake(0, runY, contentWidth, 1)];
//    rule.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.1];
//    
//    runY += rule.frame.size.height;
    //    runY += marginY; // don't want margin here because button takes up whole space
    
    // forgot password button - comment this for now, will add back later
//    UIButton *forgotButton = [[UIButton alloc] initWithFrame:CGRectMake((contentWidth - buttonWidth) / 2, runY, buttonWidth, buttonHeight)];
//    [forgotButton setTitle:@"Forgot your password?" forState:UIControlStateNormal];
//    [forgotButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    forgotButton.titleLabel.font = [UIFont systemFontOfSize:14.0];
//    [forgotButton addTarget:self action:@selector(forgotPasswordHit:) forControlEvents:UIControlEventTouchUpInside];
//    
//    runY += forgotButton.frame.size.height;
    //    runY += marginY; // don't want margin here because button takes up whole space

    
    
    // form container
    UIView *cont = [[UIView alloc] initWithFrame:CGRectMake(0, 0, contentWidth, runY)];
    cont.backgroundColor = [UIColor whiteColor];
    cont.layer.cornerRadius = 16.0;
    cont.layer.masksToBounds = YES;
    
    [cont addSubview:_usernameField];
    [cont addSubview:_passwordField];
    [cont addSubview:_submitButton];
//    [cont addSubview:rule];
//    [cont addSubview:forgotButton];
    
    return cont;
}

- (NSString*)submitButtonLabelStr {
    return @"Log In";
}

- (void)resetView {
    [self resetViewExceptUsername:NO];
}

- (void)resetViewExceptUsername:(BOOL)exceptUsername {
    
    [_scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    
    [_spinner removeFromSuperview];
    _spinner = nil;
    
    if (!exceptUsername) {
        _usernameField.text = @"";
    }
    _passwordField.text = @"";
    
    _submitButton.enabled = YES;
    [_submitButton setTitle:[self submitButtonLabelStr] forState:UIControlStateNormal];
    
    [self enableSubmitButtonEnabled:NO];
    
//    [_scrollView setContentOffset:CGPointMake(0, 0)];
}

- (void)enableSubmitButtonEnabled:(BOOL)enabled {
    _submitButton.enabled = enabled;
    _submitButton.alpha = enabled ? 1.0 : 0.3;
}

- (void)toggleSubmitButtonActiveUsernameText:(NSString*)usernameText passwordText:(NSString*)passwordText {
    [self enableSubmitButtonEnabled:(usernameText.length > 0 && passwordText.length > 0)];
}

#pragma mark UITextField delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *newString;
    
    if (string.length == 0) {
        newString = [textField.text substringWithRange:NSMakeRange(0, textField.text.length - 1)];
    }
    else {
        newString = [NSString stringWithFormat:@"%@%@", textField.text, string];
    }
    
    if (textField == _usernameField) {
        [self toggleSubmitButtonActiveUsernameText:newString passwordText:_passwordField.text];
    }
    else if (textField == _passwordField) {
        [self toggleSubmitButtonActiveUsernameText:_usernameField.text passwordText:newString];
    }
    
    return YES;
}

@end
