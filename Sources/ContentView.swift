import SwiftUI
import UniformTypeIdentifiers

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var rules: [Rule] = []
    @Published var selectedFolderURL: URL?
    @Published var scanResult: ScanResult?
    @Published var actionPlan: ActionPlan?
    @Published var executionLog: ExecutionLog?
    @Published var stalenessState: ScanStalenessState?
    
    @Published var isScanning = false
    @Published var isExecuting = false
    @Published var selectedTab: SidebarTab = .organize
    
    // Cancellation support
    @Published var scanProgress: ScanProgress?
    
    // Duplicate detection
    @Published var duplicateGroups: [[FileDescriptor]] = []
    @Published var showDuplicates = false
    
    // Rule filtering
    @Published var selectedRuleGroup: String?
    @Published var ruleSearchText: String = ""
    
    let scanner = FileScanner()
    let planner = Planner()
    let executor: ExecutionEngine
    let undoEngine = UndoEngine()
    let scanBridge = ScanBridge()
    let historyManager = HistoryManager()
    let searchManager = SearchManager()
    
    /// Computed property for filtered rules
    var filteredRules: [Rule] {
        rules.filter { rule in
            // Filter by group
            if let selectedGroup = selectedRuleGroup {
                if rule.group != selectedGroup {
                    return false
                }
            }
            
            // Filter by search text
            if !ruleSearchText.isEmpty {
                let searchLower = ruleSearchText.lowercased()
                let matchesName = rule.name.lowercased().contains(searchLower)
                let matchesDesc = rule.description.lowercased().contains(searchLower)
                let matchesTags = rule.tags.contains { $0.lowercased().contains(searchLower) }
                if !(matchesName || matchesDesc || matchesTags) {
                    return false
                }
            }
            
            return true
        }
    }
    
    /// All unique rule groups
    var ruleGroups: [String] {
        Array(Set(rules.compactMap { $0.group })).sorted()
    }
    
    /// Cancel the current scan operation
    func cancelScan() {
        Task {
            await scanner.cancel()
        }
    }
    
    init() {
        // Configure sandbox boundaries for file operations
        let home = NSHomeDirectory()
        let allowedPaths = [
            home,
            home + "/Documents",
            home + "/Downloads",
            home + "/Desktop",
            home + "/Pictures",
            home + "/Movies",
            home + "/Music"
        ]
        self.executor = ExecutionEngine(allowedSandboxPaths: allowedPaths)
        
        // Load default rules
        loadDefaultRules()
    }
    
    private func loadDefaultRules() {
        let home = NSHomeDirectory()
        
        rules = [
            // MARK: - Documents
            Rule(
                name: "Archive PDFs",
                description: "Move PDF files to the Archive folder",
                conditions: [.fileExtension(is: "pdf")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Archive/PDFs")),
                group: "Documents",
                tags: ["documents", "pdf", "archive"]
            ),
            Rule(
                name: "Organize CSV Files",
                description: "Move CSV data files to Data folder",
                conditions: [.fileExtension(is: "csv")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Data/CSV")),
                group: "Documents",
                tags: ["data", "csv"]
            ),
            Rule(
                name: "Organize Excel Files",
                description: "Move Excel spreadsheets to Spreadsheets folder",
                conditions: [.fileExtension(is: "xlsx")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Spreadsheets")),
                group: "Documents",
                tags: ["spreadsheet", "excel", "office"]
            ),
            Rule(
                name: "Organize Word Documents",
                description: "Move Word documents to Documents folder",
                conditions: [.fileExtension(is: "docx")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Word")),
                group: "Documents",
                tags: ["word", "office", "documents"]
            ),
            
            // MARK: - Images
            Rule(
                name: "Organize Screenshots",
                description: "Move screenshots to Screenshots folder",
                conditions: [.fileName(contains: "Screenshot")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Pictures/Screenshots")),
                group: "Images",
                tags: ["screenshot", "images"]
            ),
            Rule(
                name: "Organize JPG Photos",
                description: "Move JPG images to Photos folder",
                conditions: [.fileExtension(is: "jpg")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Pictures/Photos/JPG")),
                group: "Images",
                tags: ["photos", "jpg", "images"]
            ),
            Rule(
                name: "Organize JPEG Photos",
                description: "Move JPEG images to Photos folder",
                conditions: [.fileExtension(is: "jpeg")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Pictures/Photos/JPG")),
                group: "Images",
                tags: ["photos", "jpeg", "images"]
            ),
            Rule(
                name: "Organize PNG Images",
                description: "Move PNG images to Pictures folder",
                conditions: [.fileExtension(is: "png")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Pictures/PNG")),
                group: "Images",
                tags: ["images", "png"]
            ),
            Rule(
                name: "Organize HEIC Photos",
                description: "Move HEIC photos to Photos folder",
                conditions: [.fileExtension(is: "heic")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Pictures/Photos/HEIC")),
                group: "Images",
                tags: ["photos", "heic", "images"]
            ),
            Rule(
                name: "Organize GIF Images",
                description: "Move GIF files to GIFs folder",
                conditions: [.fileExtension(is: "gif")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Pictures/GIFs"))
            ),
            
            // MARK: - RAW Photos
            Rule(
                name: "Organize Sony RAW (ARW)",
                description: "Move Sony ARW raw files to RAW folder",
                conditions: [.fileExtension(is: "arw")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Pictures/RAW/Sony"))
            ),
            Rule(
                name: "Organize Canon RAW (CR2)",
                description: "Move Canon CR2 raw files to RAW folder",
                conditions: [.fileExtension(is: "cr2")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Pictures/RAW/Canon"))
            ),
            Rule(
                name: "Organize Nikon RAW (NEF)",
                description: "Move Nikon NEF raw files to RAW folder",
                conditions: [.fileExtension(is: "nef")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Pictures/RAW/Nikon"))
            ),
            Rule(
                name: "Organize DNG Files",
                description: "Move DNG raw files to RAW folder",
                conditions: [.fileExtension(is: "dng")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Pictures/RAW/DNG"))
            ),
            
            // MARK: - Code & Development
            Rule(
                name: "Organize Jupyter Notebooks",
                description: "Move Jupyter notebooks to Notebooks folder",
                conditions: [.fileExtension(is: "ipynb")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Code/Notebooks"))
            ),
            Rule(
                name: "Organize Python Files",
                description: "Move Python scripts to Code folder",
                conditions: [.fileExtension(is: "py")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Code/Python")),
                isEnabled: false
            ),
            Rule(
                name: "Organize JavaScript Files",
                description: "Move JavaScript files to Code folder",
                conditions: [.fileExtension(is: "js")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Code/JavaScript")),
                isEnabled: false
            ),
            Rule(
                name: "Organize Swift Files",
                description: "Move Swift files to Code folder",
                conditions: [.fileExtension(is: "swift")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Code/Swift")),
                isEnabled: false
            ),
            Rule(
                name: "Organize JSON Files",
                description: "Move JSON files to Data folder",
                conditions: [.fileExtension(is: "json")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Data/JSON")),
                isEnabled: false
            ),
            
            // MARK: - Videos
            Rule(
                name: "Organize MP4 Videos",
                description: "Move MP4 videos to Videos folder",
                conditions: [.fileExtension(is: "mp4")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Movies/Videos"))
            ),
            Rule(
                name: "Organize MOV Videos",
                description: "Move MOV videos to Videos folder",
                conditions: [.fileExtension(is: "mov")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Movies/Videos"))
            ),
            Rule(
                name: "Organize MKV Videos",
                description: "Move MKV videos to Videos folder",
                conditions: [.fileExtension(is: "mkv")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Movies/Videos"))
            ),
            Rule(
                name: "Organize AVI Videos",
                description: "Move AVI videos to Videos folder",
                conditions: [.fileExtension(is: "avi")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Movies/Videos"))
            ),
            
            // MARK: - Audio
            Rule(
                name: "Organize MP3 Music",
                description: "Move MP3 audio files to Music folder",
                conditions: [.fileExtension(is: "mp3")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Music/MP3"))
            ),
            Rule(
                name: "Organize WAV Audio",
                description: "Move WAV audio files to Music folder",
                conditions: [.fileExtension(is: "wav")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Music/WAV"))
            ),
            Rule(
                name: "Organize FLAC Audio",
                description: "Move FLAC audio files to Music folder",
                conditions: [.fileExtension(is: "flac")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Music/FLAC"))
            ),
            Rule(
                name: "Organize M4A Audio",
                description: "Move M4A audio files to Music folder",
                conditions: [.fileExtension(is: "m4a")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Music/M4A"))
            ),
            
            // MARK: - Archives
            Rule(
                name: "Organize ZIP Archives",
                description: "Move ZIP files to Archives folder",
                conditions: [.fileExtension(is: "zip")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Archives"))
            ),
            Rule(
                name: "Organize RAR Archives",
                description: "Move RAR files to Archives folder",
                conditions: [.fileExtension(is: "rar")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Archives"))
            ),
            Rule(
                name: "Organize 7Z Archives",
                description: "Move 7Z files to Archives folder",
                conditions: [.fileExtension(is: "7z")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Archives"))
            ),
            Rule(
                name: "Organize TAR.GZ Archives",
                description: "Move tar.gz files to Archives folder",
                conditions: [.fileExtension(is: "gz")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Archives"))
            ),
            Rule(
                name: "Organize DMG Files",
                description: "Move disk images to Installers folder",
                conditions: [.fileExtension(is: "dmg")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Installers"))
            ),
            Rule(
                name: "Organize PKG Files",
                description: "Move package installers to Installers folder",
                conditions: [.fileExtension(is: "pkg")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Installers"))
            ),
            
            // MARK: - Special Rules
            Rule(
                name: "Clean Large Downloads",
                description: "Move files larger than 100MB to a review folder",
                conditions: [.fileSize(largerThan: 100_000_000)],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/LargeFiles")),
                isEnabled: false
            ),
            Rule(
                name: "Organize Text Files",
                description: "Move text files to Notes folder",
                conditions: [.fileExtension(is: "txt")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Notes")),
                isEnabled: false
            ),
            Rule(
                name: "Organize Markdown Files",
                description: "Move markdown files to Notes folder",
                conditions: [.fileExtension(is: "md")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Notes")),
                isEnabled: false
            ),
            Rule(
                name: "Organize Log Files",
                description: "Move log files to Logs folder",
                conditions: [.fileExtension(is: "log")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Logs")),
                isEnabled: false
            ),
            Rule(
                name: "Organize SQL Files",
                description: "Move SQL files to Database folder",
                conditions: [.fileExtension(is: "sql")],
                outcome: .move(to: URL(fileURLWithPath: home + "/Documents/Code/Database")),
                isEnabled: false
            )
        ]
    }
}

enum SidebarTab: String, CaseIterable {
    case organize = "Organize"
    case rules = "Rules"
    case history = "History"
    case search = "Search"
    case statistics = "Statistics"
    
    var title: String {
        switch self {
        case .organize: return "Organize"
        case .rules: return "Rules"
        case .history: return "History"
        case .search: return "Search"
        case .statistics: return "Statistics"
        }
    }
    
    var icon: String {
        switch self {
        case .organize: return "folder.badge.gearshape"
        case .rules: return "list.bullet.rectangle.fill"
        case .history: return "clock.arrow.circlepath"
        case .search: return "magnifyingglass"
        case .statistics: return "chart.bar.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .organize: return DesignSystem.Colors.accentBlue
        case .rules: return DesignSystem.Colors.accentPurple
        case .history: return DesignSystem.Colors.accentOrange
        case .search: return DesignSystem.Colors.accentTeal
        case .statistics: return DesignSystem.Colors.accentPink
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        NavigationSplitView {
            ModernSidebarView(appState: appState)
        } detail: {
            switch appState.selectedTab {
            case .organize:
                OrganizeView(appState: appState)
            case .rules:
                RulesView(appState: appState)
            case .history:
                HistoryView(appState: appState)
            case .search:
                GlobalSearchView(appState: appState)
            case .statistics:
                StatisticsDashboardView(appState: appState)
            }
        }
        .frame(minWidth: DesignSystem.Layout.minWindowWidth, minHeight: DesignSystem.Layout.minWindowHeight)
        .background(DesignSystem.Colors.backgroundTertiary)
    }
}

// MARK: - Modern Sidebar

struct ModernSidebarView: View {
    @ObservedObject var appState: AppState
    @State private var isHoveringFolder = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo/App Header with modern gradient
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.accentBlue, DesignSystem.Colors.accentPurple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "folder.badge.gearshape.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: DesignSystem.Colors.accentBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clippy")
                            .font(DesignSystem.Typography.title3)
                            .foregroundColor(.primary)
                        Text("v1.0.0")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.xl)
            
            Divider()
                .padding(.horizontal, DesignSystem.Spacing.lg)
            
            // Navigation Menu
            ScrollView(showsIndicators: false) {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(SidebarTab.allCases, id: \.self) { tab in
                        SidebarTabButton(
                            tab: tab,
                            isSelected: appState.selectedTab == tab,
                            action: { appState.selectedTab = tab }
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
            
            Spacer()
            
            // Selected Enhanced Folder Card -
            VStack(spacing: DesignSystem.Spacing.md) {
                if let url = appState.selectedFolderURL {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Label {
                                Text("Current Folder")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)
                            } icon: {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(DesignSystem.Colors.accentBlue)
                                    .font(.system(size: 12))
                            }
                            Spacer()
                        }
                        
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            ZStack {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                    .fill(DesignSystem.Colors.accentBlue.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "folder.fill")
                                    .foregroundColor(DesignSystem.Colors.accentBlue)
                                    .font(.system(size: 14))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(url.lastPathComponent)
                                    .font(DesignSystem.Typography.body)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                    .foregroundColor(.primary)
                                
                                Text(url.path)
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.head)
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(DesignSystem.Colors.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                    .fill(
                                        LinearGradient(
                                            colors: [.white.opacity(0.4), .clear],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                    .stroke(DesignSystem.Colors.glassBorder, lineWidth: 1)
                            )
                    )
                    .shadow(color: DesignSystem.Shadows.sm.color, radius: DesignSystem.Shadows.sm.radius, x: 0, y: DesignSystem.Shadows.sm.y)
                }
                
                ModernFolderSelector(appState: appState)
            }
            .padding(DesignSystem.Spacing.lg)
            .background(DesignSystem.Colors.backgroundSecondary)
        }
        .frame(width: DesignSystem.Layout.sidebarWidth + 20)
        .background(DesignSystem.Colors.backgroundPrimary)
    }
}

struct SidebarTabButton: View {
    let tab: SidebarTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(isSelected ? tab.color : (isHovering ? tab.color.opacity(0.1) : Color.clear))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: tab.icon)
                        .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : tab.color)
                }
                
                Text(tab.title)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(tab.color)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.fast) {
                isHovering = hovering
            }
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return tab.color.opacity(0.08)
        } else if isHovering {
            return Color.primary.opacity(0.04)
        }
        return Color.clear
    }
}

struct ModernFolderSelector: View {
    @ObservedObject var appState: AppState
    @State private var showFileImporter = false
    @State private var isHovering = false
    
    var body: some View {
        Button {
            showFileImporter = true
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(isHovering ? DesignSystem.Colors.accentBlue.opacity(0.1) : DesignSystem.Colors.backgroundSecondary)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: appState.selectedFolderURL == nil ? "folder.badge.plus" : "arrow.triangle.2.circlepath")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.accentBlue)
                }
                
                Text(appState.selectedFolderURL == nil ? "Select Folder" : "Change Folder")
                    .font(DesignSystem.Typography.button)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm + 2)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(isHovering ? DesignSystem.Colors.primary.opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(isHovering ? DesignSystem.Colors.accentBlue.opacity(0.3) : DesignSystem.Colors.border, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                appState.selectedFolderURL = url
                appState.scanBridge.registerRoot(url)
                appState.stalenessState = ScanStalenessState(rootURL: url)
                appState.scanResult = nil
                appState.actionPlan = nil
                appState.executionLog = nil
            }
        }
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.fast) {
                isHovering = hovering
            }
        }
    }
}

// MARK: - Organize View

struct OrganizeView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            ModernOrganizeHeader(appState: appState)
            
            Divider()
            
            // Content
            if appState.selectedFolderURL == nil {
                ModernEmptyState(
                    icon: "folder.badge.questionmark",
                    title: "No Folder Selected",
                    description: "Select a folder from the sidebar to begin organizing your files. Nothing will happen to your files until you approve."
                )
            } else if appState.isScanning {
                ModernScanningView(appState: appState)
            } else if appState.isExecuting {
                ModernExecutingView()
            } else if let log = appState.executionLog {
                ModernExecutionResultsView(log: log, appState: appState)
            } else if let plan = appState.actionPlan {
                ModernPlanPreviewView(plan: plan, appState: appState)
            } else if let result = appState.scanResult {
                ModernScanResultsView(result: result, appState: appState)
            } else {
                ModernReadyToScanView(appState: appState)
            }
        }
        .background(DesignSystem.Colors.backgroundTertiary)
    }
}

struct ModernOrganizeHeader: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xl) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Text("Organize Files")
                        .font(DesignSystem.Typography.title1)
                        .foregroundColor(.primary)
                    
                    if let state = appState.stalenessState {
                        ScanStatusBadge(state: state)
                    }
                }
                
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Text(appState.selectedFolderURL?.path ?? "Select a folder to begin")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Quick stats with modern cards
            if let result = appState.scanResult {
                HStack(spacing: DesignSystem.Spacing.lg) {
                    ModernQuickStat(
                        value: "\(result.files.count)",
                        label: "files scanned",
                        icon: "doc.fill",
                        color: DesignSystem.Colors.accentBlue
                    )
                    
                    ModernQuickStat(
                        value: "\(appState.rules.filter(\.isEnabled).count)",
                        label: "active rules",
                        icon: "list.bullet.rectangle.fill",
                        color: DesignSystem.Colors.accentPurple
                    )
                }
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .background(DesignSystem.Colors.backgroundPrimary)
    }
}

struct ScanStatusBadge: View {
    let state: ScanStalenessState
    
    var body: some View {
        switch state.stalenessLevel {
        case .fresh:
            ModernBadge(text: "Up to date", color: .green, icon: "checkmark.seal.fill")
        case .possiblyStale:
            ModernBadge(text: "May be stale", color: .orange, icon: "clock.fill")
        case .stale:
            ModernBadge(text: "Scan recommended", color: .orange, icon: "arrow.clockwise")
        }
    }
}

struct ModernQuickStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(DesignSystem.Typography.title3)
                    .foregroundColor(.primary)
                Text(label)
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(color.opacity(0.06))
        )
    }
}

struct ModernReadyToScanView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxl) {
            Spacer()
            
            // Illustration with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.accentBlue.opacity(0.15), DesignSystem.Colors.accentPurple.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DesignSystem.Colors.accentBlue.opacity(0.2), DesignSystem.Colors.accentPurple.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DesignSystem.Colors.accentBlue, DesignSystem.Colors.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: DesignSystem.Colors.accentBlue.opacity(0.2), radius: 20, x: 0, y: 10)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Ready to Organize")
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(.primary)
                
                Text("Scanning will analyze \(appState.rules.filter(\.isEnabled).count) files and suggest changes based on your active rules.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)
            }
            
            Button(action: startScan) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                    Text("Start Scan")
                }
                .font(DesignSystem.Typography.button)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .buttonStyle(PrimaryButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func startScan() {
        guard let url = appState.selectedFolderURL else { return }
        
        appState.isScanning = true
        appState.scanResult = nil
        appState.actionPlan = nil
        appState.executionLog = nil
        appState.scanProgress = nil
        
        Task {
            let result = await appState.scanner.scan(folderURL: url) { progress in
                Task { @MainActor in
                    appState.scanProgress = progress
                }
            }
            
            await MainActor.run {
                appState.scanResult = result
                appState.isScanning = false
                appState.scanProgress = nil
                appState.scanBridge.markScanCompleted(for: url)
                appState.stalenessState = appState.scanBridge.staleness(for: url)
                
                appState.searchManager.updateData(files: result.files, rules: appState.rules, history: appState.historyManager.sessions)
                
                if !result.wasCancelled {
                    Task {
                        await detectDuplicates(from: result.files)
                    }
                }
            }
        }
    }
    
    private func detectDuplicates(from files: [FileDescriptor]) async {
        let sizeGroups = Dictionary(grouping: files) { $0.fileSize }
        
        var duplicates: [[FileDescriptor]] = []
        for (_, group) in sizeGroups where group.count > 1 {
            duplicates.append(group)
        }
        
        await MainActor.run {
            appState.duplicateGroups = duplicates.filter { $0.count > 1 }
        }
    }
}

struct ModernScanningView: View {
    @ObservedObject var appState: AppState
    
    private var progress: Double {
        guard let scanProgress = appState.scanProgress else { return 0 }
        return min(Double(scanProgress.filesFound) / 1000.0, 0.95)
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxl) {
            Spacer()
            
            ModernProgressView(
                title: "Scanning Folder...",
                subtitle: subtitleText,
                progress: progress,
                onCancel: { appState.cancelScan() }
            )
            .frame(maxWidth: 400)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var subtitleText: String {
        if let progress = appState.scanProgress {
            if let currentPath = progress.currentPath {
                return "\(progress.filesFound) files found\n\(currentPath)"
            }
            return "\(progress.filesFound) files found"
        }
        return "This may take a moment for large folders"
    }
}

struct ModernExecutingView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xxl) {
            Spacer()
            
            ModernProgressView(
                title: "Applying Changes...",
                subtitle: "Each action is logged for your review"
            )
            .frame(maxWidth: 400)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModernScanResultsView: View {
    let result: ScanResult
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Action bar
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("\(result.files.count) files analyzed")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(.primary)
                    
                    if let time = appState.stalenessState?.lastScanTime {
                        Text("Last scanned \(timeAgo(time))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: createPlan) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "wand.and.stars")
                        Text("Create Plan")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.backgroundPrimary)
            
            Divider()
            
            // File list
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(result.files.prefix(50)) { file in
                            ModernFileRow(file: file)
                                .padding(.horizontal, DesignSystem.Spacing.xl)
                        }
                        
                        if result.files.count > 50 {
                            Text("... and \(result.files.count - 50) more files")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                                .padding(.vertical, DesignSystem.Spacing.lg)
                        }
                    } header: {
                        HStack {
                            Text("File Name")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Size")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .trailing)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.backgroundTertiary)
                    }
                }
            }
        }
    }
    
    private func createPlan() {
        let enabledRules = appState.rules.filter(\.isEnabled)
        let plan = appState.planner.plan(files: result.files, rules: enabledRules)
        appState.actionPlan = plan
    }
    
    private func timeAgo(_ date: Date) -> String {
        let seconds = Int(-date.timeIntervalSinceNow)
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        return "\(hours)h ago"
    }
}

struct ModernFileRow: View {
    let file: FileDescriptor
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // Use FileThumbnailView for actual thumbnails
            FileThumbnailView(file: file, size: 36, showPreviewOnTap: true)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(file.fileName)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(file.fileURL.deletingLastPathComponent().path)
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            
            Spacer()
            
            if let size = file.fileSize, !file.isDirectory {
                Text(formatBytes(size))
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .frame(width: 80, alignment: .trailing)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(isHovering ? DesignSystem.Colors.primary.opacity(0.04) : Color.clear)
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.fast) {
                isHovering = hovering
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

struct ModernPlanPreviewView: View {
    let plan: ActionPlan
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Proposed Changes")
                            .font(DesignSystem.Typography.title1)
                            .foregroundColor(.primary)
                        
                        Text("Review before applying. Nothing will happen until you approve.")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Button(action: { appState.actionPlan = nil }) {
                            Text("Cancel")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button(action: executePlan) {
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "checkmark")
                                Text("Apply Changes")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                
                // Summary badges
                PlanSummaryBadges(plan: plan)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.backgroundPrimary)
            
            Divider()
            
            // Actions list
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xs, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(plan.actions) { action in
                            ModernPlannedActionRow(action: action)
                                .padding(.horizontal, DesignSystem.Spacing.xl)
                        }
                    } header: {
                        HStack {
                            Text("Action")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Reason")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.backgroundTertiary)
                    }
                }
            }
        }
    }
    
    private func executePlan() {
        appState.isExecuting = true
        
        let executor = appState.executor
        let folderPath = appState.selectedFolderURL?.path ?? "Unknown"
        
        DispatchQueue.global(qos: .userInitiated).async {
            let log = executor.execute(plan: plan)
            
            DispatchQueue.main.async {
                appState.executionLog = log
                appState.actionPlan = nil
                appState.isExecuting = false
                appState.historyManager.recordSession(from: log, folderPath: folderPath)
            }
        }
    }
}

struct ModernPlannedActionRow: View {
    let action: PlannedAction
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // File thumbnail
            FileThumbnailView(file: action.targetFile, size: 32, showPreviewOnTap: true)
            
            // Action icon
            actionIcon
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Text(action.targetFile.fileName)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    destinationText
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Because \(action.reason.lowercased())")
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(isHovering ? DesignSystem.Colors.primary.opacity(0.04) : Color.clear)
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.fast) {
                isHovering = hovering
            }
        }
    }
    
    @ViewBuilder
    private var actionIcon: some View {
        switch action.actionType {
        case .move:
            Image(systemName: "arrow.right.circle.fill")
                .foregroundColor(.blue)
        case .delete:
            Image(systemName: "trash.circle.fill")
                .foregroundColor(.orange)
        case .skip:
            Image(systemName: "minus.circle.fill")
                .foregroundColor(.secondary)
        case .copy:
            Image(systemName: "doc.on.doc.fill")
                .foregroundColor(.green)
        case .rename:
            Image(systemName: "pencil.circle.fill")
                .foregroundColor(.purple)
        }
    }
    
    @ViewBuilder
    private var destinationText: some View {
        switch action.actionType {
        case .move(let dest):
            Text("→ \(dest.lastPathComponent)")
        case .delete:
            Text("→ Trash")
                .foregroundColor(.orange)
        case .skip:
            Text("(no action)")
                .italic()
        case .copy(let dest):
            Text("→ copy to \(dest.lastPathComponent)")
        case .rename(let newName):
            Text("→ \(newName)")
        }
    }
}

struct ModernExecutionResultsView: View {
    let log: ExecutionLog
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: DesignSystem.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Execution Complete")
                            .font(DesignSystem.Typography.title1)
                            .foregroundColor(.primary)
                        
                        summaryText
                    }
                    
                    Spacer()
                    
                    HStack(spacing: DesignSystem.Spacing.md) {
                        Button(action: performUndo) {
                            Text("Undo Changes")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button(action: { appState.executionLog = nil; appState.scanResult = nil }) {
                            Text("Done")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.backgroundPrimary)
            
            Divider()
            
            // Results list
            ScrollView {
                LazyVStack(spacing: DesignSystem.Spacing.xs, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(log.entries, id: \.actionId) { entry in
                            ModernExecutionEntryRow(entry: entry)
                                .padding(.horizontal, DesignSystem.Spacing.xl)
                        }
                    } header: {
                        HStack {
                            Text("File")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Status")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 100, alignment: .trailing)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.backgroundTertiary)
                    }
                }
            }
        }
    }
    
    private var summaryText: some View {
        let successCount = log.entries.filter { $0.outcome == .success }.count
        let failCount = log.entries.filter { $0.outcome == .failed }.count
        
        if failCount > 0 {
            return Text("\(successCount) succeeded, \(failCount) failed")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.orange)
        } else {
            return Text("\(successCount) changes applied successfully")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.green)
        }
    }
    
    private func performUndo() {
        appState.isExecuting = true
        
        let undoEngine = appState.undoEngine
        DispatchQueue.global(qos: .userInitiated).async {
            let _ = undoEngine.undo(log: log)
            
            DispatchQueue.main.async {
                appState.executionLog = nil
                appState.scanResult = nil
                appState.isExecuting = false
            }
        }
    }
}

struct ModernExecutionEntryRow: View {
    let entry: ExecutionLog.Entry
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            outcomeIcon
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                Text(entry.sourceURL.lastPathComponent)
                    .font(DesignSystem.Typography.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                outcomeText
            }
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(isHovering ? DesignSystem.Colors.primary.opacity(0.04) : Color.clear)
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.fast) {
                isHovering = hovering
            }
        }
    }
    
    @ViewBuilder
    private var outcomeIcon: some View {
        switch entry.outcome {
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .skipped:
            Image(systemName: "arrow.uturn.right.circle.fill")
                .foregroundColor(.orange)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }
    
    @ViewBuilder
    private var outcomeText: some View {
        switch entry.outcome {
        case .success:
            if let dest = entry.destinationURL {
                Text("Moved to \(dest.lastPathComponent)")
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundColor(.secondary)
            } else {
                Text("Completed")
                    .font(DesignSystem.Typography.captionSmall)
                    .foregroundColor(.secondary)
            }
        case .skipped:
            Text(entry.message ?? "Unknown reason")
                .font(DesignSystem.Typography.captionSmall)
                .foregroundColor(.orange)
        case .failed:
            Text(entry.message ?? "Unknown error")
                .font(DesignSystem.Typography.captionSmall)
                .foregroundColor(.red)
        }
    }
}

struct PlanSummaryBadges: View {
    let plan: ActionPlan
    
    var body: some View {
        let moveCount = plan.actions.filter { if case .move = $0.actionType { return true }; return false }.count
        let deleteCount = plan.actions.filter { if case .delete = $0.actionType { return true }; return false }.count
        let skipCount = plan.actions.filter { if case .skip = $0.actionType { return true }; return false }.count
        
        HStack(spacing: DesignSystem.Spacing.sm) {
            if moveCount > 0 {
                ModernBadge(text: "\(moveCount) move", color: .blue, icon: "arrow.right")
            }
            if deleteCount > 0 {
                ModernBadge(text: "\(deleteCount) delete", color: .orange, icon: "trash")
            }
            if skipCount > 0 {
                ModernBadge(text: "\(skipCount) skip", color: .secondary, icon: "minus")
            }
        }
    }
}


