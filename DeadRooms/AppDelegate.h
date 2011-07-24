//
//  AppDelegate.h
//  Cortez
//
//  Created by COLIN DWAN on 4/12/11.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ISFSEvents.h"

@class RootViewController;
@class SmartFoxiPhoneClient;

@interface AppDelegate : NSObject <UIApplicationDelegate, ISFSEvents> {
	UIWindow			*window;
	RootViewController	*viewController;
    
    SmartFoxiPhoneClient *smartFox;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) SmartFoxiPhoneClient *smartFox;

- (void)login:(NSString *)loginName;

@end
