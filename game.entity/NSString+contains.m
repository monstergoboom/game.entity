//
//  NSString+contains.m
//  SingleDeck
//
//  Created by Alek Mitrevski on 3/31/12.
//  Copyright (c) 2012 MonsterGoBOOM!, LLC. All rights reserved.
//

#import "NSString+contains.h"

@implementation NSString ( containsCategory )

- (BOOL) containsString: (NSString*) substring ignoreCase:(bool) ignore
{   
    NSString* compareString = self;
    if ( ignore == true ) {
        compareString = [compareString lowercaseString];
        substring = [substring lowercaseString];
    }
    
    NSRange range = [compareString rangeOfString : substring];
    return ( range.location != NSNotFound );
}

@end
