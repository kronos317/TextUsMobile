//
//  MainViewController.h
//  TextUs
//
//  Created by Josh Bruhin on 11/17/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIColor+TU.h"
#import "Utils.h"
#import "AuthAPIClient.h"
#import <QuartzCore/QuartzCore.h>

@interface MainViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIScrollViewDelegate> {
    
    __weak IBOutlet UIView *_tabsContainer;
    __weak IBOutlet UITableView *_tableView;
    __weak IBOutlet UIActivityIndicatorView *_spinner;
    __strong IBOutlet UIActivityIndicatorView *_spinnerFooter;
    __weak IBOutlet UILabel *_noResultsLabel;
    //    __strong UISearchController *_searchController;
    __strong NSArray *_defaultDataArray;
    __strong NSMutableArray *_searchDataArray;
    __strong UISearchBar *_searchBar;
    BOOL _isSearching;
    
    __weak IBOutlet UILabel *_instructionsView;

    NSURLSessionDataTask *_task;
    
    BOOL _searchingMore; // if they've scrolled to bottom, trigger another search
    BOOL _noMoreData;
    BOOL _initialDataLoaded;
    BOOL _noNetwork;
    
    NSInteger _searchPageCount;
}

@property (assign) BOOL isSearching;
@property (nonatomic, strong)   MainViewController *siblingVC;

- (void)requestData;
- (void)setupNavBar;
- (NSString*)searchUrlStr;
- (id)searchParamsWithSearchStr:(NSString*)searchStr;
- (void)processSearchResonse:(id)responseObj;
- (IBAction)gotoSiblingHit:(id)sender;
- (NSString*)siblingVCIdentifierStr;
- (void)clearSearchResults;

#pragma mark UITableView delegate
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;
- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index;
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
