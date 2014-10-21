//
//  GameEntity.m
//  SingleDeck
//
//  Created by Alek Mitrevski on 3/30/12.
//  Copyright (c) 2012 MonsterGoBOOM!, LLC. All rights reserved.
//


#import <sqlite3.h>
#import "GameEntityContainer.h"
#import "GameEntityDataStructure.h"
#import "GameEntityParameter.h"

#import "GameEntity.h"

@implementation GameEntity
@synthesize doesEntityDefinitionExist,primaryKeyAutoIncrement;

-(id) init: (id<EntityContainerProtocol>) container {
    self = [super init];
    if ( self != nil ) {
        entityContainer = container;
        gameEntityId = [NSNumber numberWithLong:0];
        entityName = @"";
        
        createStmt = nil;
        selectStmt = nil;
        updateStmt = nil;
        insertStmt = nil;
        removeStmt = nil;
        
        resultSet = nil;
        currentRow = nil;
        
        primaryKeyAutoIncrement = false;
        doesEntityDefinitionExist = false;
    }
    
    return self;
}

-(id) init: (id<EntityContainerProtocol>) container withEntity:(int) entityId {
    self = [super init];
    if ( self != nil ) {
        entityContainer = container;
        gameEntityId = [NSNumber numberWithInt:entityId];
        entityName = @"";
        
        createStmt = nil;
        selectStmt = nil;
        updateStmt = nil;
        insertStmt = nil;
        removeStmt = nil;
        
        resultSet = nil;
        currentRow = nil;
        
        primaryKeyAutoIncrement = false;
        doesEntityDefinitionExist = false;
    }
    
    return self;
}

-(id) init:(id<EntityContainerProtocol>)container withEntityReferenceName:(NSString*) name {
    self = [self init:container];
    if ( self != nil ) {
        entityName = name;
        [self loadEntityDataStructure];
        [self checkAutoIncrementKey];
    }
    
    return self;
}

-(id) init:(id<EntityContainerProtocol>)container withEntityReferenceName:(NSString*) name andEntity:(int)entityId {
    self = [self init:container withEntity:entityId];
    if ( self != nil ) {
        entityName = name;
        [self loadEntityDataStructure];
        [self checkAutoIncrementKey];
        [self load:entityId];
    }
    
    return self;
}

-(void) checkAutoIncrementKey {
    primaryKeyAutoIncrement = false;
    
    const char* sql = [[NSString stringWithFormat:@"select name, seq from sqlite_sequence where name = '%@'", entityName] UTF8String];
    
    sqlite3_stmt* prepared = nil;
    if (sqlite3_prepare_v2([(GameEntityContainer*)entityContainer db], sql, -1, &prepared, NULL) == SQLITE_OK) {
        NSLog(@"sqlite_sequence statement prepared successfully.");
        
        int result = sqlite3_step(prepared);
        if (result == SQLITE_ROW) {
            long seq = sqlite3_column_int64(prepared, 1);
            primaryKeyAutoIncrement = true;
            
            NSLog(@"Entity: %@, PrimaryKey AutoIncrement: %d, Sequence: %ld", entityName, primaryKeyAutoIncrement, seq);
        } else {
            NSLog(@"Entity: %@, PrimaryKey AutoIncrement: %d", entityName, primaryKeyAutoIncrement);
        }
    } else {
        [entityContainer reportErrorMessage];
    }
    
    sqlite3_reset(prepared);
    sqlite3_finalize(prepared);
}

-(void) loadEntityDataStructure {
    [self loadEntityDataStructure: entityName];
}

-(void) loadEntityDataStructure:(NSString*) name {
    NSAssert(name != nil, @"data structure reference name must not be nil.");
    
    const char* sql = [[NSString stringWithFormat:@"pragma table_info(%@)", name] UTF8String];
    
    sqlite3_stmt* prepared = nil;
    if (sqlite3_prepare_v2([(GameEntityContainer*)entityContainer db], sql, -1, &prepared, NULL) == SQLITE_OK) {
        NSLog(@"Statement prepared successfully.");
        
        int cid;
        NSString* columnName;
        NSString* defaultValue;
        NSString* columnType;
        DataAffinityTypes type;
        int notNull;
        int pk;
        
        int result = SQLITE_OK;
        dataStructure = [NSMutableArray arrayWithCapacity:1];
        
        while((result = sqlite3_step(prepared)) == SQLITE_ROW) {
            cid = sqlite3_column_int(prepared, 0);
            
            const char* cName = (const char*) sqlite3_column_text(prepared, 1);
            const char* cType = (const char*) sqlite3_column_text(prepared, 2);
            
            columnName = [NSString stringWithUTF8String:cName];
            columnType = [NSString stringWithUTF8String:cType];
            
            type = [GameEntityContainer convertToAffinityDataType:columnType];
            notNull = sqlite3_column_int(prepared, 3);
            const unsigned char* dv = sqlite3_column_text(prepared, 4);
            defaultValue = dv != nil ? [NSString stringWithUTF8String: (const char*) sqlite3_column_text(prepared, 4)] : @"";
            pk = sqlite3_column_int(prepared, 5);
            
            GameEntityDataStructure* ds = [[GameEntityDataStructure alloc] init];
            
            ds.columnIndex = cid;
            ds.isPrimarykey = (pk == 1?true:false);
            ds.columnName = columnName;
            ds.dataType = columnType;
            ds.columnAffinityType = type;
            ds.defaultValue = defaultValue;
            ds.length = 0;
            
            [dataStructure addObject:ds];
        }
        
        if([dataStructure count] > 0)
        {
            // add row id
            GameEntityDataStructure* rowIdDs = [[GameEntityDataStructure alloc] init];
            rowIdDs.columnIndex = (int)dataStructure.count;
            rowIdDs.isPrimarykey = false;
            rowIdDs.columnName = @"rowid";
            rowIdDs.dataType = @"int64";
            rowIdDs.columnAffinityType = DAT_INTEGER;
            rowIdDs.defaultValue = @"-1";
            rowIdDs.length = 0;
            rowIdDs.isSystemField = true;
            
            [dataStructure addObject:rowIdDs];
            
            // add is dirty
            GameEntityDataStructure* dirty = [[GameEntityDataStructure alloc] init];
            dirty.columnIndex = (int)dataStructure.count;
            dirty.isPrimarykey = false;
            dirty.columnName = @"dirty";
            dirty.dataType = @"bool";
            dirty.columnAffinityType = DAT_NUMERIC;
            dirty.defaultValue = @"false";
            dirty.length = 0;
            dirty.isSystemField = true;
            
            [dataStructure addObject:dirty];
            
            // add is new row
            GameEntityDataStructure* isNew = [[GameEntityDataStructure alloc] init];
            isNew.columnIndex = (int)dataStructure.count;
            isNew.isPrimarykey = false;
            isNew.columnName = @"new";
            isNew.dataType = @"bool";
            isNew.columnAffinityType = DAT_NUMERIC;
            isNew.defaultValue = @"false";
            isNew.length = 0;
            isNew.isSystemField = true;
            
            [dataStructure addObject:isNew];
            
            // add is scheduled for delete
            GameEntityDataStructure* isDeleted = [[GameEntityDataStructure alloc] init];
            isDeleted.columnIndex = (int)dataStructure.count;
            isDeleted.isPrimarykey = false;
            isDeleted.columnName = @"delete";
            isDeleted.dataType = @"bool";
            isDeleted.columnAffinityType = DAT_NUMERIC;
            isDeleted.defaultValue = @"false";
            isDeleted.length = 0;
            isDeleted.isSystemField = true;
            
            [dataStructure addObject:isDeleted];
            
            GameEntityDataStructure* hasErrored = [[GameEntityDataStructure alloc] init];
            hasErrored.columnIndex = (int)dataStructure.count;
            hasErrored.isPrimarykey = false;
            hasErrored.columnName = @"error";
            hasErrored.dataType = @"bool";
            hasErrored.columnAffinityType = DAT_NUMERIC;
            hasErrored.defaultValue = @"false";
            hasErrored.length = 0;
            hasErrored.isSystemField = true;
            
            [dataStructure addObject:hasErrored];
            
            GameEntityDataStructure* errorCode = [[GameEntityDataStructure alloc] init];
            errorCode.columnIndex = (int)dataStructure.count;
            errorCode.isPrimarykey = false;
            errorCode.columnName = @"error_code";
            errorCode.dataType = @"integer";
            errorCode.columnAffinityType = DAT_NUMERIC;
            errorCode.defaultValue = @"0";
            errorCode.length = 0;
            errorCode.isSystemField = true;
            
            [dataStructure addObject:errorCode];
            
            GameEntityDataStructure* errorMsg = [[GameEntityDataStructure alloc] init];
            errorMsg.columnIndex = (int)dataStructure.count;
            errorMsg.isPrimarykey = false;
            errorMsg.columnName = @"error_msg";
            errorMsg.dataType = @"varchar(255)";
            errorMsg.columnAffinityType = DAT_TEXT;
            errorMsg.defaultValue = @"";
            errorMsg.length = 255;
            errorMsg.isSystemField = true;
            
            [dataStructure addObject:errorMsg];
            
            doesEntityDefinitionExist = true;
        }
        
        sqlite3_reset(prepared);
        sqlite3_finalize(prepared);
        
        NSLog(@"table: %@ is loaded. Columns: %lx", name, [dataStructure count]);
    }
    else {
        [entityContainer reportErrorMessage];
    }
}

-(NSArray*) getPrimaryKeyColumns {
    NSMutableArray* array = [NSMutableArray array];
    
    GameEntityDataStructure* ds = nil;
    for (ds in dataStructure) {
        if ( ds.isPrimarykey ) {
            [array addObject:ds];
        }
    }
    
    return array;
}

/// Create an empty record from the current datastructure
-(void) createEntityRecord {
    
    GameEntityDataStructure* s = nil;
    
    currentRow = [[NSMutableArray alloc] initWithCapacity:[dataStructure count]];
    
    for(s in dataStructure) {
        
        NSObject* data = nil;
        
        switch (s.columnAffinityType) {
            case DAT_NONE:
                data = [[NSData alloc] init];
                break;
            case DAT_INTEGER:
            case DAT_REAL:
                data = [[NSNumber alloc] init];
                break;
            case DAT_NUMERIC:
            case DAT_TEXT:
                data = [[NSString alloc] init];
                break;
            default:
                break;
        }
        data = s.defaultValue;
        
        [currentRow addObject:data];
    }
    
    if ( resultSet == nil )
        resultSet = [[NSMutableArray alloc] initWithCapacity:1];
    
    [self setNeedsUpdate:true];
    [self setIsNew:true];
    
    [resultSet addObject:currentRow];
}

-(void) createEntityDefinition:(NSArray*) definition {
    [self buildCreateTable:definition];
    
    if (sqlite3_prepare_v2([(GameEntityContainer*)entityContainer db], [create UTF8String], -1, &createStmt, NULL) == SQLITE_OK) {
        
        int errCode = 0;
        const char* errMsg;
        if ( SQLITE_DONE != sqlite3_step(createStmt) ) {
            errCode = sqlite3_errcode([(GameEntityContainer*)entityContainer db]);
            errMsg = sqlite3_errmsg([(GameEntityContainer*)entityContainer db]);
            
            NSLog(@"Error creating table. %d - %s", errCode, errMsg);
            
            [self setIsInError:true withErrorCode:[NSNumber numberWithInt:errCode] withErrorMessage:[NSString stringWithCString:errMsg encoding:NSASCIIStringEncoding]];
        }
        else {
            NSLog(@"Create Table - (create) statement prepared successfully. sql: %@", create);
        }
    }
    else {
        NSLog(@"unable to prepare sql stateme for create. sql: %@", create);
    }
}

-(void) removeEntityDefinition {
    [self buildDropTable];
    
    if (sqlite3_prepare_v2([(GameEntityContainer*)entityContainer db], [drop UTF8String], -1, &dropStmt, NULL) == SQLITE_OK) {
        int errCode = 0;
        const char* errMsg;
        if ( SQLITE_DONE != sqlite3_step(dropStmt) ) {
            errCode = sqlite3_errcode([(GameEntityContainer*)entityContainer db]);
            errMsg = sqlite3_errmsg([(GameEntityContainer*)entityContainer db]);
            
            NSLog(@"Error dropping table. %d - %s", errCode, errMsg);
            
            [self setIsInError:true withErrorCode:[NSNumber numberWithInt:errCode] withErrorMessage:[NSString stringWithCString:errMsg encoding:NSASCIIStringEncoding]];
        }
        else {
            NSLog(@"table %@ dropped.", entityName);
            
            createStmt = nil;
            selectStmt = nil;
            updateStmt = nil;
            insertStmt = nil;
            removeStmt = nil;
            
            resultSet = nil;
            currentRow = nil;
            
            primaryKeyAutoIncrement = false;
            doesEntityDefinitionExist = false;
            
            [dataStructure removeAllObjects];
        }
    }
}

-(void) buildCreateTable:(NSArray*) definition {
    
    create = [NSMutableString stringWithFormat:@"create table if not exists %@ (", entityName];
    
    GameEntityDataStructure* s = nil;
    
    int definitionCount = 0;
    for(s in definition) {
        definitionCount ++;
        
        [create appendFormat:@"%@ ", [s columnName]];
        
        if([s isKindOfClass:[GameEntityDataStructure class]]) {
            switch([s columnType]) {
                case DT_INT:
                    [create appendString:@"int "];
                    break;
                case DT_INTEGER:
                    [create appendString:@"integer "];
                    break;
                case DT_TINYINT:
                    [create appendString:@"tinyint "];
                    break;
                case DT_SMALLINT:
                    [create appendString:@"smallint "];
                    break;
                case DT_MEDIUMINT:
                    [create appendString:@"mediumint "];
                    break;
                case DT_BIGINT:
                    [create appendString:@"bigint "];
                    break;
                case DT_UNSIGNEDBIGINT:
                    [create appendString:@"unsigned big int "];
                    break;
                case DT_VARCHAR:
                    [create appendFormat:@"varchar(%d) ", [s length]];
                    break;
                case DT_NVARCHAR:
                    [create appendFormat:@"nvarchar(%d) ", [s length]];
                    break;
                case DT_CHAR:
                    [create appendFormat:@"char(%d) ", [s length]];
                    break;
                case DT_NCHAR:
                    [create appendFormat:@"nchar(%d) ", [s length]];
                    break;
                case DT_TEXT:
                    [create appendString:@"text "];
                    break;
                case DT_BLOB:
                    [create appendString:@"blob "];
                    break;
                case DT_REAL:
                    [create appendString:@"real "];
                    break;
                case DT_DOUBLE:
                    [create appendString:@"double "];
                    break;
                case DT_FLOAT:
                    [create appendString:@"float "];
                    break;
                case DT_NUMERIC:
                    [create appendString:@"numeric "];
                    break;
                case DT_BOOLEAN:
                    [create appendString:@"bool "];
                    break;
                case DT_DATE:
                    [create appendString:@"date "];
                    break;
                case DT_DATETIME:
                    [create appendString:@"datetime "];
                    break;
                case DT_DECIMAL:
                    [create appendFormat:@"decimal(%d,%d)", [s length], [s precision]];
                    break;
                default:
                    NSLog(@"unknown data type. unable to add to create table definition. %d", [s columnType] );
                    break;
            }
            
            // Apply table and column constraints
            if([s columnType] == DT_INTEGER && [s isPrimarykey] == true && [s isAutoIncremented] == true) {
                [create appendString:@"primary key autoincrement"];
            }
            else if ([s isPrimarykey]) {
                [create appendString:@"primary key"];
            }
            
            if([s isNotNull] == true) {
                [create appendString:@" not null"];
            }
            
            if (definitionCount < [definition count]) {
                [create appendString:@", "];
            }
        }
    }
    
    [create appendString:@")"];
    
    NSLog(@"create table sql: %@", create);
}

-(void) buildDropTable {
    drop = [NSMutableString stringWithFormat:@"drop table %@", entityName];
    
    NSLog(@"drop table sql: %@", drop);
}

-(void) buildSelect:(NSArray*) parameters {
    select = [NSMutableString stringWithString:@"select "];
    
    // build select statement
    GameEntityDataStructure* item = nil;
    for (item in dataStructure) {
        if ( !item.isSystemField ) {
            [select appendFormat:@"%@, ", item.columnName];
        }
    }
    
    NSRange range = NSMakeRange([select length] - 2, 2);
    
    [select replaceCharactersInRange:range withString:@" "];
    
    [select appendFormat:@"from %@ ", entityName];
    
    // build where clause
    if ( parameters.count > 0 ) {
        [select appendString:@"where "];
        
        GameEntityParameter* param = nil;
        for(param in parameters) {
            [select appendFormat:@"%@ ", param.columnName];
            [select appendFormat:@"= %@ ", param.parameterName];
            [select appendString:@"and "];
        }
        
        [select replaceCharactersInRange:NSMakeRange([select length] - 5, 5) withString:@" "];
    }
    
    NSLog(@"select sql: %@", select);
}

-(void) buildInsert {
    insert = [NSMutableString stringWithFormat:@"insert into %@ (", entityName];
    
    // build insert statement
    GameEntityDataStructure* item = nil;
    for(item in dataStructure) {
        if (!item.isSystemField) {
            if(!item.isPrimarykey || (item.isPrimarykey && !primaryKeyAutoIncrement)) {
                [insert appendFormat:@"%@, ", item.columnName];
            }
        }
    }
    
    [insert replaceCharactersInRange:NSMakeRange([insert length] - 2,2) withString:@") values ("];
    
    for(item in dataStructure) {
        if (!item.isSystemField) {
            if(!item.isPrimarykey || (item.isPrimarykey && !primaryKeyAutoIncrement)) {
                [insert appendFormat:@"@%@, ", item.columnName];
            }
        }
    }
    
    [insert replaceCharactersInRange:NSMakeRange([insert length] - 2, 2) withString:@")"];
    
    NSLog(@"insert sql: %@", insert);
}

-(void) buildUpdate:(NSArray*) parameters  {
    update = [NSMutableString stringWithFormat:@"update %@ set ", entityName];
    
    // build update statement
    GameEntityDataStructure* item = nil;
    for(item in dataStructure) {
        if (!item.isSystemField && !item.isPrimarykey) {
            [update appendFormat:@"%@ = @%@, ", item.columnName, item.columnName];
        }
    }
    
    [update replaceCharactersInRange:NSMakeRange([update length] - 2, 2) withString:@" "];
    
    // build where clause
    if ( parameters.count > 0 ) {
        [update appendString:@"where "];
        
        GameEntityParameter* param = nil;
        for(param in parameters) {
            [update appendFormat:@"%@ ", param.columnName];
            [update appendFormat:@"= %@ ", param.parameterName];
            [update appendString:@"and "];
        }
        
        [update replaceCharactersInRange:NSMakeRange([update length] - 5, 5) withString:@" "];
    }
    
    NSLog(@"update sql: %@", update);
}

-(void) buildRemove:(NSArray*) parameters  {
    remove = [NSMutableString stringWithFormat:@"delete from %@ where ", entityName];
    
    // build where clause
    if ( parameters.count > 0 ) {
        GameEntityParameter* param = nil;
        for(param in parameters) {
            [remove appendFormat:@"%@ ", param.columnName];
            [remove appendFormat:@"= %@ ", param.parameterName];
            [remove appendString:@"and "];
        }
        
        [remove replaceCharactersInRange:NSMakeRange([remove length] - 5, 5) withString:@" "];
    }
    
    NSLog(@"remove sql: %@", remove);
}

-(GameEntityParameter*) createParameter:(NSString*) columnName withValue:(NSObject *) value {
    GameEntityParameter* p = nil;
    GameEntityDataStructure* s = nil;
    for(s in dataStructure) {
        if ( [s.columnName compare:columnName options: NSCaseInsensitiveSearch] == NSOrderedSame ) {
            p = [[GameEntityParameter alloc] init:[NSString stringWithFormat:@"@%@", s.columnName] withDataType:s.columnAffinityType withValue:value columnName:s.columnName];
            break;
        }
    }
    
    return p;
}

-(long) count {
    long c = 0;
    
    if ( resultSet != nil )
        c = resultSet.count;
    
    return c;
}

-(bool) save {
    bool success = true;
    
    NSArray* primarykeys = [self getPrimaryKeyColumns];
    GameEntityDataStructure* pkds = nil;
    NSMutableArray* whereParams = [NSMutableArray arrayWithCapacity:primarykeys.count];
    
    for(pkds in primarykeys) {
        [whereParams addObject:[self createParameter:pkds.columnName withValue:pkds.defaultValue]];
    }
    
    // create the required sql statement to prepare for each crud operation
    [self buildUpdate: whereParams];
    [self buildInsert];
    [self buildRemove: whereParams];
    
    // prepares the statements so that they can be reused if necessary for each row processed.
    if (sqlite3_prepare_v2([(GameEntityContainer*)entityContainer db], [update UTF8String], -1, &updateStmt, NULL) == SQLITE_OK) {
        NSLog(@"Save - (update) statement prepared successfully.");
    } else {
        NSLog(@"Error while attempting to prepare update statement. Message: %s", sqlite3_errmsg([(GameEntityContainer*)entityContainer db]));
        throw [NSException exceptionWithName:@"sqlite" reason:[NSString stringWithUTF8String: sqlite3_errmsg([(GameEntityContainer*)entityContainer db])] userInfo:nil];
    }
    
    if (sqlite3_prepare_v2([(GameEntityContainer*)entityContainer db], [insert UTF8String], -1,&insertStmt, NULL) == SQLITE_OK) {
        NSLog(@"Save - (insert) statement prepared successfully.");
    } else {
        NSLog(@"Error while attempting to prepare insert statement. Message: %s", sqlite3_errmsg([(GameEntityContainer*)entityContainer db]));
        throw [NSException exceptionWithName:@"sqlite" reason:[NSString stringWithUTF8String: sqlite3_errmsg([(GameEntityContainer*)entityContainer db])] userInfo:nil];
    }
    
    if (sqlite3_prepare_v2([(GameEntityContainer*)entityContainer db], [remove UTF8String], -1, &removeStmt, NULL) == SQLITE_OK) {
        NSLog(@"Save - (delete) statement prepared successfully.");
    } else {
        NSLog(@"Error while attempting to prepare delete statement. Message: %s", sqlite3_errmsg([(GameEntityContainer*)entityContainer db]));
        throw [NSException exceptionWithName:@"sqlite" reason:[NSString stringWithUTF8String: sqlite3_errmsg([(GameEntityContainer*)entityContainer db])] userInfo:nil];
    }
    
    // enumerate through the list of data objects/rows
    [self reset];
    
    // temporary working result set
    NSMutableArray* workingArray = [NSMutableArray arrayWithCapacity:resultSet.count];
    
    while ([self next] == true) {
        if ( [self needsUpdate] == true) {
            if ([self isScheduledForDelete] == true) {
                NSLog(@"row needs update. removing record from table.");
                if ([self isNew] == false) {
                    NSLog(@"deleting record: %ld", [self getRowId].longValue);
                    
                    // bind where statement
                    GameEntityParameter* w = nil;
                    for(w in whereParams) {
                        w.paramenterValue = [self getValueAtColumnName:w.columnName];
                        [self bindParameter:w withStatement:removeStmt];
                    }
                    
                    // delete records
                    int errCode = 0;
                    const char* errMsg;
                    if ( SQLITE_DONE != sqlite3_step(removeStmt) ) {
                        errCode = sqlite3_errcode([(GameEntityContainer*)entityContainer db]);
                        errMsg = sqlite3_errmsg([(GameEntityContainer*)entityContainer db]);
                        
                        NSLog(@"Error deleting record. %d - %s", errCode, errMsg);
                        
                        [self setIsInError:true withErrorCode:[NSNumber numberWithInt:errCode] withErrorMessage:[NSString stringWithCString:errMsg encoding:NSASCIIStringEncoding]];
                        
                        success = false;
                    }
                    
                    // reset after every update
                    sqlite3_reset(removeStmt);
                }
            } else if ([self isNew] == true) {
                NSLog(@"row needs update. inserting new record to table.");
                GameEntityDataStructure* ds = nil;
                for(ds in dataStructure) {
                    // bind all of the update fields
                    if ( ds.isSystemField == false && ds.isPrimarykey == false ) {
                        [self bindParameter:[self createParameter:ds.columnName withValue:[self getValueAtColumnIndex:ds.columnIndex]] withStatement:insertStmt];
                    }
                }
                
                int errCode = 0;
                const char* errMsg;
                if ( SQLITE_DONE != sqlite3_step(insertStmt) ) {
                    errCode = sqlite3_errcode([(GameEntityContainer*)entityContainer db]);
                    errMsg = sqlite3_errmsg([(GameEntityContainer*)entityContainer db]);
                    
                    NSLog(@"Error inserting record. %d - %s", errCode, errMsg);
                    
                    [self setIsInError:true withErrorCode:[NSNumber numberWithInt:errCode] withErrorMessage:[NSString stringWithCString:errMsg encoding:NSASCIIStringEncoding]];
                    
                    
                    success = false;
                }
                else {
                    // we want to set the last id of the primary key for the new inserted record so that it becomes an update based on id next
                    // time around
                    if (primaryKeyAutoIncrement) {
                        long rowid = sqlite3_last_insert_rowid([(GameEntityContainer*)entityContainer db]);
                        
                        GameEntityDataStructure* k = nil;
                        for (k in primarykeys) {
                            NSNumber* id = [NSNumber numberWithLong:rowid];
                            [self setNumber:id atColumnIndex:k.columnIndex];
                            [self setRowId:id];
                            
                            NSLog(@"New record added: %ld", rowid);
                        }
                    }
                }
                
                // reset after every insert
                sqlite3_reset(insertStmt);
            } else {
                NSLog(@"row needs update. updating existing record to table.");
                
                GameEntityDataStructure* ds = nil;
                for (ds in dataStructure) {
                    // bind all of the update fields
                    if ( ds.isSystemField == false && ds.isPrimarykey == false ) {
                        [self bindParameter:[self createParameter:ds.columnName withValue:[self getValueAtColumnIndex:ds.columnIndex]] withStatement:updateStmt];
                    }
                }
                
                // bind where statement
                GameEntityParameter* w = nil;
                for(w in whereParams) {
                    w.paramenterValue = [self getValueAtColumnName:w.columnName];
                    [self bindParameter:w withStatement:updateStmt];
                }
                
                // update the sql
                int errCode = 0;
                const char* errMsg;
                if ( SQLITE_DONE != sqlite3_step(updateStmt) ) {
                    errCode = sqlite3_errcode([(GameEntityContainer*)entityContainer db]);
                    errMsg = sqlite3_errmsg([(GameEntityContainer*)entityContainer db]);
                    
                    NSLog(@"Error updating record. %d - %s", errCode, errMsg);
                    
                    [self setIsInError:true withErrorCode:[NSNumber numberWithInt:errCode] withErrorMessage:[NSString stringWithCString:errMsg encoding:NSASCIIStringEncoding]];
                    
                    success = false;
                }
                
                // reset after every update
                sqlite3_reset(updateStmt);
            }
            
            // reset flags
            [self setNeedsUpdate:false];
            [self setIsNew:false];
        }
        
        // rebuild the current array to clean up deleted items if necessary
        if ([self isScheduledForDelete] == false)
            [workingArray addObject:currentRow];
    }
    
    // reassign the result set with the current working array
    resultSet = workingArray;
    
    // finalize the statements as we rebuild them
    // every save.
    sqlite3_finalize(updateStmt);
    sqlite3_finalize(insertStmt);
    
    return  success;
}

-(NSObject*) loadData:(GameEntityDataStructure*) ds withSQL:(sqlite3_stmt*) sql {
    NSObject* data = nil;
    
    switch (ds.columnAffinityType) {
        case DAT_NONE: {
            const void* v = sqlite3_column_blob(sql, ds.columnIndex);
            data = [[NSData alloc] initWithBytes:v length:sizeof(v)];
        }
            break;
        case DAT_INTEGER:
            data = [[NSNumber alloc] initWithInt: sqlite3_column_int(sql, ds.columnIndex)];
            break;
        case DAT_REAL:
            data = [[NSNumber alloc] initWithDouble: sqlite3_column_double(sql, ds.columnIndex)];
            break;
        case DAT_TEXT:
        case DAT_NUMERIC:
        default:
            data = [NSString stringWithUTF8String: (const char*)sqlite3_column_text(sql, ds.columnIndex)];
            break;
    }
    
    return data;
}

-(void) loadDataWithSet:(NSMutableArray*) results withSQL:(sqlite3_stmt*) sql {
    GameEntityDataStructure* s = nil;
    
    currentRow = [[NSMutableArray alloc] initWithCapacity:[dataStructure count]];
    
    for(s in dataStructure) {
        
        NSObject* data = nil;
        
        // check to see if its the system dirty field, by pass
        // loading data as this is used by the class library.
        if ( s.isSystemField && ([s.columnName isEqual: @"dirty"] || [s.columnName isEqual: @"new"] || [s.columnName isEqual: @"delete"] || [s.columnName isEqual: @"error"] || [s.columnName isEqual: @"error_code"] || [s.columnName isEqual: @"error_msg"])) {
            data = s.defaultValue;
        } else {
            data = [self loadData:s withSQL:sql];
        }
        
        [currentRow addObject:data];
    }
    
    [results addObject:currentRow];
}

-(void) load:(int) entityId {
    if([self doesEntityDefinitionExist]) {
        [self loadWithParameters:[NSArray arrayWithObject: [self createParameter:@"id" withValue:[NSNumber numberWithInt:entityId]]]];
        
        resultSet = [[NSMutableArray alloc] initWithCapacity:1];
        
        int result = SQLITE_OK;
        while ((result = sqlite3_step(selectStmt)) == SQLITE_ROW) {
            [self loadDataWithSet:resultSet withSQL:selectStmt];
            [self first];
        }
        
        sqlite3_reset(selectStmt);
    }
}

-(int) bindParameter:(GameEntityParameter*) param withStatement:(sqlite3_stmt*) sql {
    int result = SQLITE_ERROR;
    
    switch (param.parameterDataType) {
        case DAT_NONE:
            result = sqlite3_bind_blob(sql, sqlite3_bind_parameter_index(sql, [[param parameterName] UTF8String]), [(NSData*)[param paramenterValue] bytes], [(NSData*)[param paramenterValue] length], SQLITE_STATIC);
            break;
        case DAT_REAL:
            result = sqlite3_bind_double(sql, sqlite3_bind_parameter_index(sql, [[param parameterName] UTF8String]), [(NSNumber*)[param paramenterValue] doubleValue]);
            break;
        case DAT_INTEGER:
            result = sqlite3_bind_int(sql, sqlite3_bind_parameter_index(sql, [[param parameterName] UTF8String]), [(NSNumber*)[param paramenterValue] intValue]);
            break;
        case DAT_TEXT:
        case DAT_NUMERIC:
            if([[param paramenterValue] respondsToSelector:@selector(UTF8String)] == true) {
                result = sqlite3_bind_text(sql, sqlite3_bind_parameter_index(sql, [[param parameterName] UTF8String]), [(NSString*)[param paramenterValue] UTF8String], [(NSString*)[param paramenterValue] length], SQLITE_STATIC);
            } else {
                result = sqlite3_bind_text(sql, sqlite3_bind_parameter_index(sql, [[param parameterName] UTF8String]), [[(NSNumber*)[param paramenterValue] stringValue] UTF8String], [[(NSNumber*)[param paramenterValue] stringValue] length], SQLITE_STATIC);
            }
        default:
            break;
    }
    
    return result;
}

-(void) loadWithParameters:(NSArray*) parameters {
    [self buildSelect:parameters];
    
    const char* sql = [select UTF8String];
    
    if (sqlite3_prepare_v2([(GameEntityContainer*)entityContainer db], sql, -1, &selectStmt, NULL) == SQLITE_OK) {
        NSLog(@"Statement prepared successfully.");
        
        GameEntityParameter* param = nil;
        for (param in parameters) {
            [self bindParameter:param withStatement:selectStmt];
        }
    }
    else {
        NSLog(@"Error while attempting to prepare statement. Message: %s", sqlite3_errmsg([(GameEntityContainer*)entityContainer db]));
    }
}

/// schedules the current row to be deleted
-(void) remove {
    if ( currentRow != nil ) {
        [self setIsScheduledForDelete:true];
        [self setNeedsUpdate:true];
        
        NSLog(@"current row: %ld is scheduled to be deleted next save.", [self getRowId].longValue);
    } else {
        NSLog(@"no current row selected. nothing to do.");
    }
}

-(bool) validateAndAttachToEntityContainer {
    return true;
}

-(bool) validateAndAttachToEntityContainerWithId:(id<EntityContainerProtocol>) containerId {
    return true;
}

-(void) clearAndReset {
    sqlite3_finalize(selectStmt);
    sqlite3_finalize(updateStmt);
    sqlite3_finalize(insertStmt);
    sqlite3_finalize(removeStmt);
    
    selectStmt = nil;
    updateStmt = nil;
    insertStmt = nil;
    removeStmt = nil;
}

-(bool) doesExistForEntityId:(int) entityId {
    return true;
}

-(NSString*) debugToString {
    return @"entity: %@, ";
}

-(void) reset {
    currentRow = nil;
    rsEnumerator = nil;
}

-(bool) first {
    currentRow = nil;
    rsEnumerator = nil;
    
    rsEnumerator = [resultSet objectEnumerator];
    if ( rsEnumerator != nil) {
        currentRow = [rsEnumerator nextObject];
    }
    
    return (currentRow != nil);
}

-(bool) next {
    currentRow = nil;
    if (rsEnumerator != nil) {
        currentRow = [rsEnumerator nextObject];
    } else {
        [self first];
    }
    
    return (currentRow != nil);
}

/// this method might be difficult to implement with the current solution
/// if this is needed will re-evaluate
-(bool) previous {
    return true;
}

-(GameEntityParameter*) findParameter:(NSArray*) parameters byName:(NSString*) name {
    GameEntityParameter* param = nil;
    
    GameEntityParameter* w = nil;
    for(w in parameters) {
        if ( [w.columnName compare:name options:NSCaseInsensitiveSearch] == NSOrderedSame ) {
            param = w;
            break;
        }
    }
    
    return param;
}

-(GameEntityDataStructure*) findDataStructure:(int) index {
    GameEntityDataStructure* ds = nil;
    
    for (ds in dataStructure) {
        if ( ds.columnIndex == index ) {
            return ds;
        }
    }
    
    return nil;
}

-(GameEntityDataStructure*) findDataStructureByName:(NSString*) name {
    GameEntityDataStructure* ds = nil;
    
    for (ds in dataStructure) {
        if ( [[[ds columnName] lowercaseString] compare:name options:NSCaseInsensitiveSearch] == NSOrderedSame ) {
            return ds;
        }
    }
    
    return nil;
}

-(void) setNeedsUpdate:(bool) updateValue {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructureByName:@"dirty"];
    if ( ds != nil ) {
        [currentRow replaceObjectAtIndex:ds.columnIndex withObject: ( (updateValue == true) ? @"true":@"false") ];
    }
}

-(bool) needsUpdate {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    bool result = false;
    
    GameEntityDataStructure* ds = [self findDataStructureByName:@"dirty"];
    if ( ds != nil ) {
        result = [[(NSString*)[currentRow objectAtIndex:[ds columnIndex]] lowercaseString] compare:@"true" options:NSCaseInsensitiveSearch] == NSOrderedSame ? true: false;
    }
    
    return result;
}

-(void) setIsNew:(bool) updateValue {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructureByName:@"new"];
    if (ds != nil) {
        [currentRow replaceObjectAtIndex:ds.columnIndex withObject:((updateValue == true) ? @"true":@"false")];
    }
}

/// setIsAuto
/// set true/false if the primary key associated to entity is an auto increment
-(void) setIsAuto:(bool)updateValue {
    primaryKeyAutoIncrement = updateValue;
}

/// isScheduledForDelete
/// returns true if the current row is set to be deleted from the db, false otherwise.
-(bool) isScheduledForDelete {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    bool result = false;
    GameEntityDataStructure* ds = [self findDataStructureByName:@"delete"];
    if ( ds != nil ) {
        result = [[(NSString*)[currentRow objectAtIndex:[ds columnIndex]] lowercaseString] compare:@"true" options:NSCaseInsensitiveSearch] == NSOrderedSame ? true: false;
    }
    
    return result;
}

/// setIsScheduledForDelete
/// sets true/false if the current row should be deleted next save.
-(void) setIsScheduledForDelete:(bool) updateValue {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructureByName:@"delete"];
    if ( ds != nil ) {
        [currentRow replaceObjectAtIndex:ds.columnIndex withObject: ( (updateValue == true) ? @"true":@"false") ];
    }
}

/// isNew
/// Return true if the current data row is a new record otherwise false
-(bool) isNew {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    bool result = false;
    GameEntityDataStructure* ds = [self findDataStructureByName:@"new"];
    if ( ds != nil ) {
        result = [[(NSString*)[currentRow objectAtIndex:[ds columnIndex]] lowercaseString] compare:@"true" options:NSCaseInsensitiveSearch] == NSOrderedSame ? true: false;
    }
    
    return result;
}

/// isAuto
/// Return true if the primary key associated with datastructure is auto incremented otherwise false
-(bool) isAuto {
    return primaryKeyAutoIncrement;
}

/// isInError
/// Return true if the current data row errored last statement update
-(bool) isInError {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    bool result = false;
    GameEntityDataStructure* ds = [self findDataStructureByName:@"error"];
    if ( ds != nil ) {
        result = [[(NSString*)[currentRow objectAtIndex:[ds columnIndex]] lowercaseString] compare:@"true" options:NSCaseInsensitiveSearch] == NSOrderedSame ? true: false;
    }
    
    return result;
}

-(NSNumber*) errorCode {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    NSNumber* code = [NSNumber numberWithInt:0];
    
    GameEntityDataStructure* ds = [self findDataStructureByName:@"error_code"];
    if ( ds != nil ) {
        code = (NSNumber*)[currentRow objectAtIndex:[ds columnIndex]];
    }
    
    return code;
}

-(NSString*) errorMsg {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    NSString* msg = @"";
    
    GameEntityDataStructure* ds = [self findDataStructureByName:@"error_msg"];
    if ( ds != nil ) {
        msg = (NSString*)[currentRow objectAtIndex:[ds columnIndex]];
    }
    
    return msg;
}

/// setIsInError
/// Set the error flag, code and message of the current row
-(void) setIsInError:(bool)updateValue withErrorCode:(NSNumber*)errCode withErrorMessage:(NSString *)errMsg {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructureByName:@"error"];
    if (ds != nil) {
        [currentRow replaceObjectAtIndex:ds.columnIndex withObject:((updateValue == true) ? @"true":@"false")];
        if (updateValue) {
            GameEntityDataStructure* dsErrorCode = [self findDataStructureByName:@"error_code"];
            [currentRow replaceObjectAtIndex:dsErrorCode.columnIndex withObject:errCode];
            
            GameEntityDataStructure* dsErrorMsg = [self findDataStructureByName:@"error_msg"];
            [currentRow replaceObjectAtIndex:dsErrorMsg.columnIndex withObject:errMsg];
        }
    }
}

/// setRowId
/// set the value of the new row id after an insert only.
-(void) setRowId:(NSNumber*) rowId {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructureByName:@"rowid"];
    if (ds != nil) {
        [currentRow replaceObjectAtIndex:ds.columnIndex withObject:rowId];
    }
}

/// getRowId
/// Returns the current row id of the selected row
-(NSNumber*) getRowId {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    NSNumber* value = nil;
    
    GameEntityDataStructure* ds = [self findDataStructureByName:@"rowid"];
    if ( ds != nil ) {
        value = (NSNumber*)[currentRow objectAtIndex:[ds columnIndex]];
    }
    
    return value;
}

#pragma mark Getter/Setter Column Data
/// getValueAtColumnIndex
/// Returns an Object based on the datastructure affinity, this method is to be used for the
/// automatic binding done as part of the save method.
-(NSObject*) getValueAtColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    NSObject* data = nil;
    
    GameEntityDataStructure* ds = [dataStructure objectAtIndex:index];
    
    switch (ds.columnAffinityType) {
        case DAT_NONE:
            data = (NSData*)[currentRow objectAtIndex:index];
            break;
        case DAT_INTEGER:
        case DAT_REAL:
            data = (NSNumber*)[currentRow objectAtIndex:index];
            break;
        case DAT_NUMERIC:
        case DAT_TEXT:
        default:
            data = [currentRow objectAtIndex:index];
            break;
    }
    
    return data;
}

/// getValueAtColumnName
/// Returns an Object based on the datastructure affinity, this method is to be used for the
/// automatic binding done as part of the save method.
-(NSObject*) getValueAtColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    NSObject* data = nil;
    
    GameEntityDataStructure* ds = [self findDataStructureByName:name];
    if ( ds != nil ) {
        data = [self getValueAtColumnIndex:[ds columnIndex]];
    } else
        NSLog(@"column index not found for column: %@", name);
    
    return data;
}

/// getDataAtColumnIndex
/// Returns a NSData object at the current column index for the current data structure. This would include
/// blob objects stored in the database
-(NSData*) getDataAtColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [dataStructure objectAtIndex:index];
    
    NSData* dv = nil;
    
    switch (ds.columnAffinityType) {
        case DAT_NONE:
            dv = (NSData*)[currentRow objectAtIndex:index];
            break;
        default:
            NSLog(@"unable to convert column: %@ to blob.", ds.columnName);
            break;
    }
    
    return dv;
}

/// getDataAtColumnName
/// Returns a NSData object at the current column name for the current data structure.
-(NSData*) getDataAtColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    NSData* data = nil;
    GameEntityDataStructure* ds = [self findDataStructureByName:name];
    if ( ds != nil ) {
        data = [self getDataAtColumnIndex:[ds columnIndex]];
    } else
        NSLog(@"column index not found for column: %@", name);
    
    return data;
}

/// getNumberAtColumnIndex
/// return an NSNumber value of the current row at the column index specified.
-(NSNumber*) getNumberAtColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [dataStructure objectAtIndex:index];
    
    NSNumber* nv = nil;
    
    switch (ds.columnAffinityType) {
        case DAT_INTEGER:
        case DAT_REAL:
            nv = (NSNumber*)[currentRow objectAtIndex:index];
            break;
        default:
            NSLog(@"unable to convert column: %@ to number.", ds.columnName);
            break;
    }
    
    return nv;
}

-(NSNumber*) getNumberAtColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    NSNumber* value = nil;
    GameEntityDataStructure* ds = [self findDataStructureByName:name];
    if ( ds != nil ) {
        value = [self getNumberAtColumnIndex:[ds columnIndex]];
    } else
        NSLog(@"column index not found for column: %@", name);
    
    return value;
}

-(NSNumber*) getNumberAtColumnName:(NSString*) name withDefault:(NSNumber*) defaultNumber {
    NSNumber* d = [self getNumberAtColumnName:name];
    if (d==nil) {
        d = defaultNumber;
    }
    
    return d;
}

-(NSString*) getTextAtColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [dataStructure objectAtIndex:index];
    
    NSString* dv = nil;
    
    switch (ds.columnAffinityType) {
        case DAT_NONE:
            NSLog(@"unable to convert data type none to string for column %@.", ds.columnName);
            break;
        case DAT_INTEGER:
        case DAT_REAL:
            dv = [NSString stringWithString:[(NSNumber*)[currentRow objectAtIndex:index] stringValue]];
            break;
        case DAT_NUMERIC:
        case DAT_TEXT:
        default:
            dv = [currentRow objectAtIndex:index];
            break;
    }
    
    return dv;
}

-(NSString*) getTextAtColumnName:(NSString*) name withDefault:(NSString*) defaultText {
    NSString* d = [self getTextAtColumnName:name];
    if (d==nil) {
        d = defaultText;
    }
    
    return d;
}

-(NSString*) getTextAtColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    NSString* text = nil;
    GameEntityDataStructure* ds = [self findDataStructureByName: name];
    if ( ds != nil ) {
        text = [self getTextAtColumnIndex:(int)[ds columnIndex]];
    }
    else
        NSLog(@"column index not found for column: %@", name);
    
    return text;
}

-(NSDate*) getDateAtColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    NSString* dateConvert = [self getTextAtColumnIndex:index];
    
    NSDateFormatter* dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    return [dateFormat dateFromString:dateConvert];
}

-(NSDate*) getDateAtColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    NSDate* value = nil;
    
    GameEntityDataStructure* ds = [self findDataStructureByName:name];
    if ( ds != nil ) {
        value = [self getDateAtColumnIndex:(int)[ds columnIndex]];
    } else
        NSLog(@"column index not found for column: %@", name);
    
    return value;
}

-(NSDate*) getDateAtColumnName:(NSString*) name withDefault:(NSDate*) defaultDate {
    NSDate* d = [self getDateAtColumnName:name];
    if (d==nil) {
        d = defaultDate;
    }
    
    return d;
}

-(bool) getBoolAtColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [dataStructure objectAtIndex:index];
    
    NSNumber* nv = nil;
    
    switch (ds.columnAffinityType) {
        case DAT_INTEGER:
        case DAT_REAL:
        case DAT_NUMERIC:
            nv = (NSNumber*)[currentRow objectAtIndex:index];
            break;
        default:
            NSLog(@"unable to convert column: %@ to number.", ds.columnName);
            nv = [NSNumber numberWithBool:false];
            break;
    }
    
    return [nv boolValue];
}

-(bool) getBoolAtColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    bool value = false;
    
    GameEntityDataStructure* ds = [self findDataStructureByName:name];
    if ( ds != nil ) {
        value = [self getBoolAtColumnIndex:(int)[ds columnIndex]];
    } else
        NSLog(@"column index not found for column: %@", name);
    
    return value;
}

-(void) setData:(NSData*) data atColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructure:index];
    if ( ds != nil ) {
        NSData* obj = (NSData*)[currentRow objectAtIndex:index];
        
        switch (ds.columnAffinityType) {
            case DAT_NONE:
                obj = data;
                [currentRow replaceObjectAtIndex:index withObject:obj];
                [self setNeedsUpdate:true];
                break;
            case DAT_INTEGER:
            case DAT_REAL:
            case DAT_TEXT:
            case DAT_NUMERIC:
                NSLog(@"unable to set text for integer, real, text,numeric or blob data types.");
            default:
                break;
        }
    }
}

-(void) setData:(NSData*) data atColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructureByName:name];
    if ( ds != nil ) {
        [self setData:data atColumnIndex:(int)[ds columnIndex]];
    } else {
        NSLog(@"column index not found for column: %@", name);
    }
}

-(void) setNumber:(NSNumber*) number atColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructure:index];
    if ( ds != nil ) {
        NSNumber* obj = (NSNumber*)[currentRow objectAtIndex:index];
        
        switch (ds.columnAffinityType) {
            case DAT_NONE:
            case DAT_INTEGER:
            case DAT_REAL:
            case DAT_NUMERIC:
                obj = number;
                [currentRow replaceObjectAtIndex:index withObject:obj];
                [self setNeedsUpdate:true];
                break;
            case DAT_TEXT:
            default:
                NSLog(@"unable to set text for numeric/text");
                break;
        }
    }
}

-(void) setNumber:(NSNumber*) number atColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructureByName:name];
    if ( ds != nil ) {
        [self setNumber:number atColumnIndex:(int)[ds columnIndex]];
    } else {
        NSLog(@"column index not found for column: %@", name);
    }
}

-(void) setText:(NSString*) text atColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructure:index];
    if ( ds != nil ) {
        NSString* obj = [currentRow objectAtIndex:index];
        
        switch (ds.columnAffinityType) {
            case DAT_NONE:
            case DAT_INTEGER:
            case DAT_REAL:
                NSLog(@"unable to set text for integer, real or blob data types.");
                break;
            case DAT_TEXT:
            case DAT_NUMERIC:
                obj = text;
                [currentRow replaceObjectAtIndex:index withObject:obj];
                [self setNeedsUpdate:true];
            default:
                break;
        }
    }
}

-(void) setText:(NSString*) text atColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructureByName:name];
    if ( ds != nil ) {
        [self setText:text atColumnIndex:(int)[ds columnIndex]];
    } else {
        NSLog(@"column index not found for column: %@", name);
    }
}

-(void) setDate:(NSDate*) date atColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSString *dateString = [dateFormat stringFromDate:date];
    
    [self setText:dateString atColumnIndex:index];
}

-(void) setDate:(NSDate*) date atColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructureByName:name];
    if ( ds != nil ) {
        [self setDate:date atColumnIndex:(int)[ds columnIndex]];
    } else {
        NSLog(@"column index not found for column: %@", name);
    }
}

-(void) setBool:(bool) value atColumnIndex:(int) index {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructure:index];
    if ( ds != nil ) {
        NSNumber* obj = nil;
        
        switch (ds.columnAffinityType) {
            case DAT_NONE:
            case DAT_INTEGER:
            case DAT_REAL:
            case DAT_NUMERIC:
                obj = [NSNumber numberWithBool:value];
                [currentRow replaceObjectAtIndex:index withObject:obj];
                [self setNeedsUpdate:true];
                break;
            case DAT_TEXT:
            default:
                NSLog(@"unable to set text for numeric/text");
                break;
        }
    }
}

-(void) setBool:(bool) value atColumnName:(NSString*) name {
    NSAssert(currentRow != nil, @"current row not set, use first or next to traverse to the first row.");
    
    GameEntityDataStructure* ds = [self findDataStructureByName:name];
    if ( ds != nil ) {
        [self setBool:value atColumnIndex:(int)[ds columnIndex]];
    } else {
        NSLog(@"column index not found for column: %@", name);
    }
}

@end
