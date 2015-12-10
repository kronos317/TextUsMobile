//
//  Utils.m
//  TextUs
//
//  Created by Josh Bruhin on 11/13/15.
//  Copyright © 2015 TextUs. All rights reserved.
//

#import "Utils.h"
#import "TUMessage.h"
#import "TUContact.h"
#import "Reachability.h"

@implementation Utils


+ (UIView*)navBarTitleView {
    
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_navBar"]];
    imgView.contentMode = UIViewContentModeScaleAspectFit;
    CGRect frame = imgView.frame;
    frame.size.height = 40.0;
    imgView.frame = frame;

    return imgView;
}

+ (NSString *)localizedStringForDate:(NSDate*)date withTime:(BOOL)withTime withYear:(BOOL)withYear {
    
    if (!date || ![date isKindOfClass:[NSDate class]]) {
        return @"";
    }
    
    NSString *dateComponents = @"yMMMd";
    NSString *dateFormat = [NSDateFormatter dateFormatFromTemplate:dateComponents options:0 locale:[NSLocale currentLocale]];
    NSArray *tmpSubstrings = [dateFormat componentsSeparatedByString:@"y"];
    NSString *tmpStr;
    NSRange r;
    if ([[tmpSubstrings objectAtIndex:0] length] == 0) {
        r.location = 1;
        r.length = [[tmpSubstrings objectAtIndex:1] length] - 1;
        tmpStr = [[tmpSubstrings objectAtIndex:1] substringWithRange:r];
    } else {
        r.location = 0;
        r.length = [[tmpSubstrings objectAtIndex:0] length] - 1;
        tmpStr = [[tmpSubstrings objectAtIndex:0] substringWithRange:r];
    }
    
    NSString *newStr = nil;
    if (withTime && withYear) {
        newStr = [[NSString alloc] initWithFormat:@"%@ yyyy h:mm a", tmpStr];
    }
    else if (withTime) {
        newStr = [[NSString alloc] initWithFormat:@"%@ h:mm a", tmpStr];
        
    }
    else if (withYear) {
        newStr = [[NSString alloc] initWithFormat:@"%@ yyyy", tmpStr];
    }
    else {
        tmpStr = [tmpStr substringWithRange:NSMakeRange(0, tmpStr.length - 1)]; // to get rid of trailing comma
        newStr = [[NSString alloc] initWithString:tmpStr];
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:newStr];
    NSString *formattedDateString = [formatter stringFromDate:date];
    
    return formattedDateString;
}


+ (NSInteger)heightForString:(NSString*)theStr withFont:(UIFont*)font forWith:(NSInteger)width {
    
    if (!theStr) {
        return 0;
    }
    
    theStr = [theStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSDictionary *attrs = @{NSFontAttributeName: font, NSForegroundColorAttributeName: [UIColor redColor] };
    
    NSString *text = theStr;
    NSAttributedString *attributedText = [[NSAttributedString alloc]
                                          initWithString:text
                                          attributes:attrs];
    
    CGRect rect = [attributedText boundingRectWithSize:(CGSize){(float)width, CGFLOAT_MAX}
                                               options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                               context:nil];
    
    
    return ceilf(rect.size.height);
}


+ (NSArray*)processMessagesResponse:(NSArray*)responseArray {
    
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:responseArray.count];
    for (NSDictionary *msgDict in responseArray) {
        TUMessage *message = [[TUMessage alloc] initWithDict:msgDict];
        [mArray addObject:message];
    }
    return [NSArray arrayWithArray:mArray];
}


+ (NSArray*)processContactsResponse:(NSArray*)responseArray {
    
    NSMutableArray *mArray = [[NSMutableArray alloc] initWithCapacity:responseArray.count];
    for (NSDictionary *dict in responseArray) {
        TUContact *contact = [[TUContact alloc] initWithDict:dict];
        [mArray addObject:contact];
    }
    return [NSArray arrayWithArray:mArray];
}

+ (id) checkObjectForNull:(id) object{
    if ([object isKindOfClass:[NSNull class]]) {
        return nil;
    }
    return object;
}

+ (void)showAlertWithTitle:(NSString*)title message:(NSString*)message fromViewController:(UIViewController*)vc {
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //
    }];
    
    [alert addAction:cancel];
    
    [vc presentViewController:alert animated:YES completion:nil];
}



+ (NSDate*)dateForDateString:(NSString*)dateString {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    // Always use this locale when parsing fixed format date strings
    NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [formatter setLocale:posix];
    return [formatter dateFromString:dateString];
}

+ (BOOL)notConnectedShowAlert:(BOOL)showAlert fromVC:(UIViewController*)vc {
    BOOL connected = [Utils connected];
    if (!connected && showAlert) {
        [Utils showAlertWithTitle:@"No network connection" message:@"Please reconnect to the network and try again." fromViewController:vc];
    }
    return !connected;
}

+ (BOOL)connected {
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    if (networkStatus == NotReachable) {
        NSLog(@"no internet connection");
    }
    return !(networkStatus == NotReachable);
}

+ (void)handleGeneralError:(NSError*)error fromViewController:(UIViewController*)vc {
    
    NSString *theStr = nil;
    NSString *subStr = nil;
    
    // searching string here for error codes. not a good solution, needs to be coordinated and
    // re-done with server guys at some point to handle errors better in general
    
    NSString *desc = error.localizedDescription;
    NSRange range = [desc rangeOfString:@"401"];
    
    if (range.location != NSNotFound) {
        
        theStr = @"Invalid username or password";
        subStr = @"Please try again.";
    }
    else {
        
        NSInteger theCode = error.code;
        
        switch (theCode) {
            case -1099:
            case 1099:
                theStr = @"No internet connection";
                break;
            case NSURLErrorBadServerResponse:
                theStr = @"Invalid response";
                break;
            case NSURLErrorTimedOut:
                theStr = @"Request timed out";
                break;
            case NSURLErrorCannotConnectToHost:
                theStr = @"Cannot reach server";
                break;
            case NSURLErrorNetworkConnectionLost:
                theStr = @"Lost connection";
                break;
                
            default:
                theStr = @"An error occurred";
                subStr = [NSString stringWithFormat:@"Please try again - code: %ld", (long)error.code];
                break;
        }
    }
    
    [Utils showAlertWithTitle:theStr message:subStr fromViewController:vc];

}

@end
