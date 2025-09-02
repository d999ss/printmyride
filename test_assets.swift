import UIKit

// Test loading the placeholder images we just added
print("🧪 Testing asset loading...")

let testImages = ["alpine_climb", "forest_switchbacks", "coastal_sprint", "city_night_ride", "poster_placeholder"]

for imageName in testImages {
    if let image = UIImage(named: imageName) {
        print("✅ \(imageName): \(image.size)")
    } else {
        print("❌ \(imageName): Failed to load")
    }
}