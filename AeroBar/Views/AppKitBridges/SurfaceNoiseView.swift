import SwiftUI
import AppKit

struct SurfaceNoiseView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        if let filter = CIFilter(name: "CIRandomGenerator"),
           let outputImage = filter.outputImage,
           let cgImage = CIContext(options: nil).createCGImage(outputImage, from: CGRect(x: 0, y: 0, width: 200, height: 200)) {
            let noiseImage = NSImage(cgImage: cgImage, size: NSSize(width: 200, height: 200))
            view.layer?.contents = noiseImage
            view.layer?.contentsCenter = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
            view.layer?.contentsGravity = .resize
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
