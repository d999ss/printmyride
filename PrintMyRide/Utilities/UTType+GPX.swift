import UniformTypeIdentifiers

extension UTType {
    static var gpx: UTType {
        // Fall back to XML if the system doesn't know GPX
        UTType(filenameExtension: "gpx") ?? .xml
    }
}