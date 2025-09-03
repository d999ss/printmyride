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

/// The "alpine_climb" asset catalog image resource.
static NSString * const ACImageNameAlpineClimb AC_SWIFT_PRIVATE = @"alpine_climb";

/// The "city_night_ride" asset catalog image resource.
static NSString * const ACImageNameCityNightRide AC_SWIFT_PRIVATE = @"city_night_ride";

/// The "coastal_sprint" asset catalog image resource.
static NSString * const ACImageNameCoastalSprint AC_SWIFT_PRIVATE = @"coastal_sprint";

/// The "forest_switchbacks" asset catalog image resource.
static NSString * const ACImageNameForestSwitchbacks AC_SWIFT_PRIVATE = @"forest_switchbacks";

/// The "poster_placeholder" asset catalog image resource.
static NSString * const ACImageNamePosterPlaceholder AC_SWIFT_PRIVATE = @"poster_placeholder";

#undef AC_SWIFT_PRIVATE
