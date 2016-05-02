//
//  TUMessageTemplate.h
//  TextUs
//
//  Created by Josh Bruhin on 4/15/16.
//  Copyright © 2016 TextUs. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *kMessageTemplateContentKey = @"content";
static NSString *kMessageTemplateTitleKey = @"title";
static NSString *kMessageTemplateIdKey = @"id";
static NSString *kMessageTemplateCreateDateKey = @"created_at";
static NSString *kMessageTemplateUpdateDateKey = @"updated_at";

@interface TUMessageTemplate : NSObject

- (id)initWithDict:(NSDictionary*)dataDict;

@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *idStr;
@property (nonatomic, strong) NSString  *createdDateStr;
@property (nonatomic, strong) NSString  *updatedDateStr;
@property (nonatomic, strong) NSDate  *createdDate;
@property (nonatomic, strong) NSDate  *updatedDate;

@end
