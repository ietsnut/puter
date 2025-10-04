import SwiftUI
import UIKit

final class OrthogonalConnectionRouter {
    /// Compute an orthogonal (90°) path connecting two ports with rounded bends.
    static func makePath(from p1: CGPoint, fromPort: PortView,
                         to p2: CGPoint, toPort: PortView) -> UIBezierPath {
        // Ensure fromPort is output and toPort is input
        var sourcePort = fromPort
        var targetPort = toPort
        var start = p1
        var end = p2
        if sourcePort.kind != .output {
            swap(&sourcePort, &targetPort)
            swap(&start, &end)
        }
        // Base offsets for horizontal port extension
        let offset: CGFloat = 40.0
        let startX = start.x + offset  // extend to the right of source module
        let endX   = end.x - offset    // extend to the left of target module
        let path = UIBezierPath()
        path.move(to: start)
        
        if startX <= endX {
            // Straightforward L-shaped or Z-shaped path (no forced detour)
            var midX = (startX + endX) / 2
            // Offset midX slightly based on port indices to avoid overlaps
            midX += CGFloat(sourcePort.index - targetPort.index) * 10.0
            // Horizontal out from source, vertical, then horizontal into target
            path.addLine(to: CGPoint(x: midX, y: start.y))
            path.addLine(to: CGPoint(x: midX, y: end.y))
            path.addLine(to: CGPoint(x: endX, y: end.y))
            path.addLine(to: end)
        } else {
            // Source is to the right of target – route around via an orthogonal detour
            // Choose a detour Y-level above or below both modules to avoid crossing
            let detourY: CGFloat
            if start.y < end.y {
                detourY = min(start.y, end.y) - 100.0  // go above both modules
            } else {
                detourY = max(start.y, end.y) + 100.0  // go below both modules
            }
            // Path: out from source, orthogonal detour around, then into target
            path.addLine(to: CGPoint(x: startX, y: start.y))
            path.addLine(to: CGPoint(x: startX, y: detourY))
            path.addLine(to: CGPoint(x: endX, y: detourY))
            path.addLine(to: CGPoint(x: endX, y: end.y))
            path.addLine(to: end)
        }
        return path
    }
}
