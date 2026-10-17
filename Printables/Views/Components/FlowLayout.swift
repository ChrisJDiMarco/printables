import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let arrangement = arrange(subviews: subviews, maxWidth: maxWidth)
        return CGSize(width: maxWidth.isFinite ? maxWidth : arrangement.size.width, height: arrangement.size.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(subviews: subviews, maxWidth: bounds.width)
        for placement in arrangement.placements {
            let origin = CGPoint(x: bounds.minX + placement.point.x, y: bounds.minY + placement.point.y)
            placement.subview.place(at: origin, proposal: ProposedViewSize(placement.size))
        }
    }

    private struct Placement {
        let subview: LayoutSubview
        let point: CGPoint
        let size: CGSize
    }

    private struct Arrangement {
        let placements: [Placement]
        let size: CGSize
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> Arrangement {
        var placements: [Placement] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth && currentX > 0 {
                currentY += rowHeight + spacing
                currentX = 0
                rowHeight = 0
            }
            placements.append(Placement(subview: subview, point: CGPoint(x: currentX, y: currentY), size: size))
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, currentX - spacing)
        }
        return Arrangement(placements: placements, size: CGSize(width: totalWidth, height: currentY + rowHeight))
    }
}
