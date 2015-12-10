//
//  TUContact.m
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "TUContact.h"
#import "Utils.h"

@implementation TUContact

@synthesize firstName;
@synthesize lastName;
@synthesize businessName;
@synthesize phone;
@synthesize country;
@synthesize idStr;
@synthesize createdDate;
@synthesize updatedDate;
@synthesize optedOut;
@synthesize isIdOnly;

- (id)initWithDict:(NSDictionary*)dataDict {
    self = [super init];
    if (self) {
        self.firstName = [Utils checkObjectForNull:[dataDict objectForKey:kContactFirstNameKey]];
        self.lastName = [Utils checkObjectForNull:[dataDict objectForKey:kContactLastNameKey]];
        self.businessName = [Utils checkObjectForNull:[dataDict objectForKey:kContactBusinessNameKey]];
        self.phone = [Utils checkObjectForNull:[dataDict objectForKey:kContactPhoneKey]];
        self.country = [Utils checkObjectForNull:[dataDict objectForKey:kContactCountryKey]];
        self.idStr = [[Utils checkObjectForNull:[dataDict objectForKey:kContactIdKey]] stringValue];
        self.createdDate = [Utils checkObjectForNull:[dataDict objectForKey:kContactCreateDateKey]];
        self.updatedDate = [Utils checkObjectForNull:[dataDict objectForKey:kContactUpdateDateKey]];
        self.optedOut = [[Utils checkObjectForNull:[dataDict objectForKey:kContactOptOutKey]] boolValue];
    }
    return self;
}

@end
