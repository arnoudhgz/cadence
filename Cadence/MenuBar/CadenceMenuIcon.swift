import SwiftUI

/// Brand icon for the menubar: a "C" arc enclosing a play triangle.
/// Drawn vector-style so it stays crisp at 1x and 2x, and inherits the
/// menubar tint via .primary (white on dark menubar, black on light).
struct CadenceMenuIcon: View {
    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let cx = size.width / 2
            let cy = size.height / 2
            let stroke = side * 0.16
            let arcRadius = side * 0.42 - stroke / 2

            // C: arc with a gap on the right where the play triangle peeks out.
            var arc = Path()
            arc.addArc(
                center: CGPoint(x: cx, y: cy),
                radius: arcRadius,
                startAngle: .degrees(-145),
                endAngle: .degrees(145),
                clockwise: false,
            )
            context.stroke(
                arc,
                with: .color(.primary),
                style: StrokeStyle(lineWidth: stroke, lineCap: .round),
            )

            // Play triangle, optically centered (small nudge left to balance the
            // visual weight of the C's opening on the right).
            let triHeight = side * 0.42
            let triWidth = triHeight * 0.86
            let triCenterX = cx - side * 0.02
            var tri = Path()
            tri.move(to: CGPoint(x: triCenterX - triWidth / 2, y: cy - triHeight / 2))
            tri.addLine(to: CGPoint(x: triCenterX - triWidth / 2, y: cy + triHeight / 2))
            tri.addLine(to: CGPoint(x: triCenterX + triWidth / 2, y: cy))
            tri.closeSubpath()
            context.fill(tri, with: .color(.primary))
        }
        .frame(width: 18, height: 18)
    }
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
