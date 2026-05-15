import SwiftUI
import AppKit

/// Brand icon for the menubar: a "C" arc enclosing a play triangle.
/// Drawn as a template NSImage (single-channel alpha) so AppKit auto-tints
/// it to match the current menubar appearance (white on dark, black on light).
/// SwiftUI Canvas does not reliably render inside a MenuBarExtra label —
/// AppKit needs an NSImage with isTemplate=true to do the tinting.
struct CadenceMenuIcon: View {
    var body: some View {
        Image(nsImage: Self.image)
    }

    private static let image: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let side = min(rect.width, rect.height)
            let cx = rect.midX
            let cy = rect.midY

            // Geometry derived from icon-source.png: C mouth-on-right with
            // a play triangle centered inside. Inner clearance is anchored
            // so adjusting stroke thickness grows the C outward, leaving the
            // play triangle the same room inside.
            let innerRadius = side * 0.30
            let stroke = side * 0.16
            let arcRadius = innerRadius + stroke / 2

            NSColor.black.setStroke()
            NSColor.black.setFill()

            // C arc — endpoints at ±45° (mouth on right ≈90° gap), traversing
            // the left half via 180°. With NSBezierPath, going from +45°
            // counter-clockwise (clockwise:false) lands at -45° after the
            // long way through 90° → 180° → 270°.
            let arcPath = NSBezierPath()
            arcPath.appendArc(
                withCenter: NSPoint(x: cx, y: cy),
                radius: arcRadius,
                startAngle: 45,
                endAngle: -45,
                clockwise: false,
            )
            arcPath.lineWidth = stroke
            arcPath.lineCapStyle = .round
            arcPath.stroke()

            // Play triangle — sits inside the C with a slight right-bias so
            // the right tip points into (but stops short of) the mouth.
            let triHeight = side * 0.32
            let triWidth = triHeight * 0.86
            let triCenterX = cx + side * 0.05
            let triPath = NSBezierPath()
            triPath.move(to: NSPoint(x: triCenterX - triWidth / 2, y: cy + triHeight / 2))
            triPath.line(to: NSPoint(x: triCenterX - triWidth / 2, y: cy - triHeight / 2))
            triPath.line(to: NSPoint(x: triCenterX + triWidth / 2, y: cy))
            triPath.close()
            triPath.fill()

            return true
        }
        image.isTemplate = true
        return image
    }()
}

#Preview {
    HStack(spacing: 16) {
        CadenceMenuIcon()
        CadenceMenuIcon().foregroundStyle(.white)
        CadenceMenuIcon().foregroundStyle(.black)
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
