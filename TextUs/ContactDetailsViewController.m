//
//  ContactDetailsViewController.m
//  TextUs
//
//  Created by Josh Bruhin on 11/16/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "ContactDetailsViewController.h"
#import "ChatViewController.h"
#import "AppDelegate.h"
#import "AuthAPIClient.h"
#import "Utils.h"
#import "NewContactViewController.h"

@interface ContactDetailsViewController ()

@end

@implementation ContactDetailsViewController

@synthesize contact;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupNavbar];
    
    BOOL busy = NO;
    if (!self.contact.isIdOnly) {
        [self getOptOutRecord];
        [self populateView];
    }
    else {
        [self getUserObject];
        busy = YES;
    }
    
    [self setupViewBusy:busy];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupNavbar {
    self.title = @"";
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editHit:)];
    self.navigationItem.rightBarButtonItem = button;
}

- (void)setupViewBusy:(BOOL)busy {
    
    for (UIView *subView in self.view.subviews) {
        if (subView != _spinner) {
            subView.hidden = busy;
        }
    }
    
    if (busy) {
        [_spinner startAnimating];
    }
    else {
        [_spinner stopAnimating];
    }
}

- (BOOL)optedOut {
    return _optedOut;
}
- (void)setOptedOut:(BOOL)optedOut {
    _optedOut = optedOut;
    [_optInSwitch setOn:optedOut animated:YES];
    
    if (!optedOut) {
        _optOutId = nil;
    }
}

#pragma mark Actions

- (IBAction)optOutSwitchHit:(id)sender {
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        [_optInSwitch setOn:!_optInSwitch.isOn animated:YES];
        return;
    }

    if (_optedOut && _optOutId && _optOutId.length > 0) {
        // we're destroying the opt out for this user
        
        NSString *urlStr = [NSString stringWithFormat:@"opt_outs/%@", _optOutId];
        id params = @{@"id":_optOutId};
        
        [[AuthAPIClient sharedClient] DELETE:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
            NSLog(@"ResponseObject: %@", responseObject);
            
            self.optedOut = NO;
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Error: %@", error);
            
            [Utils handleGeneralError:error fromViewController:self];
            [_optInSwitch setOn:!_optInSwitch.isOn animated:YES];

        }];

    }
    else {
        // we're creating the opt out
        
        NSString *urlStr = @"opt_outs";
        id params = @{@"phone":self.contact.phone};
        
        [[AuthAPIClient sharedClient] POST:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
            NSLog(@"ResponseObject: %@", responseObject);
            
            _optOutId = [Utils checkObjectForNull:[[(NSDictionary*)responseObject objectForKey:@"id"] stringValue]];
            self.optedOut = YES;

        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Error: %@", error);
            [Utils handleGeneralError:error fromViewController:self];
            [_optInSwitch setOn:!_optInSwitch.isOn animated:YES];
        }];

    }
    
}


- (IBAction)cancelHit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editHit:(id)sender {
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }

    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController *nc = [sb instantiateViewControllerWithIdentifier:@"NewContactNavigationController"];
    NewContactViewController *vc = [nc.viewControllers objectAtIndex:0];
    vc.contactToEdit = self.contact;
    vc.delegate = self;
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelHit:)];
    vc.navigationItem.leftBarButtonItem = button;
    
    [self presentViewController:nc animated:YES completion:nil];
}

- (IBAction)deleteHit:(id)sender {
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:@"The contact will be permanently deleted." preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete contact" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {

        NSString *urlStr = [NSString stringWithFormat:@"contacts/%@", self.contact.idStr];
        id params = @{@"id":self.contact.idStr};
        
        [[AuthAPIClient sharedClient] DELETE:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
            NSLog(@"ResponseObject: %@", responseObject);
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(ContactDetailsViewController:deletedContact:)]) {
                [self.delegate ContactDetailsViewController:self deletedContact:self.contact];
            }
            
            [self.navigationController popViewControllerAnimated:YES];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Error: %@", error);
            [Utils handleGeneralError:error fromViewController:self];
        }];

    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //
    }];
    
    [alert addAction:delete];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction)messageHit:(id)sender {
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ChatViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ChatViewController"];
    
    vc.senderId = appDelegate.currentUser.idStr;
    vc.senderDisplayName = [NSString stringWithFormat:@"%@ %@", appDelegate.currentUser.firstName, appDelegate.currentUser.lastName];
    
    vc.contact = self.contact;
    vc.contactDisplayName = [NSString stringWithFormat:@"%@ %@", self.contact.firstName, self.contact.lastName];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)callHit:(id)sender {
    
    NSURL *phoneUrl = [NSURL URLWithString:[NSString  stringWithFormat:@"telprompt:%@",self.contact.phone]];
    
    if ([[UIApplication sharedApplication] canOpenURL:phoneUrl]) {
        [[UIApplication sharedApplication] openURL:phoneUrl];
    }
    else {
        [Utils showAlertWithTitle:@"Unable to call from this device" message:nil fromViewController:self];
    }
}

#pragma mark Setup View

- (void)populateView {
    
    [self setupNameLabel];
    
    _phoneLabel.text = self.contact.phone;
    _businessNameLabel.text = self.contact.businessName;
}

- (void)setupNameLabel {
    
    NSString *combStr = [NSString stringWithFormat:@"%@ %@", self.contact.firstName, self.contact.lastName];
    
    
    UIFont *unBoldedFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:24];
    NSRange unBoldedRange = [combStr rangeOfString:[NSString stringWithFormat:@"%@", self.contact.firstName]];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:combStr attributes:@{NSFontAttributeName: _nameLabel.font}];
    
    [attrString beginEditing];
    [attrString addAttribute:NSFontAttributeName
                       value:unBoldedFont
                       range:unBoldedRange];
    
    [attrString endEditing];
    
    _nameLabel.attributedText = attrString;

}

#pragma mark Data Request

- (void)getUserObject {
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }

    
    NSString *urlStr = [NSString stringWithFormat:@"contacts/%@", self.contact.idStr];
    id params = @{@"id":self.contact.idStr};
    
    [[AuthAPIClient sharedClient] GET:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"ResponseObject: %@", responseObject);
        
        if (responseObject && ((NSArray*)responseObject).count > 0) {
            NSArray *contacts = [Utils processContactsResponse:@[responseObject]];
            self.contact = [contacts objectAtIndex:0];
            [self getOptOutRecord];
            [self populateView];
            [self setupViewBusy:NO];
            
            CATransition *animation = [CATransition animation];
            animation.duration = 0.15f;
            animation.type = kCATransitionFade;
            [self.view.layer addAnimation: animation forKey: @"editingFade"];
            [self.view setNeedsDisplay];

        }
        else {
            [Utils showAlertWithTitle:@"An error occurred" message:@"The contact was not found" fromViewController:self];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        [Utils handleGeneralError:error fromViewController:self];
    }];
}

- (void)getOptOutRecord {
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }

    NSString *urlStr = @"opt_outs";
    id params = @{@"q":self.contact.phone};
    
    [[AuthAPIClient sharedClient] GET:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"ResponseObject: %@", responseObject);
        
        if (responseObject && ((NSArray*)responseObject).count > 0) {
            
            NSDictionary *dict = [((NSArray*)responseObject) objectAtIndex:0];
           _optOutId = [Utils checkObjectForNull:[[dict objectForKey:@"id"] stringValue]];
            self.optedOut = YES;
        }
        
        _optInSwitch.enabled = YES;
        
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        // not alerting user in this case because this happens in the background without their knowledge
    }];

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark NewContactVC delegate

- (void)NewContactViewController:(NewContactViewController *)controller editedContact:(TUContact *)editedContact {
    
    [self dismissViewControllerAnimated:YES completion:^{
        [Utils showAlertWithTitle:@"Contact updated" message:nil fromViewController:self];
    }];
    
    self.contact = editedContact;
    [self populateView];
}


@end
