import SwiftUI
import UIKit

struct Module: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let systemImage: String
    var position: CGPoint?
    var size: CGSize?
    
    init(name: String, systemImage: String, position: CGPoint? = nil, size: CGSize? = nil) {
        self.name = name
        self.systemImage = systemImage
        self.position = position
        self.size = size
    }
    
    func placed(at position: CGPoint, size: CGSize) -> Module {
        Module(name: name, systemImage: systemImage, position: position, size: size)
    }
}

struct ModuleGroup: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let items: [Module]
}

struct MainScreen: View {
    @State private var addRequest: Module? = nil
    @State private var visibility: NavigationSplitViewVisibility = .all
    @State private var centerTrigger: Int = 0
    
    private let groups: [ModuleGroup] = [
        ModuleGroup(name: "Math", items: [
            Module(name: "Adder", systemImage: "plus"),
            Module(name: "Subtractor", systemImage: "minus"),
        ]),
        ModuleGroup(name: "Logistics", items: [
            Module(name: "Splitter", systemImage: "arrow.triangle.branch"),
        ]),
    ]
    
    var body: some View {
        NavigationSplitView(columnVisibility: $visibility) {
            SidebarList(groups: groups) { module in
                addRequest = module
                if UIDevice.current.userInterfaceIdiom == .phone {
                    withAnimation { visibility = .detailOnly }
                }
            }
            .navigationSplitViewColumnWidth(250)
        } detail: {
            ZoomingCanvasRepresentable(addRequest: $addRequest, centerTrigger: $centerTrigger)
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        Button {
                            centerTrigger &+= 1
                        } label: {
                            Label("Center", systemImage: "dot.viewfinder")
                        }
                    }
                }
        }
    }
}

struct SidebarList: View {
    let groups: [ModuleGroup]
    let onSelect: (Module) -> Void
    @State private var expanded: Set<UUID> = []
    
    var body: some View {
        List {
            ForEach(groups) { group in
                Section {
                    DisclosureGroup(isExpanded: Binding(
                        get: { expanded.contains(group.id) },
                        set: { new in
                            if new { expanded.insert(group.id) } else { expanded.remove(group.id) }
                        })
                    ) {
                        ForEach(group.items) { module in
                            Button {
                                onSelect(module)
                            } label: {
                                Label(module.name, systemImage: module.systemImage)
                                    .labelStyle(.titleAndIcon)
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        }
                    } label: {
                        Text(group.name)
                    }
                }
            }
        }
        .onAppear {
            if expanded.isEmpty {
                expanded = Set(groups.map { $0.id })
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Modules")
    }
}

struct TileView: View {
    let name: String
    let systemImage: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(name)
                .multilineTextAlignment(.center)
        }
        .frame(width: 140, height: 140)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ZoomingCanvasRepresentable: UIViewRepresentable {
    @Binding var addRequest: Module?
    @Binding var centerTrigger: Int
    
    class Coordinator {
        var lastCenterTrigger: Int = 0
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> ZoomingCanvasView {
        let view = ZoomingCanvasView()
        view.configure()
        return view
    }
    
    func updateUIView(_ uiView: ZoomingCanvasView, context: Context) {
        if let module = addRequest {
            uiView.addModuleAtCenter(module: module)
            DispatchQueue.main.async { addRequest = nil }
        }
        if context.coordinator.lastCenterTrigger != centerTrigger {
            context.coordinator.lastCenterTrigger = centerTrigger
            uiView.frameAllModules()
        }
    }
}
#Preview {
    MainScreen()
}
