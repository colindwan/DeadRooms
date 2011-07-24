//
//  MainStage.m
//  Cortez
//
//  Created by COLIN DWAN on 4/12/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// Import the interfaces
#import <UIKit/UIKit.h>
#import "CCTouchDispatcher.h"
#import "MainStage.h"
#import "Math.h"
#import "PathFinder.h"
#import "PathPoint.h"
#import "GameEngine.h"
#import "Character.h"
#import "ConversationOverlay.h"

// MainStage implementation
@implementation MainStage

@synthesize smartFox;
@synthesize appDelegate;

#pragma mark - Initialization

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	MainStage *layer = [[[MainStage alloc] init] autorelease];//[MainStage node];
	
	// add layer as a child to scene
	[scene addChild:layer z:0 tag:MAIN_STAGE_TAG];
	
	// return the scene
	return scene;
}

+(CCScene *)sceneWithMap:(NSString *)mapName :(NSString *)fromMap
{
    NSLog(@"sceneWithMap: %@", mapName);
    
    // 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	MainStage *layer = [[[MainStage alloc] initWithMapName:mapName :fromMap] autorelease];//[MainStage node];
    
	// add layer as a child to scene
	[scene addChild:layer z:0 tag:MAIN_STAGE_TAG];
    
	// return the scene
	return scene;

}

- (id)initWithMapName:(NSString *)mapName :(NSString *)fromMap
{
    // do setup
    // always call "super" init
    // Apple recommends to re-assign "self" with the "super" return value
    if( (self=[super init])) {
        CGSize s = [[CCDirector sharedDirector] winSize];
        
        myFileName = [[NSString alloc] initWithString:mapName];
        
        // Set up the map and player sprite
        [self setupMap:mapName];
        [self setupSprite];
        [self setupTriggers:fromMap];
        [self setupGenerators];
        
        
        // Get the tile size
        CGSize ts = [map tileSize];
        
        // If our map doesn't specify where to start the player, set the player in the middle of our screen
        if (mainChar.mySprite.position.x == 0 && mainChar.mySprite.position.y == 0) {
            mainChar.mySprite.position = ccp(s.width/2-ts.width, s.height/2-ts.height);
        }
        
        CGSize mapSize = map.contentSize;
        CGSize tileSize = map.tileSize;
        int iMaxZ = mapSize.height/tileSize.height;
        int iNewZ = MAX(iMaxZ - (mainChar.mySprite.position.y/tileSize.height), 0);
        [self reorderChild:mainChar.myBatchNode z:iNewZ];
        
        self.isTouchEnabled = YES;
        
        // Set up the path finder
        pathFinder = [[PathFinder alloc] initWithMap:map];
        
        [self didPointOffScreen:mainChar.mySprite.position];
        
        [self schedule:@selector(repositionPlayerZ:)];
        
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        smartFox = [appDelegate smartFox];
        
        CCLabelTTF *label = [CCLabelTTF labelWithString:@"Starting up..." fontName:@"Times New Roman" fontSize:12];
        label.position = ccp(s.width * 0.05, s.height * 0.85);
        label.anchorPoint = ccp(0,0);
        [self addChild:label z:1 tag:NETWORK_STATUS_TEXT];
    }
    return self;
}

// on "init" you need to initialize your instance
// [TODO] - generalize so this is not needed - we should only have to call initWithMapName
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		CGSize s = [[CCDirector sharedDirector] winSize];
        
        // Set up the map and player sprite
        [self setupMap:@"room1.tmx"];
        [self setupSprite];
        [self setupTriggers:nil];
        [self setupGenerators];
        
        // Get the tile size
        CGSize ts = [map tileSize];
        
        // If our map doesn't specify where to start the player, set the player in the middle of our screen
        if (mainChar.mySprite.position.x == 0 && mainChar.mySprite.position.y == 0) {
            mainChar.mySprite.position = ccp(s.width/2-ts.width, s.height/2-ts.height);
        }
        
        CGSize mapSize = map.contentSize;
        CGSize tileSize = map.tileSize;
        int iMaxZ = mapSize.height/tileSize.height;
        int iNewZ = MAX(iMaxZ - ((mainChar.mySprite.position.y - mainChar.mySprite.textureRect.size.height/2)/tileSize.height), 0);
        [self reorderChild:mainChar.myBatchNode z:iNewZ];

                                
        self.isTouchEnabled = YES;
                
        // Set up the path finder
        pathFinder = [[PathFinder alloc] initWithMap:map];
        
        [self didPointOffScreen:mainChar.mySprite.position];
        myFileName = [[NSString alloc] initWithFormat:@"room1.tmx"];
        
        [self schedule:@selector(repositionPlayerZ:)];
        
        appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        smartFox = [appDelegate smartFox];
        
        CCLabelTTF *label = [CCLabelTTF labelWithString:@"Starting up..." fontName:@"Times New Roman" fontSize:12];
        label.position = ccp(s.width * 0.05, s.height * 0.85);
        label.anchorPoint = ccp(0,0);
        [self addChild:label z:1 tag:NETWORK_STATUS_TEXT];
    }
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
    [pathFinder release];
    [triggers release];
    [characters release];
    [myFileName release];
	[super dealloc];
}

- (void)setupMap:(NSString *)mapName
{
    map = [CCTMXTiledMap tiledMapWithTMXFile:mapName];
        
    for (CCSpriteBatchNode* child in [map children]) {
        [[child texture] setAntiAliasTexParameters];
    }
    
    // Add the map to myself (should I do this here or the level higher?)
    [self addChild:map z:-1 tag:MAP_TAG];
}

- (void)setupTriggers:(NSString *)fromMap
{
    CCTMXObjectGroup *group = [map objectGroupNamed:@"triggers"];
    triggers = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in group.objects) {
        
        // if we found our "start" marker, don't bother adding it to the triggers list
        if ([[dict objectForKey:@"type"] isEqualToString:@"start"]) {        
            if (fromMap != nil) {
                // if we have a map we're coming from then we need to find the specific node to start in when appearing
                if (![[dict objectForKey:@"fromMap"] isEqualToString:fromMap])
                    continue;
            }
            // otherwise if this is the first run, ignore all starting positions that are for other maps
            else if ([dict objectForKey:@"fromMap"]) {
                continue;
            }
            mainChar.mySprite.position = ccp([[dict objectForKey:@"x"] intValue], [[dict objectForKey:@"y"] intValue]);
            continue;
        }
        CGRect rect = CGRectMake([[dict objectForKey:@"x"] intValue], 
                                 [[dict objectForKey:@"y"] intValue], 
                                 [[dict objectForKey:@"width"] intValue], 
                                 [[dict objectForKey:@"height"] intValue]);
        NSDictionary *myDict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSValue valueWithCGRect:rect], @"rect",
                                                                            [dict objectForKey:@"prop1"], @"action", nil];
        [triggers addObject:myDict];
        [myDict release];
    }
}

- (void)setupGenerators
{
    CCTMXObjectGroup *group = [map objectGroupNamed:@"tools"];
    characters = [[NSMutableArray alloc] init];
    
    
    CGSize mapSize = map.contentSize;
    CGSize tileSize = map.tileSize;
    int iMaxZ = mapSize.height/tileSize.height;
    
    for (NSDictionary *dict in group.objects) {
        if ([[dict objectForKey:@"type"] isEqualToString:@"generator"])
        {            
            // [CAD] - should I store this in a generic dictionary to support a larger and variable number of attributes?
            //   maybe anything with a prefix "att"?
            NSString *name = [dict objectForKey:@"name"];
            NSString *convo = [dict objectForKey:@"conversation"];
            
            Character *temp = [[Character alloc] initWithDetails:name :convo];
            //[temp setName:name];
            //[temp setConvo:convo];
            temp.mySprite.position = ccp([[dict objectForKey:@"x"] intValue], [[dict objectForKey:@"y"] intValue]);
            [characters addObject:temp];
            int iNewZ = MAX(iMaxZ - ((temp.mySprite.position.y- temp.mySprite.textureRect.size.height/2)/tileSize.height), 0);
            [self addChild:[temp myBatchNode] z:iNewZ];
            [temp release];
        }
    }
    
}

- (void)setupSprite
{    
    mainChar = [[GameEngine sharedGameEngine] player];
    
    // Add the sprite batch node to our scene
    [self addChild:[mainChar myBatchNode]];
    // retain the SpriteBatch since when we replace this view, it'll try to release this element
    [[mainChar myBatchNode] retain];
    // turn the sprite so it faces the camera, otherwise it'll just use whatever frame was last playing when we transitioned
    [mainChar turnSprite];
}

- (void)addPlayer:(NSString *)name
{
    for(Character *character in characters) {
        if ([[character name] isEqualToString:name]) {
            // Already exists
            return;
        }
    }
    
    CGSize mapSize = map.contentSize;
    CGSize tileSize = map.tileSize;
    int iMaxZ = mapSize.height/tileSize.height;
    CGSize s = [[CCDirector sharedDirector] winSize];
    
    // Player doesn't exist yet, set them up and add them to the world
    // [CAD] - this assumes that we've broken up "rooms" appropriately.  Right now the entire world is one big room so this wouldn't work
    Character *newChar = [[Character alloc] init];
    //newChar.name = [[NSString alloc] initWithString:name];
    [newChar setName:name];
    [characters addObject:newChar];
    
    newChar.mySprite.position = ccp(s.width * 0.1, s.height *0.1);
    int iNewZ = MAX(iMaxZ - ((newChar.mySprite.position.y - newChar.mySprite.textureRect.size.height/2)/tileSize.height), 0);
    
    [[newChar mySprite] setColor:ccc3(rand()%255, rand()%255, rand()%255)];
    
    [self addChild:[newChar myBatchNode] z:iNewZ];
    
    [newChar release];
}

- (void)removePlayer:(NSString *)name
{
    for (Character *character in characters) {
        if ([[character name] isEqualToString:name]) {
            [characters removeObject:character];
            [self removeChild:[character myBatchNode] cleanup:YES];
            return;
        }
    }
}

#pragma mark - Touch handlers

- (void)registerWithTouchDispatcher
{
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL)ccTouchBegan:(UITouch *)touch 
           withEvent:(UIEvent *)event
{
    if ([[GameEngine sharedGameEngine] bLock]) {
        return NO;
    }
    return YES;
}

- (void)ccTouchEnded:(UITouch *)touch 
           withEvent:(UIEvent *)event
{
#ifdef NPC_DEBUG
    [self NPCMoveTest:touch :event];
    return;
#endif
    
    // Get our touch information - where did we poke, how far is it, etc?
    CGPoint location = [self convertTouchToNodeSpace:touch];
    bool bEngageNPC = false;
    Character *foundChar = nil;
    CGPoint temp = [self pointInCharacter:location :&foundChar];
    if (!CGPointEqualToPoint(temp, CGPointZero)) {
        location = temp;
        bEngageNPC = true;
    }    
    
    // Figure out if we need to move the screen around
    CCNode *node = self;
    CGSize mapSize = map.contentSize;
    CGSize tileSize;
            
    // Get the tile info that we're clicking on
    CCTMXLayer *layer = [map layerNamed:@"obstacles"];
    tileSize = [map tileSize];
    unsigned int guid;
    NSDictionary *props;
    int iWalkable = 0;
    NSMutableArray *path = NULL;
    
    // Check to see if I could walk to that point
    CGPoint start, end;
    start = ccp((int)(mainChar.mySprite.position.x/tileSize.width), (int)(mainChar.mySprite.position.y/tileSize.height));
    end = ccp((int)(location.x/tileSize.width), (int)(location.y/tileSize.height));
    
    NSArray *results = [[NSArray alloc] initWithArray:stepLine(start, end)];
    for (int i = 0; i < [results count]; i++)
    {
        NSValue *val = [results objectAtIndex:i];
        CGPoint nextPos = [val CGPointValue];
        
        guid = [layer tileGIDAt:ccp((int)nextPos.x, (int)mapSize.height/tileSize.height - (int)nextPos.y-1)];
        props = [map propertiesForGID:guid];
        iWalkable = 0;
        iWalkable = [[props objectForKey:@"walkable"] intValue];
        if (iWalkable < 0){
            path = [pathFinder findPath:start :end];
            break;
        }
    }
    
    if (iWalkable < 0 && !path) {
        return;
    }
    
    float dist = distance(location, mainChar.mySprite.position);
    float time = dist/WALK_VEL;
    
    [node stopAllActions];
    [mainChar.mySprite stopAllActions];
    
    [self didPointOffScreen:location];
    
    if (path && [path count])
    {
        dist = [path count]*tileSize.width;
        time = dist/WALK_VEL;
        float dt = time/[path count];
        PathPoint *temp = [path objectAtIndex:[path count]-2];
        PathPoint *lastPoint;
        id seq = [CCSequence actions:[CCMoveTo actionWithDuration:dt position:ccp((int)temp.pos.x*tileSize.width+tileSize.width/2, (int)temp.pos.y*tileSize.height)], nil];
        id animSeq = [CCSequence actions:(id)[mainChar animateToPoint:mainChar.mySprite.position :ccp((int)temp.pos.x*tileSize.width+tileSize.width/2, (int)temp.pos.y*tileSize.height) :false], nil];
        lastPoint = temp;
        // drop the first two points since they're queued up in our first move, drop the last point b/c it adds 
        //   an extra anim cycle that we don't need
        // [TODO] - clean up the data returned so we don't have to do this janky workarounds
        for (int i = [path count]-3; i >= 1; i--)
        {
            temp = [path objectAtIndex:i];
            
            id move = [CCMoveTo actionWithDuration:dt position:ccp((int)temp.pos.x*tileSize.width+tileSize.width/2, (int)temp.pos.y*tileSize.height)];
            
            seq = [CCSequence actions:seq, move, nil];
            
            id nextAnim = [mainChar animateToPoint:ccp((int)lastPoint.pos.x*tileSize.width+tileSize.width/2, (int)lastPoint.pos.y*tileSize.height) :ccp((int)temp.pos.x*tileSize.width, (int)temp.pos.y*tileSize.height) :false];
            animSeq = [CCSequence actions:animSeq, nextAnim, nil];
            lastPoint = temp;
        }
        seq = [CCSequence actions:seq, [CCCallFunc actionWithTarget:self selector:@selector(pointInTrigger)], nil];
        if (bEngageNPC) {
            //seq = [CCSequence actions:seq, [CCCallFunc actionWithTarget:self selector:@selector(startConvo)], nil];
            //[CCCallFuncND actionWithTarget:self selector:@selector(showStep:data:) data:[optionData objectForKey:@"leads_to"]]
            seq = [CCSequence actions:seq, [CCCallFuncND actionWithTarget:self selector:@selector(startConvo:data:) data:foundChar], nil];
        }
        [mainChar.mySprite runAction:seq];
        [mainChar.mySprite runAction:animSeq];
        [path removeAllObjects];
        //[path release];
        return;
    }
    else
    {
        id seq = [CCSequence actions:[CCMoveTo actionWithDuration:time position:location], [CCCallFunc actionWithTarget:self selector:@selector(pointInTrigger)], nil];
        if (bEngageNPC) {
            //seq = [CCSequence actions:seq, [CCCallFunc actionWithTarget:self selector:@selector(startConvo)], nil];
            //[CCCallFuncND actionWithTarget:self selector:@selector(showStep:data:) data:[optionData objectForKey:@"leads_to"]]
            seq = [CCSequence actions:seq, [CCCallFuncND actionWithTarget:self selector:@selector(startConvo:data:) data:foundChar], nil];

        }
        [mainChar.mySprite runAction:seq];
    }
    
    [mainChar.mySprite runAction:[mainChar animateToPoint:mainChar.mySprite.position :location :true]];
    
    SFSObject *obj = [SFSObject newInstance];
    [obj putUtfString:@"type" value:@"touch"];
    [obj putInt:@"x" value:(int)location.x];
    [obj putInt:@"y" value:(int)location.y];
    
    [smartFox send:[ObjectMessageRequest requestWithObject:obj]];
}

- (void)NPCMoveTest:(UITouch *)touch :(UIEvent *)event
{
    // Get our touch information - where did we poke, how far is it, etc?
    CGPoint location = [self convertTouchToNodeSpace:touch];
        
    // Figure out if we need to move the screen around
    CCNode *node = self;
    CGSize mapSize = map.contentSize;
    CGSize tileSize;
    
    // Get the tile info that we're clicking on
    CCTMXLayer *layer = [map layerNamed:@"obstacles"];
    tileSize = [map tileSize];
    unsigned int guid;
    NSDictionary *props;
    int iWalkable = 0;
    NSMutableArray *path = NULL;
    
    // [CAD] - just grab the NPC at the top of the list and walk him around.
    Character *pNPC = [characters objectAtIndex:0];
    
    // [CAD] - When we're doing this for real, just have the other frontend tell us whether it's a
    //          straight shot or if we need to path.  For now we'll have to brute force it
    // Check to see if I could walk to that point
    CGPoint start, end;
    start = ccp((int)(pNPC.mySprite.position.x/tileSize.width), (int)(pNPC.mySprite.position.y/tileSize.height));
    end = ccp((int)(location.x/tileSize.width), (int)(location.y/tileSize.height));
    
    NSArray *results = [[NSArray alloc] initWithArray:stepLine(start, end)];
    for (int i = 0; i < [results count]; i++)
    {
        NSValue *val = [results objectAtIndex:i];
        CGPoint nextPos = [val CGPointValue];
        
        guid = [layer tileGIDAt:ccp((int)nextPos.x, (int)mapSize.height/tileSize.height - (int)nextPos.y-1)];
        props = [map propertiesForGID:guid];
        iWalkable = 0;
        iWalkable = [[props objectForKey:@"walkable"] intValue];
        if (iWalkable < 0){
            path = [pathFinder findPath:start :end];
            break;
        }
    }
    
    if (iWalkable < 0 && !path) {
        return;
    }
    
    float dist = distance(location, pNPC.mySprite.position);
    float time = dist/WALK_VEL;
    
    [node stopAllActions];
    [pNPC.mySprite stopAllActions];
    
    //[self didPointOffScreen:location];
    
    if (path && [path count])
    {
        dist = [path count]*tileSize.width;
        time = dist/WALK_VEL;
        float dt = time/[path count];
        PathPoint *temp = [path objectAtIndex:[path count]-2];
        PathPoint *lastPoint;
        id seq = [CCSequence actions:[CCMoveTo actionWithDuration:dt position:ccp((int)temp.pos.x*tileSize.width+tileSize.width/2, (int)temp.pos.y*tileSize.height)], nil];
        id animSeq = [CCSequence actions:(id)[pNPC animateToPoint:pNPC.mySprite.position :ccp((int)temp.pos.x*tileSize.width+tileSize.width/2, (int)temp.pos.y*tileSize.height) :false], nil];
        lastPoint = temp;
        // drop the first two points since they're queued up in our first move, drop the last point b/c it adds 
        //   an extra anim cycle that we don't need
        // [TODO] - clean up the data returned so we don't have to do this janky workarounds
        for (int i = [path count]-3; i >= 1; i--)
        {
            temp = [path objectAtIndex:i];
            
            id move = [CCMoveTo actionWithDuration:dt position:ccp((int)temp.pos.x*tileSize.width+tileSize.width/2, (int)temp.pos.y*tileSize.height)];
            
            seq = [CCSequence actions:seq, move, nil];
            
            id nextAnim = [pNPC animateToPoint:ccp((int)lastPoint.pos.x*tileSize.width+tileSize.width/2, (int)lastPoint.pos.y*tileSize.height) :ccp((int)temp.pos.x*tileSize.width, (int)temp.pos.y*tileSize.height) :false];
            animSeq = [CCSequence actions:animSeq, nextAnim, nil];
            lastPoint = temp;
        }
        seq = [CCSequence actions:seq, [CCCallFunc actionWithTarget:self selector:@selector(pointInTrigger)], nil];
        [pNPC.mySprite runAction:seq];
        [pNPC.mySprite runAction:animSeq];
        [path removeAllObjects];
        //[path release];
        return;
    }
    else
    {
        id seq = [CCSequence actions:[CCMoveTo actionWithDuration:time position:location], [CCCallFunc actionWithTarget:self selector:@selector(pointInTrigger)], nil];
        [pNPC.mySprite runAction:seq];
    }
    
    [pNPC.mySprite runAction:[pNPC animateToPoint:pNPC.mySprite.position :location :true]];
}

- (void)MoveCharacter:(NSString *)name :(CGPoint)location
{    
    // Figure out if we need to move the screen around
    CCNode *node = self;
    CGSize mapSize = map.contentSize;
    CGSize tileSize;
    
    // Get the tile info that we're clicking on
    CCTMXLayer *layer = [map layerNamed:@"obstacles"];
    tileSize = [map tileSize];
    unsigned int guid;
    NSDictionary *props;
    int iWalkable = 0;
    NSMutableArray *path = NULL;
    
    // [CAD] - just grab the NPC at the top of the list and walk him around.
    Character *pNPC;
    pNPC = [self getCharacterByName:name];
    if (pNPC == nil) {
        pNPC = [characters objectAtIndex:0];
    }
    
    // [CAD] - When we're doing this for real, just have the other frontend tell us whether it's a
    //          straight shot or if we need to path.  For now we'll have to brute force it
    // Check to see if I could walk to that point
    CGPoint start, end;
    start = ccp((int)(pNPC.mySprite.position.x/tileSize.width), (int)(pNPC.mySprite.position.y/tileSize.height));
    end = ccp((int)(location.x/tileSize.width), (int)(location.y/tileSize.height));
    
    NSArray *results = [[NSArray alloc] initWithArray:stepLine(start, end)];
    for (int i = 0; i < [results count]; i++)
    {
        NSValue *val = [results objectAtIndex:i];
        CGPoint nextPos = [val CGPointValue];
        
        guid = [layer tileGIDAt:ccp((int)nextPos.x, (int)mapSize.height/tileSize.height - (int)nextPos.y-1)];
        props = [map propertiesForGID:guid];
        iWalkable = 0;
        iWalkable = [[props objectForKey:@"walkable"] intValue];
        if (iWalkable < 0){
            path = [pathFinder findPath:start :end];
            break;
        }
    }
    
    if (iWalkable < 0 && !path) {
        return;
    }
    
    float dist = distance(location, pNPC.mySprite.position);
    float time = dist/WALK_VEL;
    
    [node stopAllActions];
    [pNPC.mySprite stopAllActions];
    
    //[self didPointOffScreen:location];
    
    if (path && [path count])
    {
        dist = [path count]*tileSize.width;
        time = dist/WALK_VEL;
        float dt = time/[path count];
        PathPoint *temp = [path objectAtIndex:[path count]-2];
        PathPoint *lastPoint;
        id seq = [CCSequence actions:[CCMoveTo actionWithDuration:dt position:ccp((int)temp.pos.x*tileSize.width+tileSize.width/2, (int)temp.pos.y*tileSize.height)], nil];
        id animSeq = [CCSequence actions:(id)[pNPC animateToPoint:pNPC.mySprite.position :ccp((int)temp.pos.x*tileSize.width+tileSize.width/2, (int)temp.pos.y*tileSize.height) :false], nil];
        lastPoint = temp;
        // drop the first two points since they're queued up in our first move, drop the last point b/c it adds 
        //   an extra anim cycle that we don't need
        // [TODO] - clean up the data returned so we don't have to do this janky workarounds
        for (int i = [path count]-3; i >= 1; i--)
        {
            temp = [path objectAtIndex:i];
            
            id move = [CCMoveTo actionWithDuration:dt position:ccp((int)temp.pos.x*tileSize.width+tileSize.width/2, (int)temp.pos.y*tileSize.height)];
            
            seq = [CCSequence actions:seq, move, nil];
            
            id nextAnim = [pNPC animateToPoint:ccp((int)lastPoint.pos.x*tileSize.width+tileSize.width/2, (int)lastPoint.pos.y*tileSize.height) :ccp((int)temp.pos.x*tileSize.width, (int)temp.pos.y*tileSize.height) :false];
            animSeq = [CCSequence actions:animSeq, nextAnim, nil];
            lastPoint = temp;
        }
        seq = [CCSequence actions:seq, [CCCallFunc actionWithTarget:self selector:@selector(pointInTrigger)], nil];
        [pNPC.mySprite runAction:seq];
        [pNPC.mySprite runAction:animSeq];
        [path removeAllObjects];
        //[path release];
        return;
    }
    else
    {
        id seq = [CCSequence actions:[CCMoveTo actionWithDuration:time position:location], [CCCallFunc actionWithTarget:self selector:@selector(pointInTrigger)], nil];
        [pNPC.mySprite runAction:seq];
    }
    
    [pNPC.mySprite runAction:[pNPC animateToPoint:pNPC.mySprite.position :location :true]];
}

#pragma mark - Screen moving

- (void)didPointOffScreen:(CGPoint)tap
{
    // Figure out if we need to move the screen around
    // precalc some of the important numbers (not neccesarily for effiency, just for ease of reading)
    bool bMoveScreen = NO;
    CGPoint diff;
    float fBuffer = 0.15f;      // how much of a buffer region do we want around the edge of the screen?
    CCNode *node = self;
    CGPoint currentPos = ccpNeg([node positionInPixels]);
    CGSize screen = [[CCDirector sharedDirector] winSizeInPixels];
    CGSize mapSize = map.contentSizeInPixels;
    int iUpperY = currentPos.y+(screen.height*(1.0f-fBuffer));
    int iLowerY = currentPos.y+(screen.height*fBuffer);
    int iUpperX = currentPos.x+(screen.width*(1.0f-fBuffer));
    int iLowerX = currentPos.x+(screen.width*fBuffer);
    
    int destx, desty;
    
    destx = 0;
    desty = 0;
    // are we walking off the edge?
    // if so, try to recenter the screen
    // [TODO] - put these screen movements into a series of queued actions to match other movement, return in a dictionary
    if (tap.x > iUpperX)
    {
        //diff = ccpSub(ccp(-currentPos.x+screen.width/2, tap.y), tap);
        destx = tap.x - (currentPos.x + screen.width/2);
        //if (currentPos.x > mapSize.width - screen.width/2)
        //    destx = currentPos.x;
        
        if (tap.x + screen.width/2 > mapSize.width)
            destx = (mapSize.width - screen.width) - currentPos.x;
        
        bMoveScreen = YES;
    }
    else if (tap.x < iLowerX)
    {
        destx = tap.x- (currentPos.x + screen.width/2);
        if (currentPos.x < screen.width/2)
            destx = -currentPos.x;
        
        bMoveScreen = YES;
    }
    // If we're going to walk near the top edge, recenter the screen
    if (tap.y > iUpperY)
    {
        desty = tap.y - (currentPos.y + screen.height/2);
        if (tap.y + screen.height/2 > mapSize.height)
            desty = (mapSize.height - screen.height) - currentPos.y;
        
        bMoveScreen = YES;
    }  
    // are we walking off the edge?
    else if (tap.y < iLowerY)
    {        
        desty = tap.y - (currentPos.y + screen.height/2);
        if (currentPos.y < screen.height/2)
        {
            desty = -currentPos.y;
        }
        bMoveScreen = YES;
    }     
    
    if (bMoveScreen)
        diff = ccp(-destx, -desty);//ccpSub(ccp(destx, desty), currentPos);
    
    // if we actually walked towards the edge, move
    if (bMoveScreen)
    {
        // [CAD] - added a magic number of 2.0 to slow down the screen movement slower than the character walk speed
        //          this was to help it feel like the camera is trailing the character and give the character time to walk
        //          around odd obstacles that might get in the way
        float time = 2.0*(WALK_LOOP_TIME * distance(CGPointZero, diff))/WALK_VEL;
        [node runAction:[CCMoveBy actionWithDuration:time position:diff]];
    }
}

-(void) repositionPlayerZ:(ccTime)dt
{
	CGSize mapSize = map.contentSize;
    CGSize tileSize = map.tileSize;
    int iMaxZ = mapSize.height/tileSize.height;
    int iNewZ = MAX(iMaxZ - ((mainChar.mySprite.position.y )/tileSize.height), 0);
    [self reorderChild:mainChar.myBatchNode z:iNewZ];
}

#pragma mark - Triggers

- (bool)pointInTrigger
{
    CGPoint p0 = mainChar.mySprite.position;
    for (int i = 0; i < [triggers count]; i++)
    {
        NSDictionary *thisDict = [[NSDictionary alloc] initWithDictionary:[triggers objectAtIndex:i]];
        CGRect rect = [[thisDict objectForKey:@"rect"] CGRectValue];
        if (p0.x < rect.origin.x || p0.y < rect.origin.y || p0.x > rect.origin.x+rect.size.width || p0.y > rect.origin.y+rect.size.height) {
            [thisDict release];
            continue;
        }
        [self removeAllChildrenWithCleanup:YES];
        [self unschedule:@selector(repositionPlayerZ:)];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionCrossFade transitionWithDuration:0.5f 
                                                                                          scene:[MainStage sceneWithMap:[thisDict objectForKey:@"action"] :myFileName]]];
        return true;
    }
    return false;
}

#pragma mark - Character interaction

- (CGPoint)pointInCharacter:(CGPoint)p0 :(Character **)foundChar
{
//    CGPoint p0 = mainChar.mySprite.position;
    for (int i = 0; i < [characters count]; i++)
    {
        Character *tempChar = [characters objectAtIndex:i];
        CGRect rect = [[tempChar mySprite] boundingBox];

        // Artificially increase size of clickable area by 10%
        rect.origin.x -= rect.size.width*0.05;
        rect.origin.y -= rect.size.height*0.05;
        rect.size.width *= 1.10;
        rect.size.height *= 1.10;
        if (p0.x < rect.origin.x || p0.y < rect.origin.y || p0.x > rect.origin.x+rect.size.width || p0.y > rect.origin.y+rect.size.height) {
            continue;
        }
        CGPoint newPoint;
        // If we clicked on one, lock in our destination to stand right next to the character
        // [TODO] - need to check if this position might be in a wall.  For now, don't place an NPC directly against a wall :)
        if (mainChar.mySprite.position.x < rect.origin.x)
            newPoint = ccp(rect.origin.x - rect.size.width*.5, rect.origin.y);
        else
            newPoint = ccp(rect.origin.x + rect.size.width*1.5, rect.origin.y);
        
        *foundChar = tempChar;
        
        return newPoint;

    }
    return CGPointZero;
}

// NOTE - this assumes unique names so will just return the first valid match (probably not a great long term idea)
// [TODO] - add a truly UniqueId to search on
- (Character *)getCharacterByName:(NSString *)name
{
    for (Character *temp in characters) {
        if ([[temp name] isEqualToString:name]) {
            return temp;
        }
    }
    return nil;
}

//- (void)showStep:(id)node data:(void *)stepLabel
- (void)startConvo:(id)node data:(void *)aWho
{
    Character *aNPC = aWho;
    ConversationOverlay *overlay;
    if (!([aNPC conversation])) {
        overlay = [[ConversationOverlay alloc] initWithConvo:@"default_convo.plist"];
    }
    else {
        overlay = [[ConversationOverlay alloc] initWithConvo:[aNPC conversation]];
    }
    [overlay setPosition:ccp(-[self position].x, -[self position].y)];
    [self addChild:overlay z:100 tag:CONVO_TAG];
}

/*
- (void)startConvo
{
    // [TODO] - set up convo based on who I clicked on
    ConversationOverlay *overlay = [[ConversationOverlay alloc] initWithConvo:@"conversation_test.plist"];
    [self addChild:overlay z:100 tag:CONVO_TAG];
}
 */

- (void)cleanupConvo
{
    [self removeChildByTag:CONVO_TAG cleanup:YES];
}


#pragma mark - Network

- (void)createGame
{
    NSLog(@"Creating game...");
    CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:99];
    [label setString:@"Creating game..."];
    
    RoomSettings *settings = [RoomSettings settingsWithName:@"testGame"];
    settings.password = @"";
    settings.groupId = @"game";
    settings.isGame = YES;
    settings.maxUsers = 20;
    settings.maxSpectators = 20;
    
    [smartFox send:[CreateRoomRequest requestWithRoomSettings:settings autoJoin:YES roomToLeave:smartFox.lastJoinedRoom]];
}

- (void)onLogin:(SFSEvent *)evt
{
    NSLog(@"onLogin - Stage");

    CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:NETWORK_STATUS_TEXT];
    [label setString:@"Connected!"];
    
    [self createGame];
}

- (void)onRoomJoin:(SFSEvent *)evt
{
    SFSRoom *room = [evt.params objectForKey:@"room"];
    if (![room isGame])
    {
        NSLog(@"Not yet game");
        return;
    }
    
    for(SFSUser *usr in [smartFox.lastJoinedRoom userList]) {
        if (![usr isItMe]) {
            [self addPlayer:[usr name]];
        }
    }
    
    CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:NETWORK_STATUS_TEXT];
    [label setString:@"Joined Game"];
}

- (void)onObjectMessage:(SFSEvent *)evt
{
    NSLog(@"onObjectReceived");
    
    SFSObject *obj = [evt.params objectForKey:@"message"];
    NSLog(@"Got object: %@", [obj getUtfString:@"type"]);
    if ([[obj getUtfString:@"type"] isEqualToString:@"touch"]) {
        NSInteger x = [obj getInt:@"x"];
        NSInteger y = [obj getInt:@"y"];
        NSLog(@"Received touch update: %d, %d by %@", x, y, [[evt.params objectForKey:@"sender"] name]);
        
        
        CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:NETWORK_STATUS_TEXT];
        [label setString:[NSString stringWithFormat:@"%@ Touched: %d %d", [[evt.params objectForKey:@"sender"] name], x, y]];
        
        [self MoveCharacter:[[evt.params objectForKey:@"sender"] name] :CGPointMake(x, y)];
    }
}

- (void)onRoomCreationError:(SFSEvent *)evt
{
    NSLog(@"onRoomCreationError");
    
    // HACK
    // We couldn't create the game room so it must already exist.  Just join it instead
    [smartFox send:[JoinRoomRequest requestWithId:@"testGame" pass:@"" roomIdToLeave:[NSNumber numberWithInt:[smartFox.lastJoinedRoom id]] asSpect:NO]];
}

/**
 * Packet format:
 *      room = "[Room: testGame, Id: 40, GroupId: game]";
 *      user = "[User: GuestUser#99, Id: 99, isMe: NO]";
 */
- (void)onUserEnterRoom:(SFSEvent *)evt
{        
    SFSUser *usr = [evt.params objectForKey:@"user"];
    if (![usr isItMe]) {
        [self addPlayer:[usr name]];
    }
    
    CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:NETWORK_STATUS_TEXT];
//    [label setString:[NSString stringWithFormat:@"User joined: %@", [[smartFox.lastJoinedRoom userList] objectAtIndex:[[smartFox.lastJoinedRoom userList] count]-1]]];
    [label setString:[NSString stringWithFormat:@"User joined: %@", usr]];
}

/**
 * Packet format:
 *      room = "[Room: The Lobby, Id: 2, GroupId: default]";
 *      user = "[User: GuestUser#139, Id: 139, isMe: NO]";
 */
- (void)onUserExitRoom:(SFSEvent *)evt
{
    SFSUser *usr = [evt.params objectForKey:@"user"];
    NSLog(@"Packet Check: %@", [evt params]);
    NSLog(@"User leaving: %@", usr);
    
    if (![usr isItMe]) {
        [self removePlayer:[usr name]];
    }
    
    CCLabelTTF *label = (CCLabelTTF *)[self getChildByTag:NETWORK_STATUS_TEXT];
    [label setString:[NSString stringWithFormat:@"User exited: %@", usr]];
}

@end
