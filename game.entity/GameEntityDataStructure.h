//
//  GameEntityDataStructure.h
//  SingleDeck
//
//  Created by Alek Mitrevski on 3/31/12.
//  Copyright (c) 2012 MonsterGoBOOM!, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GameEntityDataStructure : NSObject {
    int columnIndex;
    bool isPrimaryKey;
    NSString* columnName;
    DataAffinityTypes columnAffinityType;
    DataTypes columnType;
    NSString* dataType; 
    NSObject* defaultValue;
    int length;
    int precision;
    bool isSystemField;
    bool isAutoIncremented;
    bool isNotNull;
}

@property (nonatomic, assign) int columnIndex;
@property (nonatomic, assign) bool isPrimarykey;
@property (nonatomic, strong) NSString* columnName;
@property (nonatomic, assign) DataAffinityTypes columnAffinityType;
@property (nonatomic, assign) DataTypes columnType;
@property (nonatomic, strong) NSString* dataType;
@property (nonatomic, strong) NSObject* defaultValue;
@property (nonatomic, assign) int length;
@property (nonatomic, assign) int precision;
@property (nonatomic, assign) bool isSystemField;
@property (nonatomic, assign) bool isAutoIncremented;
@property (nonatomic, assign) bool isNotNull;

@end
