//
//  HelloWorldLayer.h
//  Empty Cocos Project
//
//  Created by COLIN DWAN on 4/18/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

// HelloWorldLayer
@interface ConversationOverlay : CCLayer
{
    NSDictionary *convo;
    CCMenu *menu;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

- (id)initWithConvo:(NSString *)convoName;

- (void)setupConvo:(NSString *)filename;
- (void)lockConvo;
- (void)doSomething:(CCMenuItem *)menuItem;
- (void)unlockConvo:(CCMenuItem *)menuItem;

- (void)showStep:(id)node data:(void *)stepLabel;


// Tags
#define NPC_TEXT    1
#define PC_TEXT     2
#define MENU        3
@end
