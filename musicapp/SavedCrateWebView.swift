import SwiftUI

// MARK: - Saved crate CD web (`396:3505` / vector `396:3513`)

struct SavedCrateWebView: View {
    let moments: [SavedMoment]
    var selectedID: UUID?
    var artworkFor: (SavedMoment) -> UIImage?
    let onSelect: (SavedMoment) -> Void

    private static let webCanvasCoordinateSpace = "crateWeb.canvas"
    private static let webPinchMin: CGFloat = 0.45
    private static let webPinchMax: CGFloat = 3.25
    /// Figma Dev gray for vector links (`396:3396` / `396:3513`).
    fileprivate static let webStrandTint = Color(red: 0.89, green: 0.89, blue: 0.89)

    @State private var layout = SavedCrateWebLayout(
        nodes: [],
        edges: [],
        canvasSize: CGSize(width: 800, height: 800),
        graphCenter: CGPoint(x: 400, y: 400)
    )

    /// User-dragged node centers keyed by moment id — survives relayout merges until IDs change or reset.
    @State private var nodeCentersById: [UUID: CGPoint] = [:]

    /// Active gesture (strand endpoints update live via `nodesForDrawing`).
    @State private var dragNodeId: UUID?
    @State private var dragTranslation = CGSize.zero

    /// Starts at `1`; pinch adjusts with pan/drag simultaneous on the infinite canvas.
    @State private var webPinchScale: CGFloat = 1
    @State private var webPinchBaseline: CGFloat = 1

#if DEBUG
    /// Stable fake moments for canvas panning/strand QA (DEBUG only).
    @State private var stressSupplement: [SavedMoment] = []
#endif

    private func composedMoments() -> [SavedMoment] {
#if DEBUG
        moments + stressSupplement
#else
        return moments
#endif
    }

    private func refreshStressSupplementIfNeeded() {
#if DEBUG
        stressSupplement = SavedCrateWebGraph.stressPreviewMoments(
            targetTotal: 22,
            existingCount: moments.count,
            templateArtwork: moments.first?.artworkImage
        )
#endif
    }

    private func momentIdentifiersSignature(for list: [SavedMoment]) -> String {
        "\(list.count)|" + list.map(\.id.uuidString).joined(separator: ",")
    }

    /// Nodes centered for rendering connectors + taps (drag offset applied inline).
    private var nodesForDrawing: [SavedCrateWebNode] {
        layout.nodes.map { n in
            guard n.id == dragNodeId else { return n }
            let c = CGPoint(
                x: n.center.x + dragTranslation.width,
                y: n.center.y + dragTranslation.height
            )
            return SavedCrateWebNode(moment: n.moment, diameter: n.diameter, center: c)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let viewport = geo.size

            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        SavedCrateDottedBackground(size: layout.canvasSize)

                        SavedCrateWebVectorConnectors(
                            nodes: nodesForDrawing,
                            edges: layout.edges,
                            canvasSize: layout.canvasSize
                        )

                        ForEach(nodesForDrawing) { node in
                            SavedCrateWebDiscNode(
                                artwork: artworkFor(node.moment),
                                diameter: node.diameter,
                                isSelected: node.id == selectedID
                            )
                            .frame(width: node.diameter, height: node.diameter)
                            .contentShape(Circle())
                            .position(node.center)
                            .gesture(canvasDiscGesture(for: node, viewport: viewport))
                        }

                        Color.clear
                            .frame(width: 1, height: 1)
                            .position(layout.graphCenter)
                            .id("webGraphCenter")
                    }
                    .coordinateSpace(name: Self.webCanvasCoordinateSpace)
                    .scaleEffect(webPinchScale, anchor: .topLeading)
                    .frame(
                        width: layout.canvasSize.width * webPinchScale,
                        height: layout.canvasSize.height * webPinchScale
                    )
                }
                .scrollIndicators(.hidden)
                .background(Color.white)
                .overlay {
                    if composedMoments().isEmpty {
                        emptyState
                    }
                }
                .simultaneousGesture(
                    MagnifyGesture()
                        .onChanged { value in
                            let next = webPinchBaseline * value.magnification
                            webPinchScale = min(max(next, SavedCrateWebView.webPinchMin), SavedCrateWebView.webPinchMax)
                        }
                        .onEnded { _ in
                            webPinchBaseline = webPinchScale
                        }
                )
                .onAppear {
                    refreshStressSupplementIfNeeded()
                    relayout(viewport: viewport, resetStoredCenters: true)
                    centerScroll(proxy: proxy)
                }
                .onChange(of: momentIdentifiersSignature(for: moments)) { _, _ in
                    refreshStressSupplementIfNeeded()
                    webPinchScale = 1
                    webPinchBaseline = 1
                    nodeCentersById = [:]
                    dragNodeId = nil
                    dragTranslation = .zero
                    relayout(viewport: viewport, resetStoredCenters: true)
                    centerScroll(proxy: proxy)
                }
                .onChange(of: viewport) { _, size in
                    relayout(viewport: size, resetStoredCenters: false)
                }
            }
        }
        .background(Color.white)
        .accessibilityIdentifier("savedCrate.web")
    }

    /// Drag moves the disc itself; tapered strands redraw from moving edge anchors. Tiny movement counts as tap-to-select.
    private func canvasDiscGesture(for node: SavedCrateWebNode, viewport: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .named(Self.webCanvasCoordinateSpace))
            .onChanged { value in
                dragNodeId = node.id
                dragTranslation = value.translation
            }
            .onEnded { value in
                let dist = hypot(value.translation.width, value.translation.height)
                if dist < 6 {
                    onSelect(node.moment)
                    dragNodeId = nil
                    dragTranslation = .zero
                    return
                }
                guard let draggingId = dragNodeId else { return }
                let base = layout.nodes.first(where: { $0.id == draggingId }) ?? node
                let merged = CGPoint(
                    x: base.center.x + value.translation.width,
                    y: base.center.y + value.translation.height
                )
                nodeCentersById[draggingId] = merged

                dragNodeId = nil
                dragTranslation = .zero

                let newNodes = layout.nodes.map { n -> SavedCrateWebNode in
                    let c = n.id == draggingId ? merged : (nodeCentersById[n.id] ?? n.center)
                    return SavedCrateWebNode(moment: n.moment, diameter: n.diameter, center: c)
                }
                layout = SavedCrateWebGraph.layoutExpandingCanvas(
                    nodes: newNodes,
                    edges: layout.edges,
                    viewport: viewport,
                    floorCanvas: layout.canvasSize
                )
                for n in layout.nodes {
                    nodeCentersById[n.id] = n.center
                }
            }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "circle.grid.cross")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color(white: 0.78))
            Text("No saved CDs yet")
                .font(FigmaFont.mono(15))
                .foregroundStyle(Color(white: 0.35))
            Text(
                """
                Long-press a CD in the crate to save a moment — at most \
                one connection per disc (matching artist/genre strands).
                """
            )
                .font(FigmaFont.mono(12))
                .foregroundStyle(Color(white: 0.55))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
    }

    private func relayout(viewport: CGSize, resetStoredCenters: Bool) {
        let list = composedMoments()
        guard !list.isEmpty else {
            layout = SavedCrateWebLayout(
                nodes: [],
                edges: [],
                canvasSize: CGSize(
                    width: max(viewport.width * 2.4, SavedCrateWebGraph.canvasMargin * 2),
                    height: max(viewport.height * 2.4, SavedCrateWebGraph.canvasMargin * 2)
                ),
                graphCenter: CGPoint(x: viewport.width * 1.2, y: viewport.height * 1.2)
            )
            if resetStoredCenters { nodeCentersById = [:] }
            return
        }

        if resetStoredCenters {
            nodeCentersById = [:]
        } else {
            let valid = Set(list.map(\.id))
            nodeCentersById = nodeCentersById.filter { valid.contains($0.key) }
        }

        let built = SavedCrateWebGraph.build(moments: list, viewport: viewport)

        let newNodes = built.nodes.map { n -> SavedCrateWebNode in
            let center = resetStoredCenters ? n.center : (nodeCentersById[n.id] ?? n.center)
            return SavedCrateWebNode(moment: n.moment, diameter: n.diameter, center: center)
        }

        layout = SavedCrateWebGraph.layoutExpandingCanvas(
            nodes: newNodes,
            edges: built.edges,
            viewport: viewport,
            floorCanvas: resetStoredCenters ? nil : layout.canvasSize
        )
    }

    private func centerScroll(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo("webGraphCenter", anchor: .center)
        }
    }
}

// MARK: - Dotted infinite field (`396:3505`)

struct SavedCrateDottedBackground: View {
    let size: CGSize
    var dotStep: CGFloat = 14
    var dotRadius: CGFloat = 0.55

    var body: some View {
        Canvas { context, canvasSize in
            context.fill(Path(CGRect(origin: .zero, size: canvasSize)), with: .color(.white))

            var x = dotStep * 0.5
            while x < canvasSize.width {
                var y = dotStep * 0.5
                while y < canvasSize.height {
                    let rect = CGRect(
                        x: x - dotRadius,
                        y: y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(Color(red: 0.82, green: 0.82, blue: 0.82).opacity(0.55))
                    )
                    y += dotStep
                }
                x += dotStep
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

// MARK: - Uniform-strand connectors (Figma `396:3396` stroked Bézier)

struct SavedCrateWebVectorConnectors: View {
    let nodes: [SavedCrateWebNode]
    let edges: [SavedCrateWebEdge]
    let canvasSize: CGSize

    /// Round caps/joins preserve constant perpendicular thickness along the spline as endpoints move (“morphing” vector strand).
    private var strandStroke: StrokeStyle {
        StrokeStyle(
            lineWidth: SavedCrateWebGraph.uniformWebStrandLineWidth,
            lineCap: .round,
            lineJoin: .round
        )
    }

    var body: some View {
        Canvas { context, _ in
            let nodeMap = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
            for edge in edges {
                guard let a = nodeMap[edge.a], let b = nodeMap[edge.b] else { continue }
                let start = SavedCrateWebGraph.edgePoint(on: a.center, toward: b.center, radius: a.radius)
                let end = SavedCrateWebGraph.edgePoint(on: b.center, toward: a.center, radius: b.radius)
                let spine = SavedCrateWebConnectorPath.uniformStrandSpine(from: start, to: end)
                context.stroke(
                    spine,
                    with: .color(SavedCrateWebView.webStrandTint),
                    style: strandStroke
                )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(false)
    }
}

// MARK: - Disc node

struct SavedCrateWebDiscNode: View {
    var artwork: UIImage?
    let diameter: CGFloat
    var isSelected: Bool = false

    private var hub: CGFloat { max(14, diameter * 0.234) }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .shadow(color: .black.opacity(0.08), radius: diameter * 0.04, y: diameter * 0.02)

            discFace
                .frame(width: diameter, height: diameter)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .stroke(Color.black.opacity(0.06), lineWidth: max(0.5, diameter * 0.005))
                }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.96), Color(white: 0.74)],
                        center: .center,
                        startRadius: 0,
                        endRadius: hub / 2
                    )
                )
                .frame(width: hub, height: hub)
                .overlay {
                    Circle()
                        .stroke(Color.black.opacity(0.14), lineWidth: 0.5)
                }
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.easeOut(duration: 0.18), value: isSelected)
    }

    @ViewBuilder
    private var discFace: some View {
        if let ui = artwork {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
        } else {
            Image(FigmaImage.cdDisc)
                .resizable()
                .scaledToFill()
        }
    }
}

#Preview("Web — empty") {
    SavedCrateWebView(moments: [], selectedID: nil, artworkFor: { _ in nil }, onSelect: { _ in })
        .frame(height: 520)
}
