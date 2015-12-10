//
//  MainViewController.m
//  TextUs
//
//  Created by Josh Bruhin on 11/17/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@end

@implementation MainViewController

@synthesize siblingVC;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupNetworkObservers];
    
    self.isSearching = NO;
    _searchPageCount = 1;
    
    _task = nil;
    [self setupView];
    [self requestData];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (![Utils connected]) {
        [self setupNoNetwork];
    }
}

- (void)setupNetworkObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupNoNetwork)
                                                 name:@"NetworkLost" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setupNetworkRestored)
                                                 name:@"NetworkRestored" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)requestData {
    // subclass
}

#pragma mark Actions

- (IBAction)gotoSiblingHit:(id)sender {
    
    if (!self.siblingVC) {
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        self.siblingVC = [sb instantiateViewControllerWithIdentifier:[self siblingVCIdentifierStr]];
        self.siblingVC.siblingVC = self;
    }
    
    [self.navigationController setViewControllers:@[self.siblingVC]];
}

- (NSString*)siblingVCIdentifierStr {
    // subclass
    return @"";
}

#pragma mark ViewSetup

- (void)setupView {
    
    [_tableView registerNib:[UINib nibWithNibName:@"MessagesTableViewCell" bundle:nil] forCellReuseIdentifier:@"MessagesTableViewCell"];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupTableView];
    [self setupSearch];
    [self setupNavBar];
}

- (void)setupNavBar {
    // subclass
}

- (void)setupSearch {
    
    // NOT USING STANDARD SEARCH AFTER ALL. ROLL OUR OWN BELOW
    
    //    // There's no transition in our storyboard to our search results tableview or navigation controller
    //    // so we'll have to grab it using the instantiateViewControllerWithIdentifier: method
    //    UINavigationController *searchResultsController = [[self storyboard] instantiateViewControllerWithIdentifier:@"SearchResultsNavigationController"];
    //
    //    _searchController = [[UISearchController alloc] initWithSearchResultsController:searchResultsController];
    //    _searchController.searchResultsUpdater = self;
    //
    //    // The searchBar contained in XCode's storyboard is a leftover from UISearchDisplayController.
    //    // Don't use this. Instead, we'll create the searchBar programatically.
    //    _searchController.searchBar.frame = CGRectMake(_searchController.searchBar.frame.origin.x,
    //                                                       _searchController.searchBar.frame.origin.y,
    //                                                       _searchController.searchBar.frame.size.width, 44.0);
    //    _searchController.searchBar.delegate = self;
    //    _searchController.hidesNavigationBarDuringPresentation = NO;
    //
    //    _tableView.tableHeaderView = _searchController.searchBar;
    //
    
    _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, _tableView.frame.size.width, 44)];
    _searchBar.delegate = self;
    _searchBar.showsCancelButton = NO;
    //    _searchBar.barTintColor = [UIColor tuGrayColor];
    _searchBar.backgroundColor = [UIColor tuGrayColor];
    _searchBar.backgroundImage = [[UIImage alloc] init];
    _searchBar.placeholder = @"Search";
    [_tableView setTableHeaderView:_searchBar];
}

- (void)setupTableView {
    
    //    _tableView.contentInset = UIEdgeInsetsMake(_tabsContainer.frame.origin.y + _tabsContainer.frame.size.height, 0, 0, 0);
    
    _tableView.backgroundColor = [UIColor clearColor];
    [self setupTableFooter];
}

- (void)setupTableFooter {
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _tableView.frame.size.width, 50)];
    footer.backgroundColor = [UIColor clearColor];
    
    if (_searchingMore) {
        _spinnerFooter = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _spinnerFooter.hidesWhenStopped = YES;
        _spinnerFooter.center = footer.center;
        [_spinnerFooter startAnimating];
        [footer addSubview:_spinnerFooter];
    }
    
    [_tableView setTableFooterView:footer];
}


- (void)setIsSearching:(BOOL)isSearching {
    
    _isSearching = isSearching;
    
    if (!isSearching) {
        [self clearSearchResults];
        [_spinner stopAnimating];
        _noResultsLabel.hidden = YES;
        _instructionsView.hidden = NO;
    }
    
    [_tableView reloadData];
    
    CATransition *animation = [CATransition animation];
    animation.duration = 0.15f;
    animation.type = kCATransitionFade;
    [_tableView.layer addAnimation: animation forKey: @"editingFade"];
    [_tableView setNeedsDisplay];
    
}
- (BOOL)isSearching {
    return _isSearching;
}


- (void)setupNoNetwork {
    
    _noNetwork = YES;
    
    _noResultsLabel.text = @"NO NETWORK CONNECTION";
    _instructionsView.hidden = YES;
    _noResultsLabel.hidden = NO;
    
    _tableView.userInteractionEnabled = NO;
    [_tableView reloadData];
}

- (void)setupNetworkRestored {
    
    // this can get called even when we did not previously have no network, so we check
    if (_noNetwork) {
        
        _noNetwork = NO;
        
        _noResultsLabel.text = @"NO RESULTS";
        _noResultsLabel.hidden = YES; // since we're requesting data
        
        _instructionsView.hidden = _searchDataArray.count > 0 ? YES : NO;
        //    _noResultsLabel.hidden = _searchDataArray.count > 0 ? YES : NO;
        
        _tableView.userInteractionEnabled = YES;
        [_tableView reloadData];
        
        [self requestData];
    }
    
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark Data Processing

- (void)processSearchResonse:(id)responseObj {
    // subclass
}

- (NSString*)searchUrlStr {
    // subclass
    return @"";
}

- (id)searchParamsWithSearchStr:(NSString*)searchStr {
    // subclass
    return nil;
}

- (void)clearSearchResults {
    _searchDataArray = nil;
    _noMoreData = YES;
}

- (void)searchForString:(NSString*)searchString {
    
    if ([Utils notConnectedShowAlert:YES fromVC:self]) {
        return;
    }
    
    NSString *urlStr = [self searchUrlStr];
    id params = [self searchParamsWithSearchStr:searchString];
    
    if (_task) {
        [_task cancel];
    }
    
    if (_searchingMore) {
        [self setupTableFooter];
    }
    else {
        [_spinner startAnimating];
    }
    
    _noResultsLabel.hidden = YES;
    _instructionsView.hidden = YES;
    
    _task = [[AuthAPIClient sharedClient] GET:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        
        //            NSLog(@"ResponseObject: %@", responseObject);
        NSLog(@"searched");
        
        _noMoreData = NO;
        _searchingMore = NO;
        
        [_spinner stopAnimating];
        [_spinnerFooter stopAnimating];
        
        if (((NSArray*)responseObject).count == 0 || !responseObject) {
            
            // so we won't load more upon scrolling
            _noMoreData = YES;
            
            if (_searchDataArray.count == 0) {
                _noResultsLabel.hidden = NO;
            }
        }
        else {
            [self processSearchResonse:responseObject];
            [_tableView reloadData];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (error.code != -999) { // cancelled
            _searchingMore = NO;
            [_spinner stopAnimating];
            [_spinnerFooter stopAnimating];
            NSLog(@"Error: %@", error);
            [Utils handleGeneralError:error fromViewController:self];
        }
    }];
}


#pragma mark UIScrollView delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (_isSearching) {
        [_searchBar resignFirstResponder];
    }
    
    if ((self.isSearching && _searchDataArray.count == 0) || (!self.isSearching && _defaultDataArray.count == 0)) {
        [scrollView setContentOffset:CGPointMake(0, 0)];
    }
    
    if (!_noMoreData && !_searchingMore) {
        [self checkToGetMorePosts];
    }
}

- (void)checkToGetMorePosts {
    
    CGFloat distanceFromBottom = _tableView.contentOffset.y - _tableView.contentSize.height + _tableView.frame.size.height;
    
    if (distanceFromBottom < 0.0f) {
        distanceFromBottom *= -1;
    }
    
    if (!_searchingMore && distanceFromBottom <= 100.0f) {
        _searchingMore = YES;
        _searchPageCount ++;
        [self searchForString:_searchBar.text];
    }
}

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor whiteColor];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // subclass
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (![Utils connected]) {
        return 0;
    }
    return _isSearching ? _searchDataArray.count : _defaultDataArray.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // subcalss
    return @"";
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    // subclass
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    // subclass
    return 0;
}
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    // subclass
    return 0;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // subclass
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // subclass
    return 0;
}

#pragma mark - UISearchBarDelegate & UISearchResultsDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.isSearching = YES;
    _searchBar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    self.isSearching = NO;
    
    _searchBar.showsCancelButton = NO;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    NSString *searchString = searchBar.text;
    
    [self clearSearchResults];

    if (searchString && searchString.length > 2) {
        _searchPageCount = 1;
        [self searchForString:searchString];
    }
    else {
        _noResultsLabel.hidden = searchString.length == 0;
        _instructionsView.hidden = searchString.length > 0;
        [_tableView reloadData];
    }
}

// Called when the search bar becomes first responder
//- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
//{
//
//    // Set searchString equal to what's typed into the searchbar
//    NSString *searchString = _searchController.searchBar.text;
//
//    if (searchString && searchString.length > 2) {
//
//        NSString *urlStr = @"messages";
//        id params = @{@"page":@"1", @"per_page":@"25", @"q":searchString};
//
//        [[AuthAPIClient sharedClient] GET:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
//            NSLog(@"ResponseObject: %@", responseObject);
//
//            _messages = [self processMessagesResponse:responseObject];
//
//            if (_searchController.searchResultsController) {
//
//                UINavigationController *navController = (UINavigationController *)_searchController.searchResultsController;
//                SearchResultsTableViewController *vc = (SearchResultsTableViewController *)navController.topViewController;
//                vc.searchResults = [NSMutableArray arrayWithArray:_messages];
//                [vc.tableView reloadData];
//            }
//
//
//        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//            NSLog(@"Error: %@", error);
//        }];    
//        
//        
//    }
//}


@end
