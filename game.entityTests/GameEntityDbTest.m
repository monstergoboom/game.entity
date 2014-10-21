//
//  GameEntityDbTest.m
//  game.entity.lib
//
//  Created by Alek Mitrevski on 7/6/14.
//  Copyright (c) 2014 Alek Mitrevski. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "GameEntity.h"
#import "GameEntityContainer.h"
#import "GameEntityDataStructure.h"

@interface GameEntityDbTest : XCTestCase

@end

@implementation GameEntityDbTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

-(void) testConnectToDb {
    GameEntityContainer* dbContainer = [[GameEntityContainer alloc] initWithName:@"game.entity"];
    [dbContainer open:true];

    XCTAssertTrue([dbContainer isOpen], @"database is not open");
    
    [dbContainer close];
}

-(void) testCreateTableDefinition {
    GameEntityContainer* dbContainer = [[GameEntityContainer alloc] initWithName:@"game.entity"];
    [dbContainer open: true];

    GameEntity* entity = [[GameEntity alloc] init:dbContainer withEntityReferenceName:@"game_object" andEntity:1];
    XCTAssert([entity doesEntityDefinitionExist] == false, @"entity table exist");
    
    GameEntityDataStructure* idColumn = [[GameEntityDataStructure alloc] init];
    idColumn.columnName = @"id";
    idColumn.columnType = DT_INTEGER;
    idColumn.isPrimarykey = true;
    idColumn.isAutoIncremented = true;
    idColumn.isNotNull = true;
    
    GameEntityDataStructure* nameColumn = [[GameEntityDataStructure alloc] init];
    nameColumn.columnName = @"name";
    nameColumn.columnType = DT_VARCHAR;
    nameColumn.length = 255;
    nameColumn.isNotNull = true;
    
    GameEntityDataStructure* descriptionColumn = [[GameEntityDataStructure alloc] init];
    descriptionColumn.columnName = @"description";
    descriptionColumn.columnType = DT_TEXT;
    
    NSMutableArray* def = [[NSMutableArray alloc] initWithCapacity:3];
    [def addObject:idColumn];
    [def addObject:nameColumn];
    [def addObject:descriptionColumn];
    
    [entity createEntityDefinition:def];
    
    [dbContainer close];
}

-(void) testAddData {
    GameEntityContainer* dbContainer = [[GameEntityContainer alloc] initWithName:@"game.entity"];
    [dbContainer open: true];
    
    GameEntity* entity = [[GameEntity alloc] init:dbContainer withEntityReferenceName:@"game_object" andEntity:1];
    [entity createEntityRecord];
    
    [entity setText:@"sword" atColumnName:@"name"];
    [entity setText:@"sword of truth" atColumnName:@"description"];
    
    bool result = [entity save];
    XCTAssert(result == true, @"unable to save entity record");
    
    [dbContainer close];
}

-(void) testUpdateData {
    GameEntityContainer* dbContainer = [[GameEntityContainer alloc] initWithName:@"game.entity"];
    [dbContainer open: true];
    
    GameEntity* entity = [[GameEntity alloc] init:dbContainer withEntityReferenceName:@"game_object" andEntity:1];
    
    [entity setText:@"sword of justice" atColumnName:@"description"];
    bool result = [entity save];
    XCTAssert(result == true, @"unable to save entity record");
    
    [dbContainer close];
}

-(void) testRemoveData {
    GameEntityContainer* dbContainer = [[GameEntityContainer alloc] initWithName:@"game.entity"];
    [dbContainer open: true];
    
    GameEntity* entity = [[GameEntity alloc] init:dbContainer withEntityReferenceName:@"game_object" andEntity:1];
    
    [entity remove];
    
    [dbContainer close];
}

-(void) testDropTableDefinition {
    GameEntityContainer* dbContainer = [[GameEntityContainer alloc] initWithName:@"game.entity"];
    [dbContainer open: true];
    
    GameEntity* entity = [[GameEntity alloc] init:dbContainer withEntityReferenceName:@"game_object" andEntity:1];
    XCTAssert([entity doesEntityDefinitionExist], @"entity table does not exist");
    
    [entity removeEntityDefinition];
    
    XCTAssert([entity doesEntityDefinitionExist] == false, @"entity table exists.");
    
    [dbContainer close];
}
@end
