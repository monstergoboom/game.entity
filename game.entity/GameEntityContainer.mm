//
//  GameEntityContainer.m
//  SingleDeck
//
//  Created by Alek Mitrevski on 4/7/10.
//  Copyright 2010 MGB!. All rights reserved.
//

#import <sqlite3.h>
#import "GameEntityContainer.h"
#import "NSString+contains.h"

@implementation GameEntityContainer
@synthesize db, name, path, isOpen, schemaVersion, userVersion;

-(id) init {
	if (self = [super init]) {
		db = nil;
        name = @"";
        path = @"";
        isOpen = false;
        schemaVersion = 0;
        userVersion = 0;
	}
	
	return self;
}

-(id) initWithName:(NSString *)containerName {
    self = [super init];
    if (self != nil) {
        db = nil;
        name = containerName;
        path = @"";
        isOpen = false;
        schemaVersion = 0;
        userVersion = 0;
    }
    
    return self;
}

-(id) initWithName:(NSString*) containerName withSearchPath:(NSString*) searchPath {
    self = [super init];
    if(self != nil) {
        db = nil;
        name = containerName;
        path = searchPath;
        isOpen = false;
        userVersion = 0;
        schemaVersion = 0;
    }
    
    return self;
}

int schemaVersionCallBack(void* ptr,int count,char** resultPtr, char** columnsPtr)
{
    int* version = (int*)ptr;
    
    if(count > 0 && strcmp(columnsPtr[0], [@"schema_version" UTF8String]) == 0)
    {
        char* vstr = resultPtr[0];
        *version = atoi(vstr);
    }
    
    return 0;
}

int userVersionCallBack(void* ptr,int count,char** resultPtr, char** columnsPtr)
{
    int* version = (int*)ptr;
    
    if(count > 0 && strcmp(columnsPtr[0], [@"user_version" UTF8String]) == 0)
    {
        char* vstr = resultPtr[0];
        *version = atoi(vstr);
    }
    
    return 0;
}

-(void) open
{
    [self open:false];
}

-(void) open:(bool) create {
	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* documentsDirectory = [paths objectAtIndex:0];
	
    NSString* databaseName = [NSString stringWithFormat:@"%@.sqlite", name];
    NSString* filePath = [path stringByAppendingFormat:@"/%@", databaseName];
    
	NSLog(@"File path at: %s", [filePath UTF8String]);
    
    // check if the database exists
    bool success = false;
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    success = [fileManager fileExistsAtPath:filePath];
    
    if(!success) {
        filePath = [documentsDirectory stringByAppendingFormat:@"/%s.sqlite",[name UTF8String]];
        
        success = [fileManager fileExistsAtPath:filePath];
        
        if ( !success ){
            NSString* dbPathFromApp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:databaseName];
            
            [fileManager copyItemAtPath:dbPathFromApp toPath:filePath error:nil];
            
            success = [fileManager fileExistsAtPath:filePath];
        }
    }
    
    if(!success) {
        if(create) {
            if (sqlite3_open([filePath UTF8String], &db) == SQLITE_OK) {
                NSLog(@"Database %@ opened successfully.", name);
                isOpen = true;
                
                [self loadSchemaVersion];
                [self loadUserVersion];
                
                path = filePath;
            }
            else {
                NSLog(@"Database %@ failed to open.", name);
                isOpen = false;
            }
        }
        else {
            isOpen = false;
            NSLog(@"database %@ does not exist at file search path: %@",name, path);
        }
    }
    else {
        if (sqlite3_open([filePath UTF8String], &db) == SQLITE_OK) {
            NSLog(@"Database %@ opened successfully.", name);
            isOpen = true;
            
            [self loadSchemaVersion];
            [self loadUserVersion];
            
            path = filePath;
        }
        else {
            NSLog(@"Database %@ failed to open.", name);
            isOpen = false;
        }
    }
}

-(void) loadSchemaVersion {
    NSString* stmt = @"pragma schema_version";
    
    const char* sql = [stmt UTF8String];
    char* errmsg;
    
    if(isOpen){
        if(sqlite3_exec(db, sql, &schemaVersionCallBack, &schemaVersion, &errmsg) != SQLITE_OK) {
            NSLog(@"unable to get schema version. sql error: %s", errmsg);
        }
    }
}

-(void) loadUserVersion {
    NSString* stmt = @"pragma user_version";
    
    const char* sql = [stmt UTF8String];
    char* errmsg;
    
    if(isOpen) {
        if(sqlite3_exec(db, sql, &userVersionCallBack, &userVersion, &errmsg) != SQLITE_OK) {
            NSLog(@"unable to get user version. sql error: %s", errmsg);
        }
    }
}

-(void) updateUserVersion:(int) version {
    NSString* stmt = [NSString stringWithFormat:@"pragma user_version(%d)", version];
    
    char* errmsg;
    const char* sql = [stmt UTF8String];
    
    if(isOpen) {
        if(sqlite3_exec(db, sql, NULL, NULL, &errmsg) == SQLITE_OK ) {
            userVersion = version;
        }
        else {
            NSLog(@"unable to set user version. sql error: %s", errmsg);
        }
    }
}

-(void) close {
	if (db != nil) {
		sqlite3_close(db);
        isOpen = false;
	}
	
	NSLog(@"Database connection closed.");
}

-(void) reportErrorMessage {
    if (db != nil) {
        NSLog(@"Database Error: %s", sqlite3_errmsg(db));
    }
}

+(DataAffinityTypes) convertToAffinityDataType:(NSString*) dataType {
    DataAffinityTypes _dataType;
    
    NSString* compare = [dataType uppercaseString];
    
    if ( [compare rangeOfString:@"INT"].location != NSNotFound) {
        _dataType = DAT_INTEGER;
    }
    else if ( [compare rangeOfString:@"CHAR"].location != NSNotFound ||
             [compare rangeOfString:@"CLOB"].location != NSNotFound||
             [compare rangeOfString:@"TEXT"].location != NSNotFound) {
        _dataType = DAT_TEXT;
    }
    else if ( [compare rangeOfString:@"BLOB"].location != NSNotFound ) {
        _dataType = DAT_NONE;
    }
    else if ( [compare rangeOfString:@"REAL"].location != NSNotFound ||
             [compare rangeOfString:@"FLOA"].location != NSNotFound ||
             [compare rangeOfString:@"DOUB"].location != NSNotFound ) {
        _dataType = DAT_REAL;
    }
    else {
        _dataType = DAT_NUMERIC;
    }
    
    return _dataType;
}

+(GameEntityContainer*) gameEntityContainerFromName:(NSString*) containerName {
    return [[GameEntityContainer alloc] initWithName:containerName];
}

@end
