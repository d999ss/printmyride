// PrintMyRide/Services/Export/HighResolutionExporter.swift
import UIKit
import PDFKit
import os.log

/// High-resolution export service supporting multiple formats and resolutions
final class HighResolutionExporter {
    // MARK: - Configuration
    enum ExportFormat: CaseIterable {
        case png4K      // 3840×5120 PNG
        case png8K      // 7680×10240 PNG
        case pdf        // Vector PDF
        case svg        // SVG (vector)
        case jpeg       // High quality JPEG
        
        var displayName: String {
            switch self {
            case .png4K: return "4K PNG (3840×5120)"
            case .png8K: return "8K PNG (7680×10240)"
            case .pdf: return "PDF (Vector)"
            case .svg: return "SVG (Vector)"
            case .jpeg: return "High Quality JPEG"
            }
        }
        
        var resolution: CGSize {
            switch self {
            case .png4K: return CGSize(width: 3840, height: 5120)
            case .png8K: return CGSize(width: 7680, height: 10240)
            case .pdf, .svg: return CGSize(width: 2400, height: 3200) // Base size for vectors
            case .jpeg: return CGSize(width: 3840, height: 5120)
            }
        }
        
        var fileExtension: String {
            switch self {
            case .png4K, .png8K: return "png"
            case .pdf: return "pdf"
            case .svg: return "svg"
            case .jpeg: return "jpg"
            }
        }
    }
    
    struct ExportOptions {
        let format: ExportFormat
        let includeMetadata: Bool
        let backgroundTransparent: Bool
        let compressionQuality: CGFloat // For JPEG
        let embedFonts: Bool // For PDF/SVG
        
        static let standard = ExportOptions(
            format: .png4K,
            includeMetadata: true,
            backgroundTransparent: false,
            compressionQuality: 0.95,
            embedFonts: true
        )
        
        static let printReady = ExportOptions(
            format: .pdf,
            includeMetadata: true,
            backgroundTransparent: false,
            compressionQuality: 1.0,
            embedFonts: true
        )
    }
    
    // MARK: - Properties
    private let logger = Logger(subsystem: "PMR", category: "HiResExport")
    private let renderService: EnhancedPosterRenderServiceProtocol
    
    init(renderService: EnhancedPosterRenderServiceProtocol = EnhancedPosterRenderServiceFactory.create()) {
        self.renderService = renderService
    }
    
    // MARK: - Main Export Method
    func exportPoster(
        request: PosterRenderRequest,
        options: ExportOptions,
        progressCallback: @escaping (Double) -> Void = { _ in }
    ) async throws -> ExportResult {
        
        logger.info("Starting high-resolution export: \(options.format.displayName)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        progressCallback(0.1)
        
        // Prepare high-resolution render request
        let hiResRequest = PosterRenderRequest(
            preset: request.preset,
            rideData: request.rideData,
            canvasSize: options.format.resolution,
            useMapBackground: request.useMapBackground,
            mapStyle: request.mapStyle,
            useOptimizedRenderer: true
        )
        
        progressCallback(0.2)
        
        // Generate high-resolution image
        let hiResImage = try await renderService.renderPoster(request: hiResRequest)
        
        progressCallback(0.6)
        
        // Export in requested format
        let exportData: Data
        let mimeType: String
        
        switch options.format {
        case .png4K, .png8K:
            exportData = try await exportPNG(image: hiResImage, options: options)
            mimeType = "image/png"
            
        case .jpeg:
            exportData = try await exportJPEG(image: hiResImage, options: options)
            mimeType = "image/jpeg"
            
        case .pdf:
            exportData = try await exportPDF(image: hiResImage, request: hiResRequest, options: options)
            mimeType = "application/pdf"
            
        case .svg:
            exportData = try await exportSVG(request: hiResRequest, options: options)
            mimeType = "image/svg+xml"
        }
        
        progressCallback(0.9)
        
        // Create temporary file
        let tempURL = try createTemporaryFile(data: exportData, format: options.format)
        
        progressCallback(1.0)
        
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("Export completed in \(duration, format: .fixed(precision: 2))s")
        
        return ExportResult(
            fileURL: tempURL,
            format: options.format,
            fileSize: exportData.count,
            resolution: options.format.resolution,
            mimeType: mimeType,
            duration: duration
        )
    }
    
    // MARK: - Format-Specific Export Methods
    private func exportPNG(image: UIImage, options: ExportOptions) async throws -> Data {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let pngData = image.pngData() else {
                    continuation.resume(throwing: ExportError.dataConversionFailed)
                    return
                }
                
                if options.includeMetadata {
                    // Add metadata to PNG
                    let dataWithMetadata = self.addMetadataToPNG(data: pngData, image: image)
                    continuation.resume(returning: dataWithMetadata)
                } else {
                    continuation.resume(returning: pngData)
                }
            }
        }
    }
    
    private func exportJPEG(image: UIImage, options: ExportOptions) async throws -> Data {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                guard let jpegData = image.jpegData(compressionQuality: options.compressionQuality) else {
                    continuation.resume(throwing: ExportError.dataConversionFailed)
                    return
                }
                
                if options.includeMetadata {
                    // Add EXIF metadata to JPEG
                    let dataWithMetadata = self.addMetadataToJPEG(data: jpegData, image: image)
                    continuation.resume(returning: dataWithMetadata)
                } else {
                    continuation.resume(returning: jpegData)
                }
            }
        }
    }
    
    private func exportPDF(
        image: UIImage,
        request: PosterRenderRequest,
        options: ExportOptions
    ) async throws -> Data {
        
        let pdfDocument = PDFDocument()
        
        // Create PDF page
        let pageRect = CGRect(origin: .zero, size: options.format.resolution)
        let page = PDFPage()
        
        // Render vector content if possible, otherwise embed raster
        if let vectorPDF = await renderVectorPDF(request: request, pageRect: pageRect, options: options) {
            return vectorPDF
        } else {
            // Fallback: embed raster image
            page.setBounds(pageRect, for: .mediaBox)
            
            let renderer = UIGraphicsImageRenderer(size: pageRect.size)
            let pdfImage = renderer.image { context in
                image.draw(in: pageRect)
                
                if options.includeMetadata {
                    addPDFMetadata(to: context, request: request)
                }
            }
            
            if let pdfPage = PDFPage(image: pdfImage) {
                pdfDocument.insert(pdfPage, at: 0)
            }
        }
        
        return pdfDocument.dataRepresentation() ?? Data()
    }
    
    private func exportSVG(
        request: PosterRenderRequest,
        options: ExportOptions
    ) async throws -> Data {
        
        // Generate SVG content
        let svgContent = await renderSVGContent(request: request, options: options)
        
        guard let svgData = svgContent.data(using: .utf8) else {
            throw ExportError.svgGenerationFailed
        }
        
        return svgData
    }
    
    // MARK: - Vector Rendering
    private func renderVectorPDF(
        request: PosterRenderRequest,
        pageRect: CGRect,
        options: ExportOptions
    ) async -> Data? {
        
        // This would integrate with Core Graphics to create true vector PDF
        let renderer = UIGraphicsImageRenderer(size: pageRect.size)
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let pdfData = NSMutableData()
                
                UIGraphicsBeginPDFDataConsumer(pdfData, pageRect, [
                    kCGPDFContextTitle as String: "PrintMyRide Poster",
                    kCGPDFContextAuthor as String: "PrintMyRide",
                    kCGPDFContextCreator as String: "PrintMyRide iOS App"
                ])
                
                UIGraphicsBeginPDFPage()
                
                if let context = UIGraphicsGetCurrentContext() {
                    // Render vector elements
                    self.renderVectorElements(
                        context: context,
                        request: request,
                        rect: pageRect
                    )
                }
                
                UIGraphicsEndPDFContext()
                
                continuation.resume(returning: pdfData as Data)
            }
        }
    }
    
    private func renderVectorElements(
        context: CGContext,
        request: PosterRenderRequest,
        rect: CGRect
    ) {
        
        // Background
        context.setFillColor(UIColor(request.preset.backgroundColor).cgColor)
        context.fill(rect)
        
        // Route path as vector
        if !request.rideData.coordinates.isEmpty {
            let path = createVectorPath(from: request.rideData.coordinates, in: rect)
            
            context.setStrokeColor(UIColor(request.preset.routeColor).cgColor)
            context.setLineWidth(request.preset.strokeWidth)
            context.setLineCap(.round)
            context.setLineJoin(.round)
            
            if request.preset.hasShadow {
                context.setShadow(
                    offset: CGSize(width: 2, height: 2),
                    blur: 4,
                    color: UIColor.black.withAlphaComponent(0.3).cgColor
                )
            }
            
            context.addPath(path)
            context.strokePath()
        }
        
        // Text elements as vectors
        renderVectorText(
            context: context,
            request: request,
            rect: rect
        )
    }
    
    private func createVectorPath(
        from coordinates: [CLLocationCoordinate2D],
        in rect: CGRect
    ) -> CGPath {
        
        let path = CGMutablePath()
        
        guard !coordinates.isEmpty else { return path }
        
        // Convert coordinates to CGPoints in rect
        let bounds = coordinates.boundingRect()
        let scale = min(rect.width / bounds.width, rect.height / bounds.height) * 0.8
        let offsetX = (rect.width - bounds.width * scale) / 2
        let offsetY = (rect.height - bounds.height * scale) / 2
        
        let points = coordinates.map { coord in
            let point = MKMapPoint(coord)
            return CGPoint(
                x: offsetX + (point.x - bounds.minX) * scale,
                y: offsetY + (point.y - bounds.minY) * scale
            )
        }
        
        if let firstPoint = points.first {
            path.move(to: firstPoint)
            points.dropFirst().forEach { path.addLine(to: $0) }
        }
        
        return path
    }
    
    private func renderVectorText(
        context: CGContext,
        request: PosterRenderRequest,
        rect: CGRect
    ) {
        
        let titleFont = UIFont.systemFont(ofSize: rect.width * 0.04, weight: .semibold)
        let statsFont = UIFont.monospacedSystemFont(ofSize: rect.width * 0.025, weight: .medium)
        
        // Title
        if !request.rideData.title.isEmpty {
            let titleRect = CGRect(
                x: rect.width * 0.1,
                y: rect.height * 0.85,
                width: rect.width * 0.8,
                height: rect.height * 0.1
            )
            
            request.rideData.title.draw(
                in: titleRect,
                withAttributes: [
                    .font: titleFont,
                    .foregroundColor: UIColor.white
                ]
            )
        }
        
        // Statistics
        let stats = formatStatistics(request.rideData)
        var y = rect.height * 0.75
        
        for stat in stats {
            stat.draw(
                at: CGPoint(x: rect.width * 0.1, y: y),
                withAttributes: [
                    .font: statsFont,
                    .foregroundColor: UIColor.white.withAlphaComponent(0.9)
                ]
            )
            y -= statsFont.lineHeight + 4
        }
    }
    
    private func renderSVGContent(
        request: PosterRenderRequest,
        options: ExportOptions
    ) async -> String {
        
        let size = options.format.resolution
        let coordinates = request.rideData.coordinates
        
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg width="\(Int(size.width))" height="\(Int(size.height))" 
             xmlns="http://www.w3.org/2000/svg" 
             xmlns:xlink="http://www.w3.org/1999/xlink">
        """
        
        // Background
        let bgColor = UIColor(request.preset.backgroundColor).hexString
        svg += """
        <rect width="100%" height="100%" fill="\(bgColor)"/>
        """
        
        // Route path
        if !coordinates.isEmpty {
            let pathData = createSVGPath(from: coordinates, in: CGRect(origin: .zero, size: size))
            let routeColor = UIColor(request.preset.routeColor).hexString
            
            svg += """
            <path d="\(pathData)" 
                  stroke="\(routeColor)" 
                  stroke-width="\(request.preset.strokeWidth)" 
                  stroke-linecap="round" 
                  stroke-linejoin="round" 
                  fill="none"
            """
            
            if request.preset.hasShadow {
                svg += """ filter="drop-shadow(2px 2px 4px rgba(0,0,0,0.3))" """
            }
            
            svg += "/>"
        }
        
        // Text elements
        svg += renderSVGText(request: request, size: size)
        
        svg += "</svg>"
        
        return svg
    }
    
    private func createSVGPath(from coordinates: [CLLocationCoordinate2D], in rect: CGRect) -> String {
        guard !coordinates.isEmpty else { return "" }
        
        let bounds = coordinates.boundingRect()
        let scale = min(rect.width / bounds.width, rect.height / bounds.height) * 0.8
        let offsetX = (rect.width - bounds.width * scale) / 2
        let offsetY = (rect.height - bounds.height * scale) / 2
        
        var pathData = ""
        
        for (index, coord) in coordinates.enumerated() {
            let point = MKMapPoint(coord)
            let x = offsetX + (point.x - bounds.minX) * scale
            let y = offsetY + (point.y - bounds.minY) * scale
            
            if index == 0 {
                pathData += "M \(x) \(y)"
            } else {
                pathData += " L \(x) \(y)"
            }
        }
        
        return pathData
    }
    
    private func renderSVGText(request: PosterRenderRequest, size: CGSize) -> String {
        var textSVG = ""
        
        // Title
        if !request.rideData.title.isEmpty {
            let fontSize = Int(size.width * 0.04)
            textSVG += """
            <text x="\(Int(size.width * 0.1))" y="\(Int(size.height * 0.9))" 
                  font-family="system-ui" font-size="\(fontSize)" 
                  font-weight="600" fill="white">
                \(request.rideData.title.xmlEscaped)
            </text>
            """
        }
        
        // Statistics
        let stats = formatStatistics(request.rideData)
        let fontSize = Int(size.width * 0.025)
        
        for (index, stat) in stats.enumerated() {
            let y = Int(size.height * 0.8) - (index * (fontSize + 8))
            textSVG += """
            <text x="\(Int(size.width * 0.1))" y="\(y)" 
                  font-family="monospace" font-size="\(fontSize)" 
                  fill="rgba(255,255,255,0.9)">
                \(stat.xmlEscaped)
            </text>
            """
        }
        
        return textSVG
    }
    
    // MARK: - Metadata Handling
    private func addMetadataToPNG(data: Data, image: UIImage) -> Data {
        // Add PNG metadata using ImageIO
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else {
            return data
        }
        
        let mutableData = NSMutableData(data: data)
        
        // This would add proper PNG metadata
        // Implementation would use ImageIO framework
        
        return mutableData as Data
    }
    
    private func addMetadataToJPEG(data: Data, image: UIImage) -> Data {
        // Add EXIF metadata to JPEG
        // Implementation would use ImageIO framework to embed EXIF data
        return data
    }
    
    private func addPDFMetadata(to context: UIGraphicsImageRendererContext, request: PosterRenderRequest) {
        // Add PDF metadata
    }
    
    // MARK: - Utilities
    private func createTemporaryFile(data: Data, format: ExportFormat) throws -> URL {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PMR_Export_\(UUID().uuidString)")
            .appendingPathExtension(format.fileExtension)
        
        try data.write(to: tempURL)
        return tempURL
    }
    
    private func formatStatistics(_ rideData: RideData) -> [String] {
        let miles = rideData.distanceMeters / 1609.344
        let feet = rideData.elevationMeters * 3.28084
        let duration = formatDuration(rideData.durationSeconds)
        let date = rideData.date.formatted(date: .abbreviated, time: .omitted)
        
        return [
            "Distance  \(String(format: "%.1f mi", miles))",
            "Climb     \(Int(feet)) ft",
            "Time      \(duration)  •  \(date)"
        ]
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Supporting Types
struct ExportResult {
    let fileURL: URL
    let format: HighResolutionExporter.ExportFormat
    let fileSize: Int
    let resolution: CGSize
    let mimeType: String
    let duration: TimeInterval
}

enum ExportError: LocalizedError {
    case dataConversionFailed
    case svgGenerationFailed
    case fileCreationFailed
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .dataConversionFailed:
            return "Failed to convert image data"
        case .svgGenerationFailed:
            return "SVG generation failed"
        case .fileCreationFailed:
            return "Could not create export file"
        case .unsupportedFormat:
            return "Unsupported export format"
        }
    }
}

// MARK: - Extensions
extension UIColor {
    var hexString: String {
        guard let components = self.cgColor.components else { return "#000000" }
        
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

extension String {
    var xmlEscaped: String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}