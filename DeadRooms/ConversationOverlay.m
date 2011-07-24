//
//  HelloWorldLayer.m
//  Empty Cocos Project
//
//  Created by COLIN DWAN on 4/18/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//


// Import the interfaces
#import "ConversationOverlay.h"
#import "GameEngine.h"
#import "MainStage.h"

// HelloWorldLayer implementation
@implementation ConversationOverlay

+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	ConversationOverlay *layer = [ConversationOverlay node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

-(id) initWithConvo:(NSString *)convoName
{
    if( (self=[super init])) {
        
        // setup convo with filename passed
        [self setupConvo:convoName];
        //add overlay sprite
        CGSize s = [[CCDirector sharedDirector] winSize];
        CCSprite *leftNav = [CCSprite spriteWithFile:@"sidebar.png"];
        // set the anchor to the top right so we can position easier
        [leftNav setAnchorPoint:ccp(1,1)];
        [leftNav setPosition:ccp(s.width, s.height)];
        // scale down to whatever resolution needed - asset is built to iphone4 specs
        [leftNav setScale:s.height/leftNav.contentSize.height];
        [self addChild:leftNav z:1];
    }
    return self;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init])) {
		[self setupConvo:@"conversation_test.plist"];
        // add overlay sprite
        CGSize s = [[CCDirector sharedDirector] winSize];
        CCSprite *leftNav = [CCSprite spriteWithFile:@"sidebar.png"];
        [leftNav setAnchorPoint:ccp(1,1)];
        leftNav.position = ccp(s.width, s.height);
        [leftNav setScale:s.height/leftNav.contentSize.height];
        [self addChild:leftNav z:1];
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
	[super dealloc];
}

#pragma mark - Drawing

void ccFillPoly( CGPoint *poli, int points, BOOL closePolygon )
{
    // Default GL states: GL_TEXTURE_2D, GL_VERTEX_ARRAY, GL_COLOR_ARRAY, GL_TEXTURE_COORD_ARRAY
    // Needed states: GL_VERTEX_ARRAY,
    // Unneeded states: GL_TEXTURE_2D, GL_TEXTURE_COORD_ARRAY, GL_COLOR_ARRAY
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);

    glVertexPointer(2, GL_FLOAT, 0, poli);
    if( closePolygon )
        glDrawArrays(GL_TRIANGLE_FAN, 0, points);
    else
        glDrawArrays(GL_LINE_STRIP, 0, points);

    // restore default state
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);
}

-(void) draw
{
	CGSize s = [[CCDirector sharedDirector] winSize];
    
	// closed grey poly
	glColor4ub(0, 0, 0, 150);
	CGPoint vertices2[] = { ccp(s.width*0.15,0), ccp(s.width*0.15,s.height*0.25), ccp(s.width*0.85,s.height*0.25), ccp(s.width*0.85,0) };
        
    ccFillPoly( vertices2, 4, YES);
}

#pragma mark - Conversations

- (void)setupConvo:(NSString *)filename
{    
    [self lockConvo];
    NSString *path = [CCFileUtils fullPathFromRelativePath:filename];
    NSDictionary *parentDict = [NSDictionary dictionaryWithContentsOfFile:path];
    convo = [parentDict objectForKey:@"first_convo"];
    [convo retain];
    [self showStep:nil data:@"0"];
}

- (void)lockConvo
{
    if (!([[GameEngine sharedGameEngine] lockNode:self])) {
        NSLog(@"We tried to lock the convo on top of another one!");
        abort();
    }
}

- (void)unlockConvo:(CCMenuItem *)menuItem
{
    [[GameEngine sharedGameEngine] unlockNode:self];
    [self removeChild:menu cleanup:YES];
    
    // [CAD] - this works but is janky - I should be able to pass whoever called me a message that I'm done without caring what kind of class it was
    [(MainStage *)[self parent] cleanupConvo];
}

- (void)doSomething:(CCMenuItem *)menuItem
{
    NSDictionary *optionData = [menuItem userData];
    
    [self removeChildByTag:PC_TEXT cleanup:YES];
    CGSize s = [[CCDirector sharedDirector] winSize];
    NSString *greeting = [NSString stringWithString:[optionData objectForKey:@"response_text"]];
    CCLabelTTF *greetingLabel = [CCLabelTTF labelWithString:greeting fontName:@"Times New Roman" fontSize:18];
    [greetingLabel setColor:ccc3(255, 255, 255)];
    greetingLabel.position = ccp(s.width*0.50, s.height*0.22);
    
    // queue up a sequence of move down, fade out, and call the next function
    [self removeChildByTag:NPC_TEXT cleanup:YES];
    id moveDown = [CCMoveBy actionWithDuration:1.5 position:ccp(0, -s.height*0.06)];
    id fadeout = [CCFadeOut actionWithDuration:2];
    id moveAndFade = [CCSpawn actions:moveDown, fadeout, nil];
    id showNext = [CCCallFuncND actionWithTarget:self selector:@selector(showStep:data:) data:[optionData objectForKey:@"leads_to"]];
    id seq = [CCSequence actions:moveAndFade, showNext, nil];
    
    [self addChild:greetingLabel z:2 tag:PC_TEXT];
    
    [greetingLabel runAction:seq];
}

- (void)showStep:(id)node data:(void *)stepLabel
{
    [self removeChild:menu cleanup:YES];
    NSDictionary *stepDict = [convo objectForKey:stepLabel];
    CGSize s = [[CCDirector sharedDirector] winSize];
    
    NSString *greeting = [NSString stringWithString:[stepDict objectForKey:@"greeting"]];
    CCLabelTTF *greetingLabel = [CCLabelTTF labelWithString:greeting fontName:@"Times New Roman" fontSize:18];
    [greetingLabel setColor:ccc3(255, 50, 255)];
    greetingLabel.position = ccp(s.width*0.50, s.height*0.22);
    [self addChild:greetingLabel z:2 tag:NPC_TEXT];
    
    NSString *immediateAction = [stepDict objectForKey:@"action"];
    if ([immediateAction length]) {
        if ([immediateAction isEqualToString:@"exit"]) {
            CCMenuItemImage *menuItem = [CCMenuItemImage itemFromNormalImage:@"btn_exit.png" 
                                                               selectedImage:@"btn_exit_down.png" 
                                                                      target:self 
                                                                    selector:@selector(unlockConvo:)];
            menu = [CCMenu menuWithItems:menuItem, nil];
            [menu setPosition:ccp(s.width*0.90, s.height*0.5)];
            [self addChild:menu z:2 tag:MENU];
            return;
        }
    }
    
    menu = [CCMenu menuWithItems:nil];
    [menu setPosition:ccp(s.width*0.90, s.height*0.5)];
    [self addChild:menu z:2 tag:MENU];
    int i = 1;
    for (NSString *optionName in stepDict)
    {
        if (!([optionName hasSuffix:@"response"])) {
            continue;
        }
        NSDictionary *optionDict = [stepDict objectForKey:optionName];
        NSString *optionText = [optionDict objectForKey:@"text"];
        NSString *btnName;
        // [CAD] - set this up in a config file so we don't have to do this hacky workaround.
        //      Ideally we would have a list of response types and their corresponding icons
        if ([optionName isEqualToString:@"inquiry_response"]) {
            btnName = [NSString stringWithFormat:@"btn_info"];
        }
        else if ([optionName isEqualToString:@"nice_response"]) {
            btnName = [NSString stringWithFormat:@"btn_nice"];
        }
        else if ([optionName isEqualToString:@"mean_response"]) {
            btnName = [NSString stringWithFormat:@"btn_mean"];
        }
        else {
            NSLog(@"Bad response type - no available button icon!");
        }
        CCMenuItemImage *menuItem = [CCMenuItemImage itemFromNormalImage:[NSString stringWithFormat:@"%@.png", btnName]
                                                           selectedImage:[NSString stringWithFormat:@"%@_down.png", btnName]
                                                                  target:self 
                                                                selector:@selector(doSomething:)];
        NSDictionary *optionData = [NSDictionary dictionaryWithObjectsAndKeys:[optionDict objectForKey:@"leads_to"], @"leads_to", optionText, @"response_text", nil];
        [menuItem setUserData:optionData];
        [optionData retain];
        i++;
        [menu addChild:menuItem];        
    }
    [menu alignItemsVerticallyWithPadding:s.height/5.0];
}

@end
