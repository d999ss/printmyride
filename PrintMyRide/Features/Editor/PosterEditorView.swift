import SwiftUI

// Legacy shim so old references compile.
// The real UI is EditorView.
struct PosterEditorView: View {
    var body: some View { EditorView() }
}
