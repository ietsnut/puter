import SwiftUI
import UIKit

final class OrthogonalConnectionRouter {
    static func makePath(from p1: CGPoint, fromPort: PortView,
                         to p2: CGPoint, toPort: PortView) -> UIBezierPath {
        var sourcePort = fromPort
        var targetPort = toPort
        var start = p1
        var end = p2
        if sourcePort.kind != .output {
            swap(&sourcePort, &targetPort)
            swap(&start, &end)
        }
        let offset: CGFloat = 40.0
        let spacing: CGFloat = 40.0
        let startOffset = offset + spacing * CGFloat(sourcePort.index)
        let endOffset = offset + spacing * CGFloat(targetPort.index)
        let startX = start.x + startOffset
        let endX = end.x - endOffset
        let bendRadius: CGFloat = 15.0
        let path = CGMutablePath()
        path.move(to: start)
        if startX <= endX {
            var midX = (startX + endX) / 2.0
            let diff = sourcePort.index - targetPort.index
            if diff != 0 {
                midX += CGFloat(diff) * spacing
            } else {
                midX += CGFloat(sourcePort.index) * spacing
            }
            var routePoints: [CGPoint] = []
            routePoints.append(CGPoint(x: midX, y: start.y))
            if start.y != end.y {
                routePoints.append(CGPoint(x: midX, y: end.y))
            }
            routePoints.append(CGPoint(x: endX, y: end.y))
            routePoints.append(end)
            var points: [CGPoint] = [start]
            points.append(contentsOf: routePoints)
            var filtered: [CGPoint] = [points[0]]
            for i in 1..<points.count-1 {
                let prev = points[i-1]
                let cur = points[i]
                let next = points[i+1]
                if (prev.x == cur.x && cur.x == next.x) || (prev.y == cur.y && cur.y == next.y) {
                    continue
                }
                filtered.append(cur)
            }
            filtered.append(points.last!)
            for i in 1..<filtered.count-1 {
                path.addArc(tangent1End: filtered[i], tangent2End: filtered[i+1], radius: bendRadius)
            }
            path.addLine(to: filtered.last!)
        } else {
            let detourClear: CGFloat = 100.0
            let verticalGap = abs(start.y - end.y)
            if verticalGap > detourClear {
                let midY = (start.y + end.y) / 2.0
                var routePoints: [CGPoint] = []
                routePoints.append(CGPoint(x: startX, y: start.y))
                routePoints.append(CGPoint(x: startX, y: midY))
                routePoints.append(CGPoint(x: endX, y: midY))
                routePoints.append(CGPoint(x: endX, y: end.y))
                routePoints.append(end)
                var points: [CGPoint] = [start]
                points.append(contentsOf: routePoints)
                var filtered: [CGPoint] = [points[0]]
                for i in 1..<points.count-1 {
                    let prev = points[i-1]
                    let cur = points[i]
                    let next = points[i+1]
                    if (prev.x == cur.x && cur.x == next.x) || (prev.y == cur.y && cur.y == next.y) {
                        continue
                    }
                    filtered.append(cur)
                }
                filtered.append(points.last!)
                for i in 1..<filtered.count-1 {
                    path.addArc(tangent1End: filtered[i], tangent2End: filtered[i+1], radius: bendRadius)
                }
                path.addLine(to: filtered.last!)
            } else {
                let baseDetourY: CGFloat
                if start.y < end.y {
                    baseDetourY = min(start.y, end.y) - detourClear
                } else {
                    baseDetourY = max(start.y, end.y) + detourClear
                }
                let diff = sourcePort.index - targetPort.index
                var detourY = baseDetourY
                if diff != 0 {
                    detourY += CGFloat(diff) * (start.y < end.y ? -spacing : spacing)
                } else {
                    if start.y < end.y {
                        detourY -= CGFloat(sourcePort.index) * spacing
                    } else {
                        detourY += CGFloat(sourcePort.index) * spacing
                    }
                }
                var routePoints: [CGPoint] = []
                routePoints.append(CGPoint(x: startX, y: start.y))
                routePoints.append(CGPoint(x: startX, y: detourY))
                routePoints.append(CGPoint(x: endX, y: detourY))
                routePoints.append(CGPoint(x: endX, y: end.y))
                routePoints.append(end)
                var points: [CGPoint] = [start]
                points.append(contentsOf: routePoints)
                var filtered: [CGPoint] = [points[0]]
                for i in 1..<points.count-1 {
                    let prev = points[i-1]
                    let cur = points[i]
                    let next = points[i+1]
                    if (prev.x == cur.x && cur.x == next.x) || (prev.y == cur.y && cur.y == next.y) {
                        continue
                    }
                    filtered.append(cur)
                }
                filtered.append(points.last!)
                for i in 1..<filtered.count-1 {
                    path.addArc(tangent1End: filtered[i], tangent2End: filtered[i+1], radius: bendRadius)
                }
                path.addLine(to: filtered.last!)
            }
        }
        return UIBezierPath(cgPath: path)
    }
}
