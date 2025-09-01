// Utilities/AutoWriter.swift
import Foundation

enum AutoWriter {
    static func writeFile(path: String, contents: String) {
        let url = URL(fileURLWithPath: path)
        let dir = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        do {
            try contents.write(to: url, atomically: true, encoding: .utf8)
            print("wrote \(path)")
        } catch {
            print("write failed \(path): \(error)")
        }
    }
}
