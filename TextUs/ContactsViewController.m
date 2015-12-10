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

@interface ContactsViewController ()

@end

@implementation ContactsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupInstructions];
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
    
    [self performSegueWithIdentifier:@"SegueShowNewContact" sender:self];
}

- (void)showDetailsForContact:(TUContact*)contact {
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    ContactDetailsViewController *vc = [sb instantiateViewControllerWithIdentifier:@"ContactDetailsViewController"];
    vc.contact = contact;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:YES];
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
    
    // Segregate the CNContact person into the appropriate arrays.
    NSInteger numberRecords = [contacts count];
    for (NSInteger i = 0; i < numberRecords; i++) {
        
        TUContact *contact = [contacts objectAtIndex:i];
        NSString *name = contact.firstName;
        
        // Ask the collation which section number the name belongs in, based on its lowercase.
        NSInteger sectionNumber = [_collation sectionForObject:name collationStringSelector:@selector(lowercaseString)];
        
        
        // Get the array for the section.
        NSMutableArray *sectionAlphabeticallyArray = [newSectionsArray objectAtIndex:sectionNumber];
        
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
    return _contactsArray.count > 20;
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
    NSString *combStr = [NSString stringWithFormat:@"%@ %@", contact.firstName, contact.lastName];
    
    
    UIFont *unBoldedFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
    NSRange unBoldedRange = [combStr rangeOfString:[NSString stringWithFormat:@"%@", contact.lastName]];
    
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
