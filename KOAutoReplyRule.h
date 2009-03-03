//
//  KOAutoReplyRule.h
//  MacBlueTelnet
//
//  Created by K.O.ed on 08-5-9.
//  Copyright 2008 Welly Group. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct {
	NSString *callerName;
	NSString *messageContent;
} Message;

typedef enum {
	EQUAL, CONTAIN, STARTWITH, MATCH
} Operator;

typedef enum {
	IGNORE, REPLY
} Response;

typedef struct {
	Operator op;
	NSString *rightValue;
} Condition;

typedef struct {
	Response res;
	NSString *replyString;
} Rule;

@interface KOAutoReplyRule : NSObject {
	Condition _sender;
	Condition _message;
	Rule _rule;
}

- (bool) matches : (Message) message;
- (NSString *) getReply : (Message) message;

@end
