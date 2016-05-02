//
//  MessageTemplatesTableViewController.m
//  TextUs
//
//  Created by Josh Bruhin on 4/15/16.
//  Copyright © 2016 TextUs. All rights reserved.
//

#import "MessageTemplatesTableViewController.h"
#import "TUMessageTemplate.h"
#import "MessageTemplateTableViewCell.h"
#import "AuthAPIClient.h"
#import "Utils.h"

@interface MessageTemplatesTableViewController ()

@end

@implementation MessageTemplatesTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"MessageTemplateTableViewCell" bundle:nil] forCellReuseIdentifier:@"MessageTemplateTableViewCell"];
    [self initTemplateCell];
    [self setupTableFooter];
    [self setupNavBar];
    [self showSpinnerVisible:YES];
    
    // add a little inset to the top of the table
    [self.tableView setContentInset:UIEdgeInsetsMake(10.0, 0.0, 0.0, 0.0)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self requestData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showSpinnerVisible:(BOOL)visible {
    
    if (_spinner) {
        [_spinner stopAnimating];
        [_spinner removeFromSuperview];
        _spinner = nil;
    }
    
    if (visible) {
        _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _spinner.center = CGPointMake(self.view.center.x, self.view.center.y / 2);
        [_spinner startAnimating];
        [self.view addSubview:_spinner];
    }
}

- (void)setupTableFooter {
    // so it doesn't show blank rows
    UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
    footer.backgroundColor = [UIColor clearColor];
    [self.tableView setTableFooterView:footer];
}

- (void)setupNavBar {
    
    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonHit:)];
    self.navigationItem.rightBarButtonItem = button;
    
    self.navigationItem.title = @"Message Templates";
}

- (void)doneButtonHit:(id)sender {
    [self finishedWithTemplate:nil];
}

- (void) initTemplateCell { // to get heightForRow
    
    NSArray *topLevel = [[NSBundle mainBundle] loadNibNamed:@"MessageTemplateTableViewCell" owner:self options:nil];
    for (id currentObject in topLevel){
        if ([currentObject isKindOfClass:[MessageTemplateTableViewCell class]]){
            _templateCell = (MessageTemplateTableViewCell *)currentObject;
            break;
        }
    }
}

- (void)requestData {
    
    if (![Utils connected]) {
        return;
    }
    
    if (_requestingData) {
        return;
    }
    
    _requestingData = YES;
    
    
//    [_spinner startAnimating];
    
    NSString *urlStr = @"message_templates";
    id params = @{@"page":@"1", @"per_page":@"25"};
    
    [[AuthAPIClient sharedClient] GET:urlStr parameters:params success:^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
        NSLog(@"ResponseObject: %@", responseObject);
        [self processResonse:responseObject];
        [self showSpinnerVisible:NO];
        
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        _requestingData = NO;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error: %@", error);
        [Utils handleGeneralError:error fromViewController:self];
        [self showSpinnerVisible:NO];
        _requestingData = NO;
    }];
    
}

- (void)processResonse:(id)responseObj {
    
    NSArray *messages = [Utils processMessagesTemplateResponse:(NSArray*)responseObj];
    
    if (!_dataArray) {
        _dataArray = [[NSMutableArray alloc] initWithCapacity:100];
    }
    
    [_dataArray addObjectsFromArray:messages];
}


- (TUMessageTemplate*)templateForIndexPath:(NSIndexPath*)indexPath {
    if (_dataArray && _dataArray.count > indexPath.row) {
        return [_dataArray objectAtIndex:indexPath.row];
    }
    return nil;
}

- (void)finishedWithTemplate:(TUMessageTemplate*)template {
    if (self.delegate && [self.delegate respondsToSelector:@selector(MessageTemplatesTableViewController:doneWithTemplate:)]) {
        [self.delegate MessageTemplatesTableViewController:self doneWithTemplate:template];
    }
}


#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor clearColor];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count;;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    MessageTemplateTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MessageTemplateTableViewCell" forIndexPath:indexPath];
    TUMessageTemplate *template = [self templateForIndexPath:indexPath];
    cell.titleLabel.text = template.title;
    cell.messageLabel.text = template.content;
        
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_templateCell heightForCellForTemplate:[self templateForIndexPath:indexPath]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self finishedWithTemplate:[self templateForIndexPath:indexPath]];
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
