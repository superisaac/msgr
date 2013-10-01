//
//  MSGRObjectSqliteStorageManager.m
//  AnyTellDemo
//
//  Created by Ke Zeng on 13-7-27.
//  Copyright (c) 2013年 ZengKe. All rights reserved.
//

#import "MSGRObjectSQLiteStore.h"


@implementation MSGRObjectSQLiteStore {
    sqlite3 * _database;
    MSGRUserObject * _user;
    NSCache * _assetCache;
}
@synthesize database=_database;
@synthesize user=_user;
@synthesize assetCache=_assetCache;

- (id)initWithLoginUser:(MSGRUserObject *)user {
    self = [super init];
    if (self) {
        _user = user;
        _assetCache = [[NSCache alloc] init];
        [_assetCache setCountLimit:20];
        
        [self ensureSchema];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"dealloced object store");
    [self closeStore];
}

- (void)closeStore {
    NSLog(@"close object store");
    if (_database) {
        int r = sqlite3_close(_database);
        [self assertDBOperation:r];
        _database = NULL;
    }
}

- (NSURL *)ensurePath:(NSString *)path {
    NSString * lastPathComponent = [path lastPathComponent];
    NSString * directory = [path stringByDeletingLastPathComponent];
    NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentationDirectory, NSUserDomainMask, YES);
    NSString * documentDirectory = paths[0];
    directory = [documentDirectory stringByAppendingPathComponent:directory];
    NSURL * directioryURL = [NSURL fileURLWithPath:directory];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    BOOL isDir;
    if (![fileManager fileExistsAtPath:directory isDirectory:&isDir]) {
        NSError * error;
        [fileManager createDirectoryAtURL:directioryURL withIntermediateDirectories:YES attributes:nil error:&error];
        assert(!error);
    }
    return [directioryURL URLByAppendingPathComponent:lastPathComponent];
}

- (void)saveData:(NSData *)data toAsset:(NSString *)path {
    [data writeToURL:[self assetURLWithPath:path] atomically:YES];
    [_assetCache setObject:data forKey:path];
}

- (NSURL *)assetURLWithPath:(NSString *)path {
    return [self ensurePath:[NSString stringWithFormat:@"messenger/%@/assets/%@", self.user.identifier, path]];
}

- (NSData *)dataFromAssetPath:(NSString *)path {
    NSData * data = [_assetCache objectForKey:path];
    if (data != nil) {
        NSLog(@"got from cache");
        return data;
    }
    
    NSURL * assetURL = [self assetURLWithPath:path];
    NSError * error = nil;
    data = [NSData dataWithContentsOfURL:assetURL options:0 error:&error];
    if (error != nil) {
        NSLog(@"Error on getting assets %@", data);
        return nil;
    }
    [_assetCache setObject:data forKey:path];
    return data;
}

- (void)assertDBOperation:(int)r {
    assert(r == SQLITE_OK);
}

- (BOOL)isTextEmpty:(NSString *)text {
    return text == nil || text.length == 0;
}

- (void)simpleExec:(NSString *)query {
    char * errMsg = NULL;
    int r = sqlite3_exec(_database, [query UTF8String], NULL, NULL, &errMsg);
    if (r != SQLITE_OK) {
        NSLog(@"Error %s", errMsg);
        @throw [NSString stringWithUTF8String:errMsg];
    }
}

- (NSString *)stringOfStatement:(sqlite3_stmt *)stmt index:(int)index {
    char * tmp = (char *)sqlite3_column_text(stmt, index);
    if (tmp == NULL) {
        return nil;
    } else {
        return [NSString stringWithUTF8String:tmp];
    }
}

- (NSData *)dataOfStatement:(sqlite3_stmt *)stmt index:(int)index {
    char * tmp = (char *)sqlite3_column_text(stmt, index);
    if (tmp == NULL) {
        return nil;
    } else {
        return [NSData dataWithBytes:tmp length:strlen(tmp)];
    }
}

- (NSDate *)dateOfStatement:(sqlite3_stmt *)stmt index:(int)index {
    NSTimeInterval timeInterval = sqlite3_column_int(stmt, index);
    return [[NSDate alloc] initWithTimeIntervalSince1970:timeInterval];
}

- (void)stmt:(sqlite3_stmt *)stmt prepareArguments:(NSArray *)args {
    for (NSInteger i=0; i<args.count;i++) {
        id arg = args[i];
        if ([arg isKindOfClass:[NSNull class]]) {
            sqlite3_bind_null(stmt, i+1);
        } else if ([arg isKindOfClass:[NSString class]]) {
            sqlite3_bind_text(stmt, i+1, [(NSString *)arg UTF8String], -1, NULL);
        } else if ([arg isKindOfClass:[NSData class]]) {
            NSData * d = (NSData *)arg;
            sqlite3_bind_text(stmt, i+1, d.bytes, d.length, NULL);
        } else if ([arg isKindOfClass:[NSDate class]]) {
            sqlite3_bind_int(stmt, i+1, (int)[(NSDate *)arg timeIntervalSince1970]);
        } else if ([arg isKindOfClass:[NSNumber class]]) {
            sqlite3_bind_int(stmt, i+1, [arg intValue]);
        } else {
            NSLog(@"illegal argument %@", arg);
            sqlite3_bind_text(stmt, i+1, [[arg stringValue] UTF8String], -1, NULL);
        }
    }
}

- (void)transactionBlock:(void(^)())block {
    [self simpleExec:@"begin transaction"];
    block();
    [self simpleExec:@"commit transaction"];
}

- (void)ensureSchema {
    NSString * path = [NSString stringWithFormat:@"messenger/%@/db.sqlite3", self.user.identifier];
    
    NSURL * pathURL = [self ensurePath:path];
    NSString * pathString = [pathURL absoluteString];
    NSLog(@"db file at %@", pathString);
    int r = sqlite3_open([pathString UTF8String], &_database);
    [self assertDBOperation:r];
    
    // User Table
    [self simpleExec:@"CREATE TABLE IF NOT EXISTS user (identifier VARCHAR(32) PRIMARY KEY, screen_name VARCHAR(32), lastmodified INT);"];
    [self simpleExec:@"CREATE INDEX IF NOT EXISTS user_lm ON user (lastmodified)"];
    
    // Message table
    [self simpleExec:@"CREATE TABLE IF NOT EXISTS message (identifier VARCHAR(32) PRIMARY KEY, state INT, touserid VARCHAR(32), fromuserid VARCHAR(32), peeruserid VARCHAR(32), type VARCHAR(20) default 'text', content TEXT, metadata TEXT, createdat INT, globalid VARCHAR(32));"];
    [self simpleExec:@"CREATE UNIQUE INDEX IF NOT EXISTS message_identifier ON message (identifier)"];
    [self simpleExec:@"CREATE INDEX IF NOT EXISTS message_state ON message(state)"];
    [self simpleExec:@"CREATE INDEX IF NOT EXISTS message_inbox ON message(touserid)"];
    [self simpleExec:@"CREATE INDEX IF NOT EXISTS message_outbox ON message(fromuserid)"];
    [self simpleExec:@"CREATE INDEX IF NOT EXISTS message_peeruser ON message(peeruserid)"];
    [self simpleExec:@"CREATE INDEX IF NOT EXISTS message_created ON message(createdat)"];
    [self simpleExec:@"CREATE INDEX IF NOT EXISTS inbox_created ON message(touserid, createdat)"];
    
    // Conv table
    [self simpleExec:@"CREATE TABLE IF NOT EXISTS conv (userid VARCHAR(32) PRIMARY KEY, lastmsgid VARCHAR(32), unread INT default 0, lastmsgcreated INT);"];
    [self simpleExec:@"CREATE INDEX IF NOT EXISTS conv_lm ON conv (lastmsgcreated)"];
    
    // Version history
    [self simpleExec:@"CREATE TABLE IF NOT EXISTS version(ver INT PRIMARY KEY, date TEXT)"];
    [self simpleExec:@"INSERT OR IGNORE INTO version(ver, date) values(1, datetime())"];
}

// User related methods
- (void)saveUser:(MSGRUserObject *)user {
    char * insertSQL = "REPLACE INTO user(identifier, screen_name, lastmodified) values(?, ?, ?);";
    sqlite3_stmt * stmt = NULL;
    int r = sqlite3_prepare_v2(_database, insertSQL, -1, &stmt, NULL);
    [self assertDBOperation:r];
    [self stmt:stmt prepareArguments:@[user.identifier, user.screenName, user.lastModified]];
    r = sqlite3_step(stmt);
    assert(r==SQLITE_DONE);
    sqlite3_finalize(stmt);
}


- (MSGRUserObject *)userByIdentifier:(NSString *)userIdentifier {
    if ([self isTextEmpty:userIdentifier]) {
        return nil;
    }
    char * querySQL = "SELECT identifier, screen_name, lastmodified FROM user WHERE identifier=? LIMIT 1";
    sqlite3_stmt * stmt = NULL;
    int r = sqlite3_prepare_v2(_database, querySQL, -1, &stmt, NULL);
    [self assertDBOperation:r];
    [self stmt:stmt prepareArguments:@[userIdentifier]];
    
    if (sqlite3_step(stmt) == SQLITE_ROW) {
        MSGRUserObject * user = [[MSGRUserObject alloc] init];
        user.identifier = [self stringOfStatement:stmt index:0];
        user.screenName = [self stringOfStatement:stmt index:1];
        user.lastModified = [self dateOfStatement:stmt index:2];
        sqlite3_finalize(stmt);
        return user;
    }
    sqlite3_finalize(stmt);
    return nil;
}

// Message related methods
- (void)saveMessage:(MSGRMsgObject *)msg {
    char * insertSQL = "REPLACE INTO message(identifier, state, touserid, fromuserid, peeruserid, type, content, metadata, globalid, createdat) values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";
    sqlite3_stmt * stmt = NULL;
    int r = sqlite3_prepare_v2(_database, insertSQL, -1, &stmt, NULL);
    [self assertDBOperation:r];
    
    [self stmt:stmt prepareArguments:@[msg.identifier,
                                        @(msg.msgState),
                                        msg.toUser?msg.toUser.identifier:[NSNull null],
                                        msg.fromUser?msg.fromUser.identifier:[NSNull null],
                                        msg.peerUser?msg.peerUser.identifier:[NSNull null],
                                        msg.msgType,
                                        msg.content,
                                        msg.jsonMetadata?msg.jsonMetadata:[NSNull null],
                                        msg.globalId?msg.globalId:[NSNull null],
                                        msg.dateCreated]];

    r = sqlite3_step(stmt);
    assert(r==SQLITE_DONE);
    
    sqlite3_finalize(stmt);
}

- (NSArray *)msgListByCondition:(NSString *)condition arguments:(NSArray *)arguments orderBy:(NSString *)orderField range:(NSRange)range {
    NSString * querySQL = [NSString stringWithFormat:@"SELECT identifier, state, touserid, fromuserid, type, content, metadata, globalid, createdat FROM message WHERE %@ ORDER BY %@ LIMIT %d OFFSET %d", condition, orderField, range.length, range.location];
    
    sqlite3_stmt * stmt = NULL;
    int r = sqlite3_prepare_v2(_database, [querySQL UTF8String], -1, &stmt, NULL);
    [self assertDBOperation:r];
    [self stmt:stmt prepareArguments:arguments];
    
    NSMutableArray * msgList = [[NSMutableArray alloc] init];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        MSGRMsgObject * msg = [[MSGRMsgObject alloc] init];
        msg.identifier = [self stringOfStatement:stmt index:0];
        msg.msgState = sqlite3_column_int(stmt, 1);
        
        NSString * userId = [self stringOfStatement:stmt index:2];
        if (![self isTextEmpty:userId]) {
            msg.toUser = [self userByIdentifier:userId];
        }        
        userId = [self stringOfStatement:stmt index:3];
        if (![self isTextEmpty:userId]) {
            msg.fromUser = [self userByIdentifier:userId];
        }
        msg.msgType = [self stringOfStatement:stmt index:4];
        msg.content = [self stringOfStatement:stmt index:5];
        msg.jsonMetadata = [self dataOfStatement:stmt index:6];
        msg.globalId = [self stringOfStatement:stmt index:7];
        msg.dateCreated = [self dateOfStatement:stmt index:8];
        [msgList addObject:msg];
    }
    sqlite3_finalize(stmt);
    return msgList;
}

- (MSGRMsgObject *)msgByIdentifier:(NSString *)msgIdentifier {
    if ([self isTextEmpty:msgIdentifier]) {
        return nil;
    }
    NSArray * msgList = [self msgListByCondition:@"identifier = ?" arguments:@[msgIdentifier] orderBy:@"identifier" range:NSMakeRange(0, 1)];
    return [msgList lastObject];
}

// Conv related methods
- (void)saveConv:(MSGRConvObject *)conv selfSend:(BOOL)selfSend {
    char * insertSQL = ("REPLACE INTO conv(userid, lastmsgid, lastmsgcreated, unread) "
                        "VALUES(?, ?, ?, COALESCE((SELECT unread FROM conv WHERE userid=?), 0))");
    sqlite3_stmt * stmt = NULL;
    int r = sqlite3_prepare_v2(_database, insertSQL, -1, &stmt, NULL);
    [self assertDBOperation:r];
    [self stmt:stmt prepareArguments:@[conv.user.identifier,  conv.lastMessage.identifier, conv.lastMessage.dateCreated, conv.user.identifier]];
    r = sqlite3_step(stmt);
    assert(r==SQLITE_DONE);
    sqlite3_finalize(stmt);
    
    if (!selfSend) {
        char * updateSQL = "UPDATE conv SET unread = unread + 1 WHERE userid = ?";
        stmt = NULL;
        r = sqlite3_prepare_v2(_database, updateSQL, -1, &stmt, NULL);
        [self assertDBOperation:r];
        [self stmt:stmt prepareArguments:@[conv.user.identifier]];
        r = sqlite3_step(stmt);
        assert(r==SQLITE_DONE);
        sqlite3_finalize(stmt);
    }
}

- (NSArray *)convListByCondition:(NSString *)condition arguments:(NSArray *)arguments orderBy:(NSString *)orderField range:(NSRange)range {
    NSString * querySQL = [NSString stringWithFormat:@"SELECT userid, lastmsgid, unread FROM conv WHERE %@ ORDER BY %@ LIMIT %d OFFSET %d", condition, orderField, range.length, range.location];

    sqlite3_stmt * stmt = NULL;
    int r = sqlite3_prepare_v2(_database, [querySQL UTF8String], -1, &stmt, NULL);
    [self assertDBOperation:r];
    [self stmt:stmt prepareArguments:arguments];
    
    NSMutableArray * convList = [[NSMutableArray alloc] init];
    while (sqlite3_step(stmt) == SQLITE_ROW) {
        MSGRConvObject * conv = [[MSGRConvObject alloc] init];
        NSString * userId = [self stringOfStatement:stmt index:0];
        conv.user = [self userByIdentifier:userId];

        NSString * lastMsgId = [self stringOfStatement:stmt index:1];
        conv.lastMessage = [self msgByIdentifier:lastMsgId];
        conv.numberOfUnread = sqlite3_column_int(stmt, 2);
        [convList addObject:conv];
    }
    sqlite3_finalize(stmt);
    return convList;
}

// Public methods
- (NSArray *)conversationListWithRange:(NSRange)range {
    NSArray * convList =  [self convListByCondition:@"1" arguments:@[] orderBy:@"lastmsgcreated desc" range:range];
    return convList;
}

- (NSArray *)conversationList {
    return [self conversationListWithRange:NSMakeRange(0, 20)];
}

- (void)addMessage:(MSGRMsgObject *)msg {
    MSGRConvObject * conv = [[MSGRConvObject alloc] init];
    conv.user = msg.peerUser;
    conv.lastMessage = msg;
    
    //[self transactionBlock:^{
        [self saveMessage:msg];
        assert(msg.peerUser);
        [self saveUser:msg.peerUser];
        [self saveConv:conv selfSend:msg.selfSend];
    //}];
}

- (NSArray *)messageListOfUser:(MSGRUserObject *)user range:(NSRange)range {
    NSArray * msgList = [self msgListByCondition:@"peeruserid = ?" arguments:@[user.identifier] orderBy:@"createdat desc" range:range];
    if (range.location == 0) {
        [self clearConvOfUser:user];
    }
    return msgList;
}

- (NSArray *)messageListOfUser:(MSGRUserObject *)user {
    return [self messageListOfUser:user range:NSMakeRange(0, 20)];
}

- (void)clearConvOfUser:(MSGRUserObject *)user {
    char * updateSQL = "UPDATE conv set unread = 0 WHERE userid = ?";
    sqlite3_stmt * stmt = NULL;
    int r = sqlite3_prepare_v2(_database, updateSQL, -1, &stmt, NULL);
    [self assertDBOperation:r];
    [self stmt:stmt prepareArguments:@[user.identifier]];
    r = sqlite3_step(stmt);
    assert(r==SQLITE_DONE);
    sqlite3_finalize(stmt);
}

- (void)clearConv:(MSGRConvObject *)conv {
    char * updateSQL = "UPDATE conv set unread = 0 WHERE userid = ?";
    sqlite3_stmt * stmt = NULL;
    int r = sqlite3_prepare_v2(_database, updateSQL, -1, &stmt, NULL);
    [self assertDBOperation:r];
    [self stmt:stmt prepareArguments:@[conv.user.identifier]];
    r = sqlite3_step(stmt);
    assert(r==SQLITE_DONE);
    sqlite3_finalize(stmt);
}

@end
