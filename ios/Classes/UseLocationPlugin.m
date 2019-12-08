#import "UseLocationPlugin.h"
#import <use_location/use_location-Swift.h>

@implementation UseLocationPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftUseLocationPlugin registerWithRegistrar:registrar];
}
@end
