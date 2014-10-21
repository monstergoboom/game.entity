//
//  GameEntity.h
//  SingleDeck
//
//  Created by Alek Mitrevski on 3/30/12.
//  Copyright (c) 2012 MonsterGoBOOM!, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "EntityProtocol.h"
#import "GameEntityParameter.h"

@interface GameEntity : NSObject<EntityProtocol> {
    
    // container reference 
    id<EntityContainerProtocol> entityContainer;	
    
    // entity reference 
    NSString* entityName;
    
    // allows to load single data objects 
    NSNumber* gameEntityId;
    
    NSMutableString* create;
    NSMutableString* drop;
    NSMutableString* select;
    NSMutableString* insert;
    NSMutableString* update;
    NSMutableString* remove;
    
    NSMutableArray* dataStructure;
    
    sqlite3_stmt* createStmt;
    sqlite3_stmt* dropStmt;
    sqlite3_stmt* selectStmt;
    sqlite3_stmt* insertStmt;
    sqlite3_stmt* updateStmt;
    sqlite3_stmt* removeStmt;
    
    // result set
    NSMutableArray* resultSet;
    NSEnumerator* rsEnumerator;
    
    NSMutableArray* currentRow;
    
    bool primaryKeyAutoIncrement;
    bool doesEntityDefinitionExist;
}

@property (nonatomic, assign, readonly) bool doesEntityDefinitionExist;
@property (nonatomic, assign, readonly) bool primaryKeyAutoIncrement;

// Construction
-(id) init:(id<EntityContainerProtocol>)container withEntityReferenceName:(NSString*) name;
-(id) init:(id<EntityContainerProtocol>)container withEntityReferenceName:(NSString*) name andEntity:(int)entityId;

-(void) loadEntityDataStructure;
-(void) loadEntityDataStructure:(NSString*) name;

-(void) buildCreateTable:(NSArray*) definition;
-(void) buildDropTable;
-(void) buildSelect:(NSArray*) parameters;
-(void) buildInsert;
-(void) buildUpdate:(NSArray*) parameters;
-(void) buildRemove:(NSArray*) parameters;

-(void) checkAutoIncrementKey;

-(GameEntityParameter*) createParameter:(NSString*) columnName withValue:(NSObject*) value;
-(void) createEntityRecord;
-(void) createEntityDefinition:(NSArray*) definition;
-(void) removeEntityDefinition;

// Selection
-(void) loadWithParameters:(NSArray*) parameters;

// Navigation
-(bool) first;
-(bool) next;
-(bool) previous;
-(void) reset;

// Data Retrieval
-(NSNumber*) getRowId;
-(void) setRowId:(NSNumber*) rowId;
-(bool) needsUpdate;
-(bool) isNew;
-(bool) isAuto;
-(bool) isScheduledForDelete;
-(bool) isInError;
-(NSNumber*) errorCode;
-(NSString*) errorMsg;
-(void) setNeedsUpdate:(bool) updateValue;
-(void) setIsNew:(bool) updateValue;
-(void) setIsAuto:(bool) updateValue;
-(void) setIsScheduledForDelete:(bool) updateValue;
-(void) setIsInError:(bool) updateValue withErrorCode:(NSNumber*) errCode withErrorMessage:(NSString*) errMsg;
-(long) count;

-(NSObject*) getValueAtColumnIndex:(int) index;
-(NSObject*) getValueAtColumnName:(NSString*) name;
-(NSData*) getDataAtColumnIndex:(int) index;
-(NSData*) getDataAtColumnName:(NSString*) name;
-(NSNumber*) getNumberAtColumnIndex:(int) index;
-(NSNumber*) getNumberAtColumnName:(NSString*) name;
-(NSNumber*) getNumberAtColumnName:(NSString*) name withDefault:(NSNumber*) defaultNumber;
-(NSString*) getTextAtColumnIndex:(int) index;
-(NSString*) getTextAtColumnName:(NSString*) name;
-(NSString*) getTextAtColumnName:(NSString*) name withDefault:(NSString*) defaultText;
-(NSDate*) getDateAtColumnIndex:(int) index;
-(NSDate*) getDateAtColumnName:(NSString*) name;
-(NSDate*) getDateAtColumnName:(NSString*) name withDefault:(NSDate*) defaultDate;
-(bool) getBoolAtColumnIndex:(int) index;
-(bool) getBoolAtColumnName:(NSString*) name;

// Data Set
-(void) setData:(NSData*) data atColumnIndex:(int) index;
-(void) setData:(NSData*) data atColumnName:(NSString*) name;
-(void) setNumber:(NSNumber*) number atColumnIndex:(int) index;
-(void) setNumber:(NSNumber*) number atColumnName:(NSString*) name;
-(void) setText:(NSString*) text atColumnIndex:(int) index;
-(void) setText:(NSString*) text atColumnName:(NSString*) name;
-(void) setDate:(NSDate*) date atColumnIndex:(int) index;
-(void) setDate:(NSDate*) date atColumnName:(NSString*) name;
-(void) setBool:(bool) value atColumnIndex:(int) index;
-(void) setBool:(bool) value atColumnName:(NSString*) name;

@end
