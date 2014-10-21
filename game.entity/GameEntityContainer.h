//
//  GameEntityContainer.h
//  SingleDeck
//
//  Created by Alek Mitrevski on 4/7/10.
//  Copyright 2010 MGB!. All rights reserved.
//

#import <sqlite3.h>
#import <Foundation/Foundation.h>
#import "EntityContainerProtocol.h"

typedef enum _DataAffinityTypes {
    DAT_NONE,
    DAT_INTEGER,
    DAT_REAL,
    DAT_TEXT,
    DAT_NUMERIC
} DataAffinityTypes;

typedef enum _DataTypes {
    DT_NONE,
    DT_INT,
    DT_INTEGER,
    DT_TINYINT,
    DT_SMALLINT,
    DT_MEDIUMINT,
    DT_BIGINT,
    DT_UNSIGNEDBIGINT,
    DT_VARCHAR,
    DT_NVARCHAR,
    DT_TEXT,
    DT_CHAR,
    DT_NCHAR,
    DT_BLOB,
    DT_REAL,
    DT_DOUBLE,
    DT_FLOAT,
    DT_NUMERIC,
    DT_DECIMAL,
    DT_BOOLEAN,
    DT_DATE,
    DT_DATETIME
} DataTypes;

@interface GameEntityContainer : NSObject<EntityContainerProtocol> {
    NSString* name;
    NSString* path;
    
	sqlite3* db;
    
    bool isOpen;
    
    int schemaVersion;
    int userVersion;
}

@property (nonatomic, assign) sqlite3* db;
@property (strong) NSString* name;
@property (strong) NSString* path;
@property (nonatomic, assign) bool isOpen;
@property (nonatomic, readonly) int schemaVersion;
@property (nonatomic, readonly) int userVersion;

-(void) updateUserVersion:(int) version;

+(GameEntityContainer*) gameEntityContainerFromName:(NSString*) containerName;

+(DataAffinityTypes) convertToAffinityDataType:(NSString*) dataType;

@end