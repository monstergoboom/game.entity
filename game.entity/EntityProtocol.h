//
//  DBEntityProtocol.h
//  SingleDeck
//
//  Created by Alek Mitrevski on 4/6/10.
//  Copyright 2010 MonsterGoBOOM!, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EntityContainerProtocol.h"

@protocol EntityProtocol

-(id) init: (id<EntityContainerProtocol>) container;
-(id) init: (id<EntityContainerProtocol>) container withEntity:(int) entityId;

-(bool) save;
-(void) load:(int) entityId;
-(void) remove;

-(bool) validateAndAttachToEntityContainer;
-(bool) validateAndAttachToEntityContainerWithId:(id<EntityContainerProtocol>) containerId;

-(void) clearAndReset;
-(bool) doesExistForEntityId:(int) entityId;

-(NSString*) debugToString;

@end
