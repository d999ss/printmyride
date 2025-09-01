#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"d999ss.PrintMyRide";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "Art of the Journey 1" asset catalog image resource.
static NSString * const ACImageNameArtOfTheJourney1 AC_SWIFT_PRIVATE = @"Art of the Journey 1";

/// The "PMR Logo" asset catalog image resource.
static NSString * const ACImageNamePMRLogo AC_SWIFT_PRIVATE = @"PMR Logo";

#undef AC_SWIFT_PRIVATE
