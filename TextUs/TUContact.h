//
//  TUContact.h
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kContactFirstNameKey = @"first_name";
static NSString *kContactLastNameKey = @"last_name";
static NSString *kContactBusinessNameKey = @"business_name";
static NSString *kContactPhoneKey = @"phone";
static NSString *kContactCountryKey = @"country";
static NSString *kContactIdKey = @"id";
static NSString *kContactCreateDateKey = @"created_at";
static NSString *kContactUpdateDateKey = @"updated_at";
static NSString *kContactOptOutKey = @"opted_out";

@interface TUContact : NSObject

- (id)initWithDict:(NSDictionary*)dataDict;

@property (nonatomic, strong) NSString  *firstName;
@property (nonatomic, strong) NSString  *lastName;
@property (nonatomic, strong) NSString  *businessName;
@property (nonatomic, strong) NSString  *phone;
@property (nonatomic, strong) NSString  *country;
@property (nonatomic, strong) NSString  *idStr;
@property (nonatomic, strong) NSDate    *createdDate;
@property (nonatomic, strong) NSDate    *updatedDate;
@property (assign)            BOOL      optedOut;
@property (assign)            BOOL      isIdOnly;

@end
