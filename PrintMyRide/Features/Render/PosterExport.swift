import SwiftUI
import PDFKit

enum PosterExport {
    struct Sizes { let pt: CGSize; let px: CGSize; let bleedPt: CGFloat }
    static func sizes(inches: CGSize, dpi: Int, bleedInches: CGFloat) -> Sizes {
        let pt = CGSize(width: inches.width*72, height: inches.height*72)
        let px = CGSize(width: inches.width*CGFloat(dpi), height: inches.height*CGFloat(dpi))
        return .init(pt: pt, px: px, bleedPt: bleedInches*72)
    }

    // Async PNG: hop to MainActor for the ImageRenderer work
    static func pngAsync(design: PosterDesign, route: GPXRoute?, dpi: Int,
                         bleedInches: CGFloat, includeGrid: Bool) async -> Data? {
        await MainActor.run {
            let s = sizes(inches: design.paperSize, dpi: dpi, bleedInches: bleedInches)
            var temp = design; if !includeGrid { temp.showGrid = false }
            let frame = CGSize(width: s.pt.width + 2*s.bleedPt, height: s.pt.height + 2*s.bleedPt)
            let view = ZStack {
                Color.white
                PosterPreview(design: temp, route: route, mode: .export)
                    .padding(EdgeInsets(top: s.bleedPt, leading: s.bleedPt, bottom: s.bleedPt, trailing: s.bleedPt))
            }
            .frame(width: frame.width, height: frame.height)

            let r = ImageRenderer(content: view)
            r.scale = CGFloat(dpi)/72.0
            #if canImport(UIKit)
            return r.uiImage?.pngData()
            #else
            return nil
            #endif
        }
    }

    // Async PDF: render SwiftUI into a PDF page on the main actor
    static func pdfAsync(design: PosterDesign, route: GPXRoute?, bleedInches: CGFloat,
                         includeGrid: Bool) async -> Data? {
        await MainActor.run {
            let s = sizes(inches: design.paperSize, dpi: 300, bleedInches: bleedInches)
            let page = CGRect(x: 0, y: 0, width: s.pt.width + 2*s.bleedPt, height: s.pt.height + 2*s.bleedPt)

            var temp = design; if !includeGrid { temp.showGrid = false }
            let view = ZStack {
                Color.white
                PosterPreview(design: temp, route: route, mode: .export)
                    .padding(EdgeInsets(top: s.bleedPt, leading: s.bleedPt, bottom: s.bleedPt, trailing: s.bleedPt))
            }
            .frame(width: page.width, height: page.height)

            let fmt = UIGraphicsPDFRendererFormat()
            let rnd = UIGraphicsPDFRenderer(bounds: page, format: fmt)
            let data = rnd.pdfData { ctx in
                ctx.beginPage()
                let r = ImageRenderer(content: view)
                r.render { size, render in
                    render(ctx.cgContext)
                }
            }
            return data
        }
    }
}

private extension CGSize {
    var rounded: CGSize { .init(width: round(width), height: round(height)) }
}
