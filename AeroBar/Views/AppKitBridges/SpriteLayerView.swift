import SwiftUI
import AppKit

struct SpriteLayerView: NSViewRepresentable {
    let spriteImage: NSImage
    let stateIndex: Int // 0 = Normal, 1 = Hover, 2 = Pressed
    let totalStates: CGFloat = 3.0
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.contents = spriteImage
        view.layer?.contentsGravity = .resizeAspect
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        let cellHeightNormalized: CGFloat = 1.0 / totalStates
        let currentYOffsetNormalized: CGFloat = 1.0 - (CGFloat(stateIndex + 1) * cellHeightNormalized)
        
        let targetCropBox = CGRect(
            x: 0.0,
            y: currentYOffsetNormalized,
            width: 1.0,
            height: cellHeightNormalized
        )
        nsView.layer?.contentsRect = targetCropBox
    }
}
