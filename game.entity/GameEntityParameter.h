//
//  GamenEntityParameter.h
//  SingleDeck
//
//  Created by Alek Mitrevski on 4/1/12.
//  Copyright (c) 2012 MonsterGoBOOM!, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GameEntityContainer.h"

@interface GameEntityParameter : NSObject {
    NSString* columnName;
    NSString* parameterName;
    NSObject* paramenterValue;
    DataAffinityTypes parameterDataType;
}

-(id) init:(NSString*) name withDataType:(DataAffinityTypes) dataType  withValue:(NSObject*) value columnName:(NSString*) column;

@property (nonatomic, strong) NSString* columnName;
@property (nonatomic, strong) NSString* parameterName;
@property (nonatomic, strong) NSObject* paramenterValue;
@property (nonatomic, assign) DataAffinityTypes parameterDataType;

@end
