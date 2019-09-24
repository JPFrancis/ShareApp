#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import "GoogleMaps/GoogleMaps.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
    [GMSServices provideAPIKey:@"AIzaSyC5ci_OyNLg6wcqWJUPPmdNleCvOHQbWD0"];
    [application registerForRemoteNotifications];
    
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
@end
