import Foundation

struct ShippingAddress: Codable, Equatable {
    var fullName: String = ""
    var line1: String = ""
    var line2: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
    var country: String = "United States"
}