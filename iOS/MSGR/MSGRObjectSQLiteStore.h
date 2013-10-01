//
//  MSGRObjectSqliteStorageManager.h
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-27.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "MSGRObjectStore.h"

@interface MSGRObjectSQLiteStore : MSGRObjectStore

@property (nonatomic) sqlite3 * database;
@property (nonatomic, strong) MSGRUserObject * user;
@property (nonatomic, strong) NSCache * assetCache;

- (id)initWithLoginUser:(MSGRUserObject *)user;
@end
