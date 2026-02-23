import SwiftUI
import ClippyCore
import ClippyEngine

struct OrganizeView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            OrganizeHeaderView(appState: appState)
            Divider()
            if appState.selectedFolderURL == nil {
                EmptyFolderStateView()
            } else if appState.isScanning {
                ScanningStateView(appState: appState)
            } else if appState.isExecuting {
                ExecutingStateView()
            } else if let log = appState.executionLog {
                ExecutionResultsView(log: log, appState: appState)
            } else if let plan = appState.actionPlan {
                PlanPreviewView(plan: plan, appState: appState)
            } else if let result = appState.scanResult {
                ScanResultsView(result: result, appState: appState)
            } else {
                ReadyToScanView(appState: appState)
            }
        }
        .background(Color(NSColor.textBackgroundColor))
    }
}

struct OrganizeHeaderView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(UICopy.Header.organizeTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                stalenessLabel
            }
            Spacer()
            if let result = appState.scanResult {
                HStack(spacing: 16) {
                    StatBadge(value: "\(result.files.count)", label: "files")
                    StatBadge(value: "\(appState.rules.filter(\.isEnabled).count)", label: "active rules")
                }
            }
        }
        .padding(20)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private var stalenessLabel: some View {
        if let state = appState.stalenessState {
            switch state.stalenessLevel {
            case .fresh:
                Label(UICopy.Header.scanUpToDate, systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            case .possiblyStale:
                Label(UICopy.Header.scanMayBeStale, systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            case .stale:
                Label(UICopy.Header.scanRecommended, systemImage: "arrow.clockwise.circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        } else {
            Text(UICopy.Header.noScanYet)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct StatBadge: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3).fontWeight(.semibold)
            Text(label).font(.caption2).foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

struct EmptyFolderStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            Text(UICopy.EmptyState.noFolderTitle)
                .font(.title3)
                .fontWeight(.medium)
            Text(UICopy.EmptyState.noFolderBody)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            Text(UICopy.EmptyState.nothingWillHappen)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ReadyToScanView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(.accentColor.opacity(0.7))
            VStack(spacing: 8) {
                Text(UICopy.EmptyState.readyToScanTitle)
                    .font(.title3)
                    .fontWeight(.medium)
                Text(UICopy.EmptyState.readyToScanBody)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            Button {
                startScan()
            } label: {
                Label(UICopy.EmptyState.startScanButton, systemImage: "magnifyingglass")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Text(UICopy.EmptyState.ruleBasisHint(count: appState.rules.filter(\.isEnabled).count))
                .font(.caption)
                .foregroundColor(.secondary)
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
                    Task { await detectDuplicates(from: result.files) }
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

struct ScanningStateView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.5)
            Text(UICopy.Progress.scanningTitle).font(.headline)
            if let progress = appState.scanProgress {
                Text("\(progress.filesFound) files found...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let currentPath = progress.currentPath {
                    Text(currentPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .frame(maxWidth: 400)
                }
            }
            Text(UICopy.Progress.scanningBody)
                .font(.caption)
                .foregroundColor(.secondary)
            Button(role: .cancel) {
                appState.cancelScan()
            } label: {
                Label("Cancel Scan", systemImage: "xmark.circle")
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ExecutingStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView().scaleEffect(1.5)
            Text(UICopy.Progress.executingTitle).font(.headline)
            Text(UICopy.Progress.executingBody)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ScanResultsView: View {
    let result: ScanResult
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(UICopy.Header.filesAnalyzed(result.files.count)).font(.headline)
                    if let time = appState.stalenessState?.lastScanTime {
                        Text(UICopy.Header.lastScanned(timeAgo(time)))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(UICopy.Plan.createPlanButton) { createPlan() }
                    .buttonStyle(.borderedProminent)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
            Divider()
            List {
                ForEach(result.files.prefix(100)) { file in
                    FileRowView(file: file)
                }
                if result.files.count > 100 {
                    Text(UICopy.Common.andMore(result.files.count - 100))
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .listStyle(.inset)
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
        return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
    }
}

struct FileRowView: View {
    let file: FileDescriptor
    
    var body: some View {
        HStack(spacing: 12) {
            FileThumbnailView(file: file, size: 40, showPreviewOnTap: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName).lineLimit(1)
                Text(file.fileURL.deletingLastPathComponent().path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
            }
            Spacer()
            if let size = file.fileSize, !file.isDirectory {
                Text(formatBytes(size))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

struct PlanPreviewView: View {
    let plan: ActionPlan
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(UICopy.Plan.title).font(.headline)
                        Text(UICopy.Plan.reassurance).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button(UICopy.Plan.cancelButton) { appState.actionPlan = nil }
                            .buttonStyle(.bordered)
                        Button { executePlan() } label: {
                            Label(UICopy.Plan.approveButton, systemImage: "checkmark")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                PlanSummaryBadges(plan: plan)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
            Divider()
            List {
                ForEach(plan.actions) { action in
                    PlannedActionRowView(action: action)
                }
            }
            .listStyle(.inset)
            HStack {
                Image(systemName: "info.circle").foregroundColor(.secondary)
                Text(UICopy.Plan.confidenceHint).font(.caption).foregroundColor(.secondary)
                Spacer()
            }
            .padding(12)
            .background(Color(NSColor.windowBackgroundColor))
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

struct PlanSummaryBadges: View {
    let plan: ActionPlan
    var body: some View {
        let moveCount = plan.actions.filter { if case .move = $0.actionType { return true }; return false }.count
        let deleteCount = plan.actions.filter { if case .delete = $0.actionType { return true }; return false }.count
        let skipCount = plan.actions.filter { if case .skip = $0.actionType { return true }; return false }.count
        HStack(spacing: 8) {
            if moveCount > 0 { Badge(text: UICopy.Plan.summaryMoved(moveCount), color: .blue) }
            if deleteCount > 0 { Badge(text: UICopy.Plan.summaryTrash(deleteCount), color: .orange) }
            if skipCount > 0 { Badge(text: UICopy.Plan.summarySkipped(skipCount), color: .secondary) }
        }
    }
}

struct Badge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

struct PlannedActionRowView: View {
    let action: PlannedAction
    
    var body: some View {
        HStack(spacing: 12) {
            FileThumbnailView(file: action.targetFile, size: 36, showPreviewOnTap: true)
            actionIcon.frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(action.targetFile.fileName).fontWeight(.medium)
                    destinationText
                }
                Text(UICopy.Plan.reason(action.reason)).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    @ViewBuilder
    private var actionIcon: some View {
        switch action.actionType {
        case .move: Image(systemName: "arrow.right.circle.fill").foregroundColor(.blue)
        case .delete: Image(systemName: "trash.circle.fill").foregroundColor(.orange)
        case .skip: Image(systemName: "minus.circle.fill").foregroundColor(.secondary)
        case .copy: Image(systemName: "doc.on.doc.fill").foregroundColor(.green)
        case .rename: Image(systemName: "pencil.circle.fill").foregroundColor(.purple)
        }
    }
    
    @ViewBuilder
    private var destinationText: some View {
        switch action.actionType {
        case .move(let dest): Text("→ \(dest.lastPathComponent)").foregroundColor(.secondary)
        case .delete: Text("→ Trash").foregroundColor(.orange)
        case .skip: Text("(no action)").foregroundColor(.secondary).italic()
        case .copy(let dest): Text("→ copy to \(dest.lastPathComponent)").foregroundColor(.secondary)
        case .rename(let newName): Text("→ \(newName)").foregroundColor(.secondary)
        }
    }
}

struct ExecutionResultsView: View {
    let log: ExecutionLog
    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(UICopy.Execution.title).font(.headline)
                        summaryText
                    }
                    Spacer()
                    HStack(spacing: 12) {
                        Button(UICopy.Execution.undoButton) { performUndo() }.buttonStyle(.bordered)
                        Button(UICopy.Execution.doneButton) {
                            appState.executionLog = nil
                            appState.scanResult = nil
                        }.buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
            Divider()
            List {
                ForEach(log.entries, id: \.actionId) { entry in
                    ExecutionEntryRowView(entry: entry)
                }
            }
            .listStyle(.inset)
        }
    }
    
    private var summaryText: some View {
        let successCount = log.entries.filter { $0.outcome == .success }.count
        let failCount = log.entries.filter { $0.outcome == .failed }.count
        if failCount > 0 {
            return Text(UICopy.Execution.partialFailure)
                .font(.caption)
                .foregroundColor(.orange)
        } else {
            return Text(UICopy.Execution.successSummary(successCount))
                .font(.caption)
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

struct ExecutionEntryRowView: View {
    let entry: ExecutionLog.Entry
    
    var body: some View {
        HStack(spacing: 12) {
            outcomeIcon.frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.sourceURL.lastPathComponent).fontWeight(.medium)
                outcomeText
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var outcomeIcon: some View {
        switch entry.outcome {
        case .success: Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .skipped: Image(systemName: "arrow.uturn.right.circle.fill").foregroundColor(.orange)
        case .failed: Image(systemName: "xmark.circle.fill").foregroundColor(.red)
        }
    }
    
    @ViewBuilder
    private var outcomeText: some View {
        switch entry.outcome {
        case .success:
            if let dest = entry.destinationURL {
                Text(UICopy.Execution.movedTo(dest.lastPathComponent)).font(.caption).foregroundColor(.secondary)
            } else {
                Text(UICopy.Execution.completed).font(.caption).foregroundColor(.secondary)
            }
        case .skipped:
            Text(UICopy.Execution.skipped(entry.message ?? UICopy.Common.unknownReason))
                .font(.caption)
                .foregroundColor(.orange)
        case .failed:
            Text(UICopy.Execution.failed(entry.message ?? UICopy.Common.unknownReason))
                .font(.caption)
                .foregroundColor(.red)
        }
    }
}
