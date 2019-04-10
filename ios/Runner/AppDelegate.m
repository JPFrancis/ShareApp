#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"

@import Firebase;
@import GoogleMaps;
@import GooglePlaces;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
    if(![FIRApp defaultApp]){
        [FIRApp configure];}
    
    [GMSServices provideAPIKey:@"AIzaSyC5ci_OyNLg6wcqWJUPPmdNleCvOHQbWD0"];
    [GMSPlacesClient provideAPIKey:@"AIzaSyC5ci_OyNLg6wcqWJUPPmdNleCvOHQbWD0"];
    
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
