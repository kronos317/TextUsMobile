//
//  TUMessageTemplate.m
//  TextUs
//
//  Created by Josh Bruhin on 4/15/16.
//  Copyright © 2016 TextUs. All rights reserved.
//

#import "TUMessageTemplate.h"
#import "Utils.h"

@implementation TUMessageTemplate

- (id)initWithDict:(NSDictionary*)dataDict {
    self = [super init];
    if (self) {
        
        self.content = [Utils checkObjectForNull:[dataDict objectForKey:kMessageTemplateContentKey]];
        self.title = [Utils checkObjectForNull:[dataDict objectForKey:kMessageTemplateTitleKey]];
        self.idStr = [[Utils checkObjectForNull:[dataDict objectForKey:kMessageTemplateIdKey]] stringValue];
        self.createdDateStr = [Utils checkObjectForNull:[dataDict objectForKey:kMessageTemplateCreateDateKey]];
        self.updatedDateStr = [Utils checkObjectForNull:[dataDict objectForKey:kMessageTemplateUpdateDateKey]];
        
        self.createdDate = [Utils dateForDateString:self.createdDateStr];
        self.updatedDate = [Utils dateForDateString:self.updatedDateStr];
        
        if (!self.createdDate || ![self.createdDate isKindOfClass:[NSDate class]]) {
            self.createdDate = [NSDate date];
        }
    }
    return self;
}

@end
