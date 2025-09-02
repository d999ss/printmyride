import CoreLocation

enum DefaultLabels {
    static let scotland: [PlaceLabel] = [
        .init(text:"Scone",         coordinate: .init(latitude:56.421, longitude:-3.438)),
        .init(text:"Dunkeld",       coordinate: .init(latitude:56.565, longitude:-3.583)),
        .init(text:"Blairgowrie",   coordinate: .init(latitude:56.589, longitude:-3.340)),
        .init(text:"Amulree",       coordinate: .init(latitude:56.482, longitude:-3.846)),
        .init(text:"Crieff",        coordinate: .init(latitude:56.372, longitude:-3.839)),
        .init(text:"Bridge of Earn",coordinate: .init(latitude:56.342, longitude:-3.404)),
        .init(text:"Coupar Angus",  coordinate: .init(latitude:56.548, longitude:-3.268)),
    ]
    
    static let sanFrancisco: [PlaceLabel] = [
        .init(text:"Golden Gate Park", coordinate: .init(latitude:37.7694, longitude:-122.4862)),
        .init(text:"Presidio",         coordinate: .init(latitude:37.7989, longitude:-122.4662)),
        .init(text:"Ocean Beach",      coordinate: .init(latitude:37.7599, longitude:-122.5107)),
        .init(text:"Lands End",        coordinate: .init(latitude:37.7855, longitude:-122.5058)),
        .init(text:"Baker Beach",      coordinate: .init(latitude:37.7936, longitude:-122.4836)),
    ]
}