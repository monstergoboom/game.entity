//
//  GameEntityDataStructure.m
//  SingleDeck
//
//  Created by Alek Mitrevski on 3/31/12.
//  Copyright (c) 2012 MonsterGoBOOM!, LLC. All rights reserved.
//

#import "GameEntityContainer.h"
#import "GameEntityDataStructure.h"

@implementation GameEntityDataStructure 
@synthesize columnIndex, columnName, columnAffinityType, defaultValue, columnType, dataType, isPrimarykey, length, precision, isSystemField, isAutoIncremented, isNotNull;

-(id) init {
    self = [super init];
    
    if ( self != nil ) {
        columnIndex = 0;
        columnName = nil;
        columnAffinityType = DAT_NONE;
        columnType = DT_NONE;
        defaultValue = nil;
        dataType = nil;
        isPrimarykey = false;
        length = 0;
        precision = 0;
        isAutoIncremented = false;
        isNotNull = false;
    }
    
    return self;
}

@end
