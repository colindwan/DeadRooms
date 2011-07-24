//
//  HelloWorldLayer.h
//  Cortez
//
//  Created by COLIN DWAN on 4/12/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

#import "SmartFoxiPhoneClient.h"
#import "ISFSEvents.h"
#import "AppDelegate.h"

@class PathFinder;
@class Character;

// Main Stage
@interface MainStage : CCLayer <ISFSEvents>
{
    CCTMXTiledMap *map;
    
    PathFinder *pathFinder;
    
    NSMutableArray *triggers;
    
    NSString *myFileName;
    
    NSMutableArray *characters;
    
    Character *mainChar;
    
    int iState;
    
    SmartFoxiPhoneClient *smartFox;
    AppDelegate *appDelegate;
}

@property (nonatomic, retain) SmartFoxiPhoneClient *smartFox;
@property (nonatomic, retain) AppDelegate *appDelegate;

#define MAP_TAG             1
#define CONVO_TAG           2
#define MAIN_STAGE_TAG      99  // this is so we can find ourself from the appdelegate and send network mesasages back down

#define NETWORK_STATUS_TEXT 100 // CCLabelTTF so I can write out network status

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;
+(CCScene *) sceneWithMap:(NSString *)mapName :(NSString *)fromMap;

// Initialization
- (id)initWithMapName:(NSString *)mapName :(NSString *)fromMap;
- (void)setupMap:(NSString *)mapName;
- (void)setupTriggers:(NSString *)fromMap;
- (void)setupGenerators;

- (void)setupSprite;

// Screen moving
- (void)didPointOffScreen:(CGPoint)tap;
- (void)repositionPlayerZ:(ccTime)dt;

// Triggers
- (bool)pointInTrigger;
- (CGPoint)pointInCharacter:(CGPoint)p0 :(Character **)foundChar;
- (Character *)getCharacterByName:(NSString *)name;

- (void)cleanupConvo;

// Debug
- (void)NPCMoveTest:(UITouch *)touch :(UIEvent *)event;
- (void)MoveCharacter:(NSString *)name :(CGPoint)location;

// Multiplayer stuff
- (void)addPlayer:(NSString *)name;
- (void)removePlayer:(NSString *)name;

@end
