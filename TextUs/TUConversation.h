//
//  TUConversation.h
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TUContact.h"

@interface TUConversation : NSObject

@property (nonatomic, strong) TUContact *contact;
@property (nonatomic, strong) NSArray *messages;

@end
