import SwiftUI

struct GalleryView: View {
    @EnvironmentObject var library: LibraryStore
    @State private var openProject: PosterProject?
    @State private var pendingRename: PosterProject?

    let cols = [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: cols, spacing: 2) {
                    ForEach(Array(library.projects.enumerated()), id: \.element.id) { indexedProject in
                        let (idx, p) = indexedProject
                        Group {
                            if let img = UIImage(contentsOfFile: library.thumbnailURL(for: p).path) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 140)
                                    .clipped()
                            } else {
                                Rectangle()
                                    .fill(DesignTokens.ColorToken.surface)
                                    .frame(height: 140)
                            }
                        }
                        .contextMenu {
                            Button("Duplicate") {
                                var copy = p
                                copy.id = UUID()
                                copy.title += " (copy)"
                                library.projects.insert(copy, at: 0)
                                library.save()
                            }
                            .font(DesignTokens.Typography.body)
                            
                            Button("Rename") { pendingRename = p }
                                .font(DesignTokens.Typography.body)
                            
                            ShareLink(item: library.thumbnailURL(for: p), preview: .init("Poster", image: Image(uiImage: UIImage(contentsOfFile: library.thumbnailURL(for: p).path)!)))
                                .font(DesignTokens.Typography.body)
                            
                            Button("Delete", role: .destructive) { 
                                library.projects.remove(at: idx)
                                library.save() 
                            }
                            .font(DesignTokens.Typography.body)
                        }
                        .onTapGesture { openProject = p }
                    }
                }
            }
            .navigationTitle("Gallery")
            .sheet(item: $openProject) { p in
                let url = library.routeURL(for: p)
                let r = url.flatMap { GPXImporter.load(url: $0) }
                EditorView(initialDesign: p.design, initialRoute: r, initialText: p.text)
            }
            .sheet(item: $pendingRename) { proj in
                RenameSheet(project: proj)
            }
        }
    }
}

struct RenameSheet: View {
    @EnvironmentObject var library: LibraryStore
    @Environment(\.dismiss) var dismiss
    @State var project: PosterProject
    var body: some View {
        NavigationStack {
            Form { 
                TextField("Title", text: $project.title)
                    .font(DesignTokens.Typography.body)
            }
            .navigationTitle("Rename")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let i = library.projects.firstIndex(where: { $0.id == project.id }) {
                            library.projects[i].title = project.title
                            library.save()
                        }
                        dismiss()
                    }
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.primary)
                }
                ToolbarItem(placement: .cancellationAction) { 
                    Button("Cancel") { dismiss() }
                        .font(DesignTokens.Typography.body)
                }
            }
        }
    }
}