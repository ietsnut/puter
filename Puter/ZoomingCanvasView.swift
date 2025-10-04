import SwiftUI
import UIKit

final class ZoomingCanvasView: UIView, UIScrollViewDelegate {
    private let gridSpacing: CGFloat = 44
    private let contentSizePx: CGFloat = 8000
    private let moduleSize = CGSize(width: 160, height: 160)
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let gridView = GridTiledView()
    
    private(set) var modules: [Module] = []
    private var moduleViews: [UUID: UIView] = [:]
    private var modulePorts: [UUID: [PortView]] = [:]
    private var connections: [Connection] = []
    private weak var selectedPort: PortView?
    
    func configure() {
        backgroundColor = .clear
        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear
        scrollView.delegate = self
        scrollView.minimumZoomScale = 0.25
        scrollView.maximumZoomScale = 3.0
        scrollView.bouncesZoom = true
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        contentView.frame = CGRect(x: 0, y: 0, width: contentSizePx, height: contentSizePx)
        scrollView.contentSize = contentView.bounds.size
        scrollView.addSubview(contentView)
        
        gridView.frame = contentView.bounds
        gridView.gridSpacing = gridSpacing
        contentView.addSubview(gridView)
        
        centerWorld()
    }
    
    func addModuleAtCenter(module: Module) {
        let center = visibleCenterInContent()
        placeModule(module: module, at: center)
    }
    
    private func ioCounts(for module: Module) -> (inputs: Int, outputs: Int) {
        switch module.name.lowercased() {
        case "adder", "subtractor":
            return (2, 1)
        case "splitter":
            return (1, 2)
        default:
            return (1, 1)
        }
    }
    
    private func placeModule(module: Module, at point: CGPoint) {
        let hosting = UIHostingController(rootView: TileView(name: module.name, systemImage: module.systemImage))
        let container = UIView(frame: CGRect(origin: .zero, size: moduleSize))
        container.backgroundColor = .clear
        container.center = point
        container.isUserInteractionEnabled = true
        
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hosting.view)
        
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            hosting.view.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
            hosting.view.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            hosting.view.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
        ])
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleModulePan(_:)))
        container.addGestureRecognizer(pan)
        
        contentView.addSubview(container)
        
        var placedModule = module.placed(at: point, size: moduleSize)
        modules.append(placedModule)
        moduleViews[placedModule.id] = container
        
        let counts = ioCounts(for: placedModule)
        let ports = createPorts(for: placedModule, in: container, inputs: counts.inputs, outputs: counts.outputs)
        modulePorts[placedModule.id] = ports
    }
    
    private func createPorts(for module: Module, in container: UIView, inputs: Int, outputs: Int) -> [PortView] {
        var created: [PortView] = []
        let size: CGFloat = 18
        let inset: CGFloat = 4
        if inputs > 0 {
            let gap = container.bounds.height / CGFloat(inputs + 1)
            for i in 0..<inputs {
                let y = gap * CGFloat(i + 1)
                let frame = CGRect(x: inset, y: y - size/2, width: size, height: size)
                let p = PortView(moduleID: module.id, kind: .input, index: i)
                p.frame = frame
                p.layer.cornerRadius = size/2
                p.backgroundColor = UIColor.systemBlue
                p.layer.borderWidth = 2
                p.layer.borderColor = UIColor.clear.cgColor
                p.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin]
                p.canvas = self
                container.addSubview(p)
                created.append(p)
            }
        }
        if outputs > 0 {
            let gap = container.bounds.height / CGFloat(outputs + 1)
            for i in 0..<outputs {
                let y = gap * CGFloat(i + 1)
                let frame = CGRect(x: container.bounds.width - size - inset, y: y - size/2, width: size, height: size)
                let p = PortView(moduleID: module.id, kind: .output, index: i)
                p.frame = frame
                p.layer.cornerRadius = size/2
                p.backgroundColor = UIColor.systemGreen
                p.layer.borderWidth = 2
                p.layer.borderColor = UIColor.clear.cgColor
                p.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleLeftMargin]
                p.canvas = self
                container.addSubview(p)
                created.append(p)
            }
        }
        return created
    }
    

    
    private func updateModulePosition(view: UIView) {
        if let index = modules.firstIndex(where: { moduleViews[$0.id] === view }) {
            modules[index].position = view.center
        }
    }
    
    func frameAllModules() {
        guard !modules.isEmpty else {
            centerWorld()
            return
        }
        
        var unionRect = CGRect(origin: modules[0].position ?? .zero, size: .zero)
        for module in modules {
            guard let position = module.position, let size = module.size else { continue }
            let rect = CGRect(
                x: position.x - size.width / 2,
                y: position.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            unionRect = unionRect.union(rect)
        }
        
        let padding: CGFloat = 120
        let target = unionRect.insetBy(dx: -padding, dy: -padding).intersection(contentView.bounds)
        scrollView.zoom(to: target, animated: true)
    }
    
    private func visibleCenterInContent() -> CGPoint {
        let scale = scrollView.zoomScale
        let x = scrollView.contentOffset.x / scale + scrollView.bounds.width * 0.5 / scale
        let y = scrollView.contentOffset.y / scale + scrollView.bounds.height * 0.5 / scale
        return CGPoint(x: x, y: y)
    }
    
    private func centerWorld() {
        scrollView.setZoomScale(1.0, animated: false)
        let target = CGPoint(
            x: (contentSizePx - scrollView.bounds.width) * 0.5,
            y: (contentSizePx - scrollView.bounds.height) * 0.5
        )
        scrollView.setContentOffset(target, animated: false)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        gridView.setNeedsDisplay()
        redrawAllConnections()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        gridView.setNeedsDisplay()
        redrawAllConnections()
    }
    
    func portTapped(_ port: PortView) {
        if let sel = selectedPort {
            if sel === port {
                highlight(port: sel, highlighted: false)
                selectedPort = nil
                return
            }
            if sel.kind == port.kind {
                highlight(port: sel, highlighted: false)
                selectedPort = port
                highlight(port: port, highlighted: true)
                return
            }
            let from: PortView
            let to: PortView
            if sel.kind == .output && port.kind == .input {
                from = sel
                to = port
            } else if sel.kind == .input && port.kind == .output {
                from = port
                to = sel
            } else {
                highlight(port: sel, highlighted: false)
                selectedPort = nil
                return
            }
            if from.moduleID == to.moduleID {
                highlight(port: sel, highlighted: false)
                selectedPort = nil
                return
            }
            createConnection(from: from, to: to)
            highlight(port: sel, highlighted: false)
            selectedPort = nil
        } else {
            selectedPort = port
            highlight(port: port, highlighted: true)
        }
    }
    
    private func highlight(port: PortView, highlighted: Bool) {
        port.layer.borderColor = highlighted ? UIColor.systemYellow.cgColor : UIColor.clear.cgColor
    }
    
    
    private func portCenterInContent(_ port: PortView) -> CGPoint {
        let local = CGRect(x: 0, y: 0, width: port.bounds.width, height: port.bounds.height)
        let center = CGPoint(x: local.midX, y: local.midY)
        return port.convert(center, to: contentView)
    }
    
    private func createConnection(from: PortView, to: PortView) {
            let layer = CAShapeLayer()
            layer.strokeColor = UIColor.label.withAlphaComponent(0.8).cgColor
            layer.fillColor = UIColor.clear.cgColor
            layer.lineWidth = 2
            layer.lineJoin = .round          // rounded corners at bends
            layer.lineCap = .round           // rounded line endpoints
            contentView.layer.insertSublayer(layer, above: gridView.layer)
            let connection = Connection(from: from, to: to, layer: layer)
            connections.append(connection)
            updateConnectionPath(connection)
        }
        
        private func updateConnectionPath(_ connection: Connection) {
            guard let fromPort = connection.from, let toPort = connection.to else { return }
            // Calculate port center positions in canvas coordinates
            let p1 = portCenterInContent(fromPort)
            let p2 = portCenterInContent(toPort)
            // Use the orthogonal router to get a path with 90-degree turns
            let bezierPath = OrthogonalConnectionRouter.makePath(from: p1, fromPort: fromPort,
                                                                 to: p2, toPort: toPort)
            connection.layer.path = bezierPath.cgPath
        }
        
        @objc private func handleModulePan(_ gesture: UIPanGestureRecognizer) {
            guard let view = gesture.view else { return }
            let translation = gesture.translation(in: contentView)
            if gesture.state == .changed {
                // Move the module
                view.center = CGPoint(x: view.center.x + translation.x,
                                       y: view.center.y + translation.y)
                gesture.setTranslation(.zero, in: contentView)
                // Update module's logical position
                updateModulePosition(view: view)
                // Dynamically reroute all connections involving this module
                if let movedID = moduleViews.first(where: { $0.value === view })?.key {
                    updateConnections(for: movedID)
                }
            }
        }
    
    private func updateConnections(for moduleID: UUID) {
        for i in 0..<connections.count {
            if connections[i].from?.moduleID == moduleID || connections[i].to?.moduleID == moduleID {
                updateConnectionPath(connections[i])
            }
        }
    }
    
    private func redrawAllConnections() {
        for i in 0..<connections.count {
            updateConnectionPath(connections[i])
        }
    }
}

final class PortView: UIView {
    enum Kind { case input, output }
    let moduleID: UUID
    let kind: Kind
    let index: Int
    weak var canvas: ZoomingCanvasView?
    
    init(moduleID: UUID, kind: Kind, index: Int) {
        self.moduleID = moduleID
        self.kind = kind
        self.index = index
        super.init(frame: .zero)
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    @objc private func tapped() {
        canvas?.portTapped(self)
    }
}

struct Connection {
    weak var from: PortView?
    weak var to: PortView?
    let layer: CAShapeLayer
}

final class GridTiledView: UIView {
    override class var layerClass: AnyClass {
        CATiledLayer.self
    }
    
    var gridSpacing: CGFloat = 44
    private let blueprintBackground = UIColor(red: 0.86, green: 0.93, blue: 0.98, alpha: 1.0)
    private let dotColor = UIColor(red: 0.07, green: 0.24, blue: 0.52, alpha: 1.0)
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let tiledLayer = layer as? CATiledLayer {
            tiledLayer.levelsOfDetail = 4
            tiledLayer.levelsOfDetailBias = 4
            tiledLayer.tileSize = CGSize(width: 256, height: 256)
            contentScaleFactor = 1
        }
        isOpaque = true
        backgroundColor = blueprintBackground
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setFillColor(blueprintBackground.cgColor)
        context.fill(rect)
        
        let spacing = gridSpacing
        let radius: CGFloat = 1.6
        let drawRect = rect.insetBy(dx: -radius, dy: -radius)
        
        context.setFillColor(dotColor.withAlphaComponent(0.8).cgColor)
        
        var x = floor(drawRect.minX / spacing) * spacing
        while x <= drawRect.maxX {
            var y = floor(drawRect.minY / spacing) * spacing
            while y <= drawRect.maxY {
                let dotRect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fillEllipse(in: dotRect)
                y += spacing
            }
            x += spacing
        }
    }
}
