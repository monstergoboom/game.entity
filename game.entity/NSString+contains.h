//
//  NSString+contains.h
//  SingleDeck
//
//  Created by Alek Mitrevski on 3/31/12.
//  Copyright (c) 2012 MonsterGoBOOM!, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString ( containsCategory )
- (BOOL) containsString: (NSString*) substring ignoreCase:(bool) ignore;
@end
