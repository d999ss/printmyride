import SwiftUI

struct MockCheckoutView: View {
    let poster: Poster
    @State private var size: String = "18×24"
    @State private var paper: String = "Matte"
    @State private var name: String = "Jane Doe"
    @State private var addr: String = "123 Demo St"
    @State private var city: String = "Park City"
    @State private var state: String = "UT"
    @State private var zip: String = "84060"
    @State private var placing = false
    @State private var successID: String?

    var body: some View {
        Form {
            Section {
                if let img = UIImage(contentsOfFile: documentsURL().appendingPathComponent(poster.thumbnailPath).path) {
                    Image(uiImage: img).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            Section("Poster") {
                Picker("Size", selection: $size) { Text("18×24").tag("18×24"); Text("A2").tag("A2") }
                Picker("Paper", selection: $paper) { Text("Matte").tag("Matte"); Text("Semi-gloss").tag("Semi-gloss") }
                HStack { Text("Price"); Spacer(); Text(priceString).fontWeight(.semibold) }
                HStack { Text("ETA"); Spacer(); Text("5–7 days") }
            }
            Section("Ship To") {
                TextField("Full Name", text: $name)
                TextField("Address", text: $addr)
                HStack { TextField("City", text: $city); TextField("State", text: $state).frame(width: 60); TextField("ZIP", text: $zip).frame(width: 90) }
            }
            Section {
                Button {
                    placing = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        placing = false
                        successID = "D-\(Int.random(in: 10000...99999))"
                    }
                } label: {
                    Text(placing ? "Placing…" : "Place Demo Order")
                }.disabled(placing)
            }
        }
        .navigationTitle("Print This Poster")
        .alert("Order Placed", isPresented: .constant(successID != nil), actions: {
            Button("Done") { successID = nil }
        }, message: {
            Text("Order #\(successID ?? "") created.\n(Stencil for real partner API)")
        })
    }
    private var priceString: String { size == "A2" ? "$49" : "$39" }
    private func documentsURL() -> URL { FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first! }
}