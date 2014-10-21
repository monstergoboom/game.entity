//
//  GamenEntityParameter.m
//  SingleDeck
//
//  Created by Alek Mitrevski on 4/1/12.
//  Copyright (c) 2012 MonsterGoBOOM!, LLC. All rights reserved.
//

#import "GameEntityParameter.h"

@implementation GameEntityParameter
@synthesize parameterName, paramenterValue, parameterDataType, columnName;

-(id) init:(NSString*) name withDataType:(DataAffinityTypes) dataType withValue:(NSObject*) value columnName:(NSString *)column {
    self = [super init];
    if (self != nil) {
        columnName = column;
        parameterName = name;
        paramenterValue = value;
        parameterDataType = dataType;
    }
    
    return self;
}

@end
