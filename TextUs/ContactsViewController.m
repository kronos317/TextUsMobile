//
//  ContactsViewController.m
//  TextUs
//
//  Created by Josh Bruhin on 11/12/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "ContactsViewController.h"
#import "Utils.h"
#import "UIColor+TU.h"
#import "TUContact.h"
#import "ContactDetailsViewController.h"
#import "AddContactsViewController.h"

static const NSString *kPhoneNumberLabelKey = @"label";
static const NSString *kPhoneNumberNumberKey = @"number";

@interface ContactsViewController ()

@end

@implementation ContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupInstructions];
    _contactToImport = nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UINavigationController *nc = segue.destinationViewController;
    NewContactViewController *vc = (NewContactViewController*)[nc.viewControllers objectAtIndex:0];
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissHit:)];
    vc.navigationItem.leftBarButtonItem = cancel;
    vc.contactToEdit = nil; // need to initialize this
    vc.delegate = self;
}

- (NSString*)siblingVCIdentifierStr {
    return @"MessagesViewController";
}

#pragma Data processing

- (NSString*)searchUrlStr {
    return @"contacts";
}

- (id)searchParamsWithSearchStr:(NSString*)searchStr {
    return @{@"page":[NSNumber numberWithInteger:_searchPageCount], @"per_page":@"25", @"q":searchStr};
}

- (void)requestData {
    // nothing
}

- (void)clearSearchResults {
    [super clearSearchResults];
    _contactsArray = nil;
}

- (void)processSearchResonse:(id)responseObj {
    
    NSArray *contacts = [self processContactsResponse:(NSArray*)responseObj];
    
    if (!_contactsArray) {
        _contactsArray = [[NSMutableArray alloc] initWithCapacity:100];
    }
    
    [_contactsArray addObjectsFromArray:contacts];

    _searchDataArray = [[NSMutableArray alloc] initWithArray:[self sectionsArrayWithContacts:_contactsArray]];
}

- (NSArray*)processContactsResponse:(NSArray*)responseArray {
    
    return [Utils processContactsResponse:responseArray];
}

#pragma mark Actions

- (IBAction)dismissHit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addContactsHit:(UIBarButtonItem*)sender {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *import = [UIAlertAction actionWithTitle:@"Import contact" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showImportContact];
    }];
    
    UIAlertAction *addNew = [UIAlertAction actionWithTitle:@"Add new contact" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self performSegueWithIdentifier:@"SegueShowNewContact" sender:self];
    }];

    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //
    }];
    
    [alert addAction:import];
    [alert addAction:addNew];
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showDetailsForContact:(TUContact*)contact {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ContactDetailsViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ContactDetailsViewController"];
    vc.contact = contact;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showImportContact {

    CNContactPickerViewController *contactPicker = [[CNContactPickerViewController alloc] init];
    contactPicker.delegate = self;
    [self presentViewController:contactPicker animated:YES completion:nil];
    
}

#pragma mark View Setup

- (void)setupNavBar {
    
    self.title = @"All Contacts";
        
    self.navigationItem.titleView = [Utils navBarTitleView];
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addContactsHit:)];
    self.navigationItem.rightBarButtonItem = button;
}

- (void)setupInstructions {
    _instructionsView.layer.cornerRadius = 8.0;
    _instructionsView.layer.masksToBounds = YES;
    _instructionsView.backgroundColor = [UIColor tuGrayColor];
}

#pragma mark Model

- (NSArray*)sectionsArrayWithContacts:(NSArray*)contacts {
    
    // Get the current collation and keep a reference to it.
    _collation = [UILocalizedIndexedCollation currentCollation];
    
    //NSCharacterSet
    NSInteger index, sectionTitlesCount = [[_collation sectionTitles] count];
    
    NSMutableArray *newSectionsArray = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    
    // Set up the sections array: elements are mutable arrays that will contain the alphabetically for that section.
    
    for (index = 0; index < sectionTitlesCount; index++) {
        NSMutableArray *array = [[NSMutableArray alloc] init];
        [newSectionsArray addObject:array];
    }
    
    _sectionsWithDataCount = 0;
    
    // Segregate the CNContact person into the appropriate arrays.
    NSInteger numberRecords = [contacts count];
    for (NSInteger i = 0; i < numberRecords; i++) {
        
        TUContact *contact = [contacts objectAtIndex:i];
        NSString *name = contact.firstName;
        
        // Ask the collation which section number the name belongs in, based on its lowercase.
        NSInteger sectionNumber = [_collation sectionForObject:name collationStringSelector:@selector(lowercaseString)];
        
        
        // Get the array for the section.
        NSMutableArray *sectionAlphabeticallyArray = [newSectionsArray objectAtIndex:sectionNumber];
        
        // if the section array has no data, we increment our sections with data count
        if (sectionAlphabeticallyArray.count == 0) {
            _sectionsWithDataCount ++;
        }
        
        //  Add the person to the section.
        [sectionAlphabeticallyArray addObject:(NSObject *)contact];
    }
    
    return newSectionsArray;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (BOOL)showSectionIndex {
    return _contactsArray.count > 20 && _sectionsWithDataCount > 2;
}

#pragma mark Contact Importing

- (NSString*)cleanedLabelString:(NSString*)origStr {
    NSMutableString *mStr = [NSMutableString stringWithString:origStr];
    [mStr replaceOccurrencesOfString:@">!$_" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, mStr.length)];
    [mStr replaceOccurrencesOfString:@"_$!<" withString:@"" options:NSLiteralSearch range:NSMakeRange(0, mStr.length)];
    
    return [NSString stringWithString:mStr];
}

- (void)handleImportContact:(CNContact*)contact {
    
    
    _contactToImport = [[TUContact alloc] init];
    _contactToImport.firstName = contact.givenName;
    _contactToImport.lastName = contact.familyName;
    _contactToImport.businessName = contact.organizationName;
        
    NSArray <CNLabeledValue<CNPhoneNumber *> *> *phoneNumbers = contact.phoneNumbers;
    
    // if they have more than one number, need to ask them which one to use. otherwise
    // use the one we have. Add the phone number to our saved contact after they choose
    // if they have no phone numbers, show an alert saying so
    // if they have only one *mobile* number, use it and save
    
    if (phoneNumbers.count == 0) {
        [self showNoNumbersAlert];
    }
    else if (phoneNumbers.count > 1) {

        NSMutableArray *numbers = [[NSMutableArray alloc] initWithCapacity:phoneNumbers.count];
        
        NSString *mobileNumber = nil;
        BOOL multipleMobileFound = NO;
        
        for (CNLabeledValue<CNPhoneNumber *> *numberObj in phoneNumbers) {
            
            
            if ([numberObj.label isEqualToString:CNLabelPhoneNumberMobile]) {
                
                if (mobileNumber) {
                    multipleMobileFound = YES;
                }
                else {
                    mobileNumber = numberObj.value.stringValue;
                }
            }
            
            
            CNPhoneNumber *number = numberObj.value;
            NSString *digits = number.stringValue; // 1234567890
            
            // the label property is a string with the correct label, but the label string is bracketed
            // by "_$!<" and ">!$_" - haven't been able to find anything about removing these, so doing it manually for now
            
            NSString *labelStr = [self cleanedLabelString:numberObj.label];
            
            //        NSString *label = numberObj.label; // Mobile
            
            [numbers addObject:@{kPhoneNumberLabelKey:labelStr, kPhoneNumberNumberKey:digits}];
        }
        
        if (multipleMobileFound || !mobileNumber) {
            // delay to allow picker time to dismiss
            [self performSelector:@selector(askUserToPickNumberFromNumbers:) withObject:[NSArray arrayWithArray:numbers] afterDelay:0.5];
        }
        else {
            // found just one mobile number, so go with it
            _contactToImport.phone = mobileNumber;
            [self saveContactToImport];
        }

    }
    else {
        // just save the contact
        CNLabeledValue<CNPhoneNumber *> *numberObj = [contact.phoneNumbers firstObject];
        CNPhoneNumber *number = numberObj.value;
        NSString *digits = number.stringValue; // 1234567890
        _contactToImport.phone = digits;
        
        [self saveContactToImport];
    }
}


- (void)showNoNumbersAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"This contact has no phone numbers." message:nil preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okay = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:okay];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)askUserToPickNumberFromNumbers:(NSArray*)numbers {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Use which number?" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (NSDictionary *dict in numbers) {
        
        NSString *labelStr = [NSString stringWithFormat:@"%@: %@", [dict objectForKey:kPhoneNumberLabelKey], [dict objectForKey:kPhoneNumberNumberKey]];
        
        __strong __block NSDictionary *__dict = dict;
        UIAlertAction *choice = [UIAlertAction actionWithTitle:labelStr style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            // update our selected contact then save it
            _contactToImport.phone = __dict[kPhoneNumberNumberKey];
            [self saveContactToImport];
        }];
        
        [alert addAction:choice];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //
    }];
    
    [alert addAction:cancel];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)saveContactToImport {
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }
    
    // first, query server for the selected contact phone number. if it exists, show error to user
    
    // need to clean the phone string to remove all but numbers, then add a "1" to the front
    
    NSString *origString = _contactToImport.phone;
    NSString *newString = [[origString componentsSeparatedByCharactersInSet:
                            [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
                           componentsJoinedByString:@""];

    // only add the "1" if it's not already there
    NSString *firstChar = [newString substringToIndex:1];
    if (![firstChar isEqualToString:@"1"]) {
        newString = [NSString stringWithFormat:@"1%@", newString];
    }
    
    // if the new number string length does not equal 11 (10 digit number with "1" country code)
    // then alert the user and return
    if (newString.length != 11) {
        [Utils showAlertWithTitle:@"Phone number must be 10 digits" message:nil fromViewController:self];
        return;
    }

    NSString *urlStr = @"contacts";
    id params = @{@"q":newString};
    
    [[AuthAPIClient sharedClient] GET:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"ResponseObject: %@", responseObject);
        
        
        // iterate the contacts from the response and see if this phone number exists
        
        BOOL exists = NO;
        if (responseObject && [responseObject isKindOfClass:[NSArray class]] && ((NSArray*)responseObject).count > 0) {
            NSArray *contacts = [Utils processContactsResponse:responseObject];
            for (TUContact *contact in contacts) {
                if ([contact.phone isEqualToString:newString]) {
                    exists = YES;
                    break;
                }
            }
        }
        
        if (!exists) {
            
            // contact does not exist, so go ahead and post it to server
            NSString *urlStr = @"contacts";
            id params = @{@"phone":_contactToImport.phone, @"first_name":_contactToImport.firstName, @"last_name":_contactToImport.lastName, @"business_name":_contactToImport.businessName};
            
            [[AuthAPIClient sharedClient] POST:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
                NSLog(@"ResponseObject: %@", responseObject);
                
                [Utils showAlertWithTitle:@"Contact Imported" message:nil fromViewController:self];
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"Error: %@", error);
                
                [Utils handleGeneralError:error fromViewController:self];
            }];
        }
        else {
            // contact exists, tell user
            [Utils showAlertWithTitle:@"Contact already exists" message:nil fromViewController:self];
        }

        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        
        [Utils handleGeneralError:error fromViewController:self];
    }];
}


#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *sectionArray = [_searchDataArray objectAtIndex:indexPath.section];
    TUContact *contact = [sectionArray objectAtIndex:indexPath.row];

    [self showDetailsForContact:contact];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    NSArray *sectionArray = [_searchDataArray objectAtIndex:indexPath.section];
    TUContact *contact = [sectionArray objectAtIndex:indexPath.row];
    
    
    NSString *first = contact.firstName ? contact.firstName : @"";
    NSString *second = contact.lastName ? contact.lastName : @"";

    
    NSString *combStr = [NSString stringWithFormat:@"%@ %@", first, second];
    
    
    UIFont *unBoldedFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    NSRange unBoldedRange = [combStr rangeOfString:[NSString stringWithFormat:@"%@", second]];
    
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:combStr attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:18]}];
    
    [attrString beginEditing];
    [attrString addAttribute:NSFontAttributeName
                       value:unBoldedFont
                       range:unBoldedRange];
    
    [attrString endEditing];
    
    cell.textLabel.attributedText = attrString;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    if (![Utils connected]) {
        return 0;
    }
    
    NSArray *sectionArray = [_searchDataArray objectAtIndex:section];
    return sectionArray.count;   // number of letters usually 26
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _searchDataArray.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self showSectionIndex] ? [[_collation sectionTitles] objectAtIndex:section] : nil;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self showSectionIndex] ? [_collation sectionIndexTitles] : nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self showSectionIndex] ? [_collation sectionForSectionIndexTitleAtIndex:index] : 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self showSectionIndex] ? 20 : 0;
}

#pragma mark CNContactPickerViewController delegate

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact {
    [self handleImportContact:contact];
}

#pragma mark ContactDetailsVC delegate

- (void)NewContactViewController:(NewContactViewController *)controller createdContact:(TUContact *)createdContact {
    
    [self dismissViewControllerAnimated:YES completion:^{
        [Utils showAlertWithTitle:@"Contact created" message:nil fromViewController:self];
    }];
}

- (void)NewContactViewController:(NewContactViewController *)controller editedContact:(TUContact *)editedContact {
    
    [self dismissViewControllerAnimated:YES completion:^{
        [Utils showAlertWithTitle:@"Contact saved" message:nil fromViewController:self];
    }];
}

#pragma mark ContactDetailsVC delegate

- (void)ContactDetailsViewController:(ContactDetailsViewController *)controller deletedContact:(TUContact *)contact {
    
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:_contactsArray.count];
    for (TUContact *eContact in _contactsArray) {
        if (![eContact.idStr isEqualToString:contact.idStr]) {
            [mArray addObject:eContact];
        }
    }
    
    _contactsArray = [NSMutableArray arrayWithArray:mArray];
    _searchDataArray = [NSMutableArray arrayWithArray:[self sectionsArrayWithContacts:_contactsArray]];
    
    [_tableView reloadData];
    
    if (_contactsArray.count == 0) {
        _noResultsLabel.hidden = NO;
    }
}

@end
