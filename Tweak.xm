#import <LocalAuthentication/LocalAuthentication.h>
@class CAFilter, SBAppSwitcherReusableSnapshotView, SBSwitcherSnapshotImageView, NCNotificationAction, SBIconView, SBIcon, NCNotificationRequest;

@class BBContent;
@interface BBContent : NSObject
@property (nonatomic,retain) NSString * title;
@property (nonatomic,retain) NSString * message;
@end

@interface SBApplication : NSObject
-(NSString *)bundleIdentifier;
@end

@interface SBIconView : NSObject
@property (nonatomic,retain) SBIcon * icon;
@end

@interface SBIcon : NSObject
-(id)applicationBundleID;
@end


@interface SBAppLayout : NSObject
-(void)getAppId;
@property (nonatomic,copy) NSDictionary * rolesToLayoutItemsMap;
@end

@interface FBProcessState : NSObject
-(int)visibility;
@end

@interface CAFilter : NSObject
+(instancetype)filterWithName:(NSString *)name;
@end

@interface NCNotificationAction : NSObject
@property (nonatomic,readonly) BOOL requiresAuthentication;
@property (nonatomic,readonly) unsigned long long behavior;
@property (nonatomic,copy,readonly) NSString * identifier;
@end

@interface BBBulletin : NSObject
@property (nonatomic,copy) NSString * sectionID;
@property (nonatomic,copy,readonly) NSString * title;
@end

@interface NCBulletinActionRunner : NSObject
@property (nonatomic,readonly) BBBulletin * bulletin;
@end

@interface SBSwitcherSnapshotImageView : UIView
@end

@interface SBAppSwitcherReusableSnapshotView
@property (nonatomic,retain) SBAppLayout * appLayout;
@end



static NSUserDefaults *prefs;
BOOL enabled;
NSString *switcherAppId;
SBAppLayout *lay;

//Loads prefs
static void loadPrefs() {
	prefs = [[NSUserDefaults alloc] initWithSuiteName:@"com.karimo299.betterprotec"];
	enabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;
}

// this should be the 3d touch on icons but im having trouble atm

// BOOL shouldGo;
// %hook SBUIAppIconForceTouchController
// +(id)filteredApplicationShortcutItemsWithStaticApplicationShortcutItems:(id)arg1 dynamicApplicationShortcutItems:(id)arg2 {
// 	LAContext *myContext = [[LAContext alloc] init];
// 	NSError *authError = nil;
// 	NSString *myLocalizedReasonString = @"Authenticate To Enter The Application";
// 	// self = %orig;
// 	NSLog(@"hi");
// 		if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&authError]) {
// 				[myContext evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:myLocalizedReasonString reply:^(BOOL success) {
// 						if (success) {
// 							shouldGo = YES;
// 							NSLog(@"YEs");
// 							return %orig;
// 						} else {
// 							shouldGo = NO;
// 							NSLog(@"No");
// 							return %orig;
// 						}
// 				}];
// 	}
// 	return %orig;
// }
// %end

//Clicking on the icon
%hook SBUIController
-(void)launchIcon:(SBApplication *)arg1 fromLocation:(long long)arg2 context:(id)arg3 activationSettings:(id)arg4 actions:(id)arg5 {
	LAContext *myContext = [[LAContext alloc] init];
	NSError *authError = nil;
	NSString *myLocalizedReasonString = @"Authenticate To Enter The Application";
  if ([[prefs valueForKey:[NSString stringWithFormat:@"LockedApps-%@", MSHookIvar<SBApplication*>(arg1,"_application").bundleIdentifier]] boolValue]) {
  	if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&authError]) {
  		dispatch_async(dispatch_get_main_queue(), ^{
  			[myContext evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:myLocalizedReasonString reply:^(BOOL success, NSError *error) {
  					if (success) {
              dispatch_async(dispatch_get_main_queue(), ^{
  						%orig;
  						});
  					} else {
  						NSLog(@"No");
  					}
  			}];
  	 });
   } else {
    dispatch_async(dispatch_get_main_queue(), ^{
      UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"BetterProtec" message:@"TouchID/FaceID is not setup on this device" preferredStyle:UIAlertControllerStyleAlert];
      [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        %orig;
      }]];
      [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:YES completion:^{}];
    });
   }
  } else {
    %orig;
  }
}
%end

//Clicking on notif
/////Fix on the lockscreen///////
%hook NCBulletinActionRunner
-(void)executeAction:(NCNotificationAction *)arg1 fromOrigin:(id)arg2 withParameters:(id)arg3 completion:(/*^block*/id)arg4{
	NSLog(@"%@", arg1.identifier);
	LAContext *myContext = [[LAContext alloc] init];
	NSError *authError = nil;
	NSString *myLocalizedReasonString = @"Authenticate To Enter The Application";
  if ([[prefs valueForKey:[NSString stringWithFormat:@"LockedApps-%@", self.bulletin.sectionID]] boolValue] && [arg1.identifier isEqual:@"com.apple.UNNotificationDefaultActionIdentifier"]) {
    if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&authError]) {
        [myContext evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:myLocalizedReasonString reply:^(BOOL success, NSError *error) {
            if (success) {
              return %orig(arg1,arg2,arg3,nil);
            } else {
              NSLog(@"No");
            }
        }];
   } else {
       UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"BetterProtec" message:@"TouchID/FaceID is not setup on this device" preferredStyle:UIAlertControllerStyleAlert];
       [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         return %orig(arg1,arg2,arg3,nil);
       }]];
       [[[[UIApplication sharedApplication] keyWindow] rootViewController] presentViewController:alertController animated:YES completion:^{}];
  }
 } else {
   %orig;
 }
}
%end

//Change text of notif
%hook BBBulletin
-(void)setContent:(BBContent *)arg1 {
 if ([[prefs valueForKey:[NSString stringWithFormat:@"LockedApps-%@", self.sectionID]] boolValue]) {
	 arg1.title = @"BetterProtec";
	 arg1.message = @"This Application is Protected";
}
	%orig;
}
%end

//Blur appSwitcher
%hook SBAppSwitcherReusableSnapshotView
-(void)setAppLayout:(SBAppLayout *)arg1 {
  lay = arg1;
  NSArray *jsonArray = [lay.rolesToLayoutItemsMap allValues];
  NSDictionary *firstObjectDict = [jsonArray objectAtIndex:0];
  switcherAppId = [firstObjectDict valueForKey:@"displayIdentifier"];
  if ([[prefs valueForKey:[NSString stringWithFormat:@"LockedApps-%@", switcherAppId]] boolValue]) {
    CAFilter *filter = [CAFilter filterWithName:@"gaussianBlur"];
    [filter setValue:@20 forKey:@"inputRadius"];
    MSHookIvar<SBSwitcherSnapshotImageView *>(self,"_firstImageView").layer.filters = [NSArray arrayWithObject:filter];
  } else {
    MSHookIvar<SBSwitcherSnapshotImageView *>(self,"_firstImageView").layer.filters = nil;
  }
	%orig;
}
%end

//
// %hook PLExpandedPlatterView
// -(void)setInterfaceActions:(NSArray *)arg1 {
// 	NSLog(@"hi");
// 	LAContext *myContext = [[LAContext alloc] init];
// 	NSError *authError = nil;
// 	NSString *myLocalizedReasonString = @"Authenticate To Enter The Application";
// 	if ([myContext canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&authError]) {
// 		[myContext evaluatePolicy:LAPolicyDeviceOwnerAuthentication localizedReason:myLocalizedReasonString reply:^(BOOL success, NSError *error) {
// 			if (success) {
// 				%orig;
// 			} else {
// 				// %orig;
// 				NSLog(@"No");
// 			}
// 		}];
//  	}
// }
// %end

%ctor {
    CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(), NULL,
		(CFNotificationCallback)loadPrefs,
		CFSTR("com.karimo299.betterprotec/prefChanged"), NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPrefs();
}
