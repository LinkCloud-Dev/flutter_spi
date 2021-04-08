#import "FlutterSpiPlugin.h"
#if __has_include(<flutter_spi/flutter_spi-Swift.h>)
#import <flutter_spi/flutter_spi-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "flutter_spi-Swift.h"
#endif

@implementation FlutterSpiPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFlutterSpiPlugin registerWithRegistrar:registrar];
}
@end
