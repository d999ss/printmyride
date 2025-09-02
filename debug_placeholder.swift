import UIKit

// Quick test to see if our placeholder images can be loaded
print("🧪 Testing placeholder image loading...")

// Test 1: Can we load alpine_climb directly?
if let alpine = UIImage(named: "alpine_climb") {
    print("✅ alpine_climb loaded successfully: \(alpine.size)")
} else {
    print("❌ alpine_climb failed to load")
}

// Test 2: Can we load poster_placeholder?
if let placeholder = UIImage(named: "poster_placeholder") {
    print("✅ poster_placeholder loaded successfully: \(placeholder.size)")
} else {
    print("❌ poster_placeholder failed to load")
}

// Test 3: List all available images in bundle
print("📦 Available images in bundle:")
if let infoPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
   let info = NSDictionary(contentsOfFile: infoPath) {
    print("Bundle loaded")
}