//
//  EntityContainerProtocol.h
//  SingleDeck
//
//  Created by Alek Mitrevski on 4/7/10.
//  Copyright 2010 MonsterGoBOOM!, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EntityContainerProtocol

-(id) initWithName:(NSString*) containerName;
-(id) initWithName:(NSString*) containerName withSearchPath:(NSString*) searchPath;

-(void) open;
-(void) open: (bool) create;

-(void) close;

-(void) reportErrorMessage;

@end
