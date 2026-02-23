import SwiftUI

// MARK: - Modern History View

struct HistoryView: View {
    @ObservedObject var appState: AppState
    @State private var sessionToUndo: HistorySession?
    @State private var showUndoAlert = false
    @State private var undoResult: HistoryManager.UndoResult?
    @State private var showUndoResult = false
    @State private var isUndoing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: DesignSystem.Spacing.xl) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("History")
                        .font(DesignSystem.Typography.title1)
                        .foregroundColor(.primary)
                    
                    Text("View and undo past file operations")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !appState.historyManager.sessions.isEmpty {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ModernQuickStat(
                            value: "\(appState.historyManager.sessions.count)",
                            label: "sessions",
                            icon: "clock.fill",
                            color: DesignSystem.Colors.accentOrange
                        )
                        
                        ModernQuickStat(
                            value: "\(appState.historyManager.sessions.reduce(0) { $0 + $1.items.count })",
                            label: "files processed",
                            icon: "doc.fill",
                            color: DesignSystem.Colors.accentBlue
                        )
                    }
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Colors.backgroundPrimary)
            
            Divider()
            
            // Content
            if appState.historyManager.sessions.isEmpty {
                ModernEmptyState(
                    icon: "clock.arrow.circlepath",
                    title: "No History Yet",
                    description: "Actions you perform will appear here. You'll see what happened, when, and where files are now.",
                    color: DesignSystem.Colors.accentOrange
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignSystem.Spacing.md) {
                        ForEach(appState.historyManager.sessions) { session in
                            sessionCardView(for: session)
                                .padding(.horizontal, DesignSystem.Spacing.xl)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.md)
                }
            }
        }
        .background(DesignSystem.Colors.backgroundTertiary)
        .alert("Undo Changes?", isPresented: $showUndoAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Undo", role: .destructive) {
                performUndo()
            }
        } message: {
            if let session = sessionToUndo {
                Text("This will restore \(session.items.count) files to their original locations. This action cannot be undone.")
            }
        }
        .sheet(isPresented: $showUndoResult) {
            if let result = undoResult {
                UndoResultView(result: result) {
                    showUndoResult = false
                    undoResult = nil
                }
            }
        }
    }
    
    private func performUndo() {
        guard let session = sessionToUndo else { return }
        
        isUndoing = true
        
        Task {
            let result = appState.historyManager.undoSession(session)
            
            await MainActor.run {
                undoResult = result
                showUndoResult = true
                isUndoing = false
                sessionToUndo = nil
            }
        }
    }
    
    @ViewBuilder
    private func sessionCardView(for session: HistorySession) -> some View {
        HistorySessionCard(
            session: session,
            onUndo: {
                sessionToUndo = session
                showUndoAlert = true
            },
            onRevealInFinder: { path in
                appState.historyManager.revealInFinder(path: path)
            }
        )
    }
}

// MARK: - Undo Result View

struct UndoResultView: View {
    let result: HistoryManager.UndoResult
    let onDismiss: () -> Void
    
    private var isFullyRestored: Bool { result.isFullyRestored }
    private var iconColor: Color { isFullyRestored ? .green : .orange }
    private var backgroundColor: Color { isFullyRestored ? Color.green.opacity(0.12) : Color.orange.opacity(0.12) }
    private var iconName: String { isFullyRestored ? "checkmark.circle.fill" : "exclamationmark.triangle.fill" }
    private var titleText: String { isFullyRestored ? "Changes Undone" : "Undo Completed" }
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Details")
                .font(DesignSystem.Typography.title3)
                .foregroundColor(.primary)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    ForEach(result.details.prefix(10)) { detail in
                        detailRow(for: detail)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    @ViewBuilder
    private func detailRow(for detail: HistoryManager.UndoItemResult) -> some View {
        let iconResult = iconForOutcome(detail.outcome)
        let colorResult = colorForOutcome(detail.outcome)
        
        HStack {
            Image(systemName: iconResult)
                .foregroundColor(colorResult)
                .font(.system(size: 12))
            
            Text(detail.fileName)
                .font(DesignSystem.Typography.caption)
                .lineLimit(1)
            
            Spacer()
            
            Text(detail.message)
                .font(DesignSystem.Typography.captionSmall)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
    
    private func iconForOutcome(_ outcome: HistoryManager.UndoOutcome) -> String {
        switch outcome {
        case .restored: return "checkmark.circle.fill"
        case .skipped: return "minus.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    private func colorForOutcome(_ outcome: HistoryManager.UndoOutcome) -> Color {
        switch outcome {
        case .restored: return .green
        case .skipped: return .orange
        case .failed: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // Header
            HStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Icon
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 100, height: 100)
                
                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundColor(iconColor)
            }
            
            // Title
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(titleText)
                    .font(DesignSystem.Typography.title1)
                    .foregroundColor(.primary)
                
                Text(result.summary)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Stats
            HStack(spacing: DesignSystem.Spacing.xl) {
                StatItem(count: result.restoredCount, label: "Restored", color: .green)
                StatItem(count: result.skippedCount, label: "Skipped", color: .orange)
                StatItem(count: result.failedCount, label: "Failed", color: .red)
            }
            
            // Details
            if !result.details.isEmpty {
                detailsSection
            }
            
            // Done button
            Button("Done") {
                onDismiss()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(DesignSystem.Spacing.xxl)
        .frame(width: 450, height: 550)
    }
}

struct StatItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Text("\(count)")
                .font(DesignSystem.Typography.title2)
                .foregroundColor(color)
            Text(label)
                .font(DesignSystem.Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
    }
}

struct HistorySessionCard: View {
    let session: HistorySession
    var onUndo: (() -> Void)?
    var onRevealInFinder: ((String) -> Void)?
    @State private var isExpanded = false
    @State private var isHovering = false
    
    private var canUndo: Bool {
        session.items.contains { $0.outcome == .success && ($0.actionType == .moved || $0.actionType == .deleted || $0.actionType == .renamed) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icon based on outcome
                ZStack {
                    Circle()
                        .fill(statusColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: statusIcon)
                        .font(.system(size: 18))
                        .foregroundColor(statusColor)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text(session.formattedDate)
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.medium)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("\(session.items.count) files")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        
                        Text("\(session.successCount) succeeded")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if session.successCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                            Text("\(session.successCount)")
                                .font(DesignSystem.Typography.captionSmall)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(Color.green.opacity(0.12))
                        .foregroundColor(.green)
                        .cornerRadius(DesignSystem.CornerRadius.full)
                    }
                    if session.failedCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                            Text("\(session.failedCount)")
                                .font(DesignSystem.Typography.captionSmall)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(Color.red.opacity(0.12))
                        .foregroundColor(.red)
                        .cornerRadius(DesignSystem.CornerRadius.full)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Divider()
                    .padding(.vertical, DesignSystem.Spacing.xs)
                
                // Action buttons
                HStack(spacing: DesignSystem.Spacing.md) {
                    if canUndo {
                        Button(action: { onUndo?() }) {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                Text("Undo Changes")
                            }
                            .font(DesignSystem.Typography.button)
                        }
                        .buttonStyle(SecondaryButtonStyle(isDestructive: true))
                    }
                    
                    Spacer()
                }
                .padding(.bottom, DesignSystem.Spacing.sm)
                
                // Files list
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    ForEach(session.items.prefix(10)) { item in
                        HistoryItemRow(item: item, onRevealInFinder: onRevealInFinder)
                    }
                    
                    if session.items.count > 10 {
                        Text("+ \(session.items.count - 10) more items")
                            .font(DesignSystem.Typography.captionSmall)
                            .foregroundColor(.secondary)
                            .padding(.top, DesignSystem.Spacing.xs)
                    }
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.backgroundPrimary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(isHovering ? DesignSystem.Colors.primary.opacity(0.15) : DesignSystem.Colors.border, lineWidth: 1)
        )
        .shadow(color: isHovering ? DesignSystem.Shadows.sm.color : Color.clear, radius: DesignSystem.Shadows.sm.radius, x: 0, y: DesignSystem.Shadows.sm.y)
        .onTapGesture {
            withAnimation(DesignSystem.Animation.spring) {
                isExpanded.toggle()
            }
        }
        .onHover { hovering in
            withAnimation(DesignSystem.Animation.fast) {
                isHovering = hovering
            }
        }
    }
    
    private var statusColor: Color {
        if session.failedCount > 0 {
            return .orange
        }
        return .green
    }
    
    private var statusIcon: String {
        if session.failedCount > 0 {
            return "exclamationmark.triangle.fill"
        }
        return "checkmark.circle.fill"
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let item: HistoryItem
    var onRevealInFinder: ((String) -> Void)?
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // Status icon
            Image(systemName: outcomeIcon)
                .foregroundColor(outcomeColor)
                .font(.system(size: 12))
                .frame(width: 20)
            
            // File name
            VStack(alignment: .leading, spacing: 2) {
                Text(item.fileName)
                    .font(DesignSystem.Typography.caption)
                    .lineLimit(1)
                
                if let currentPath = item.currentPath {
                    Text(currentPath)
                        .font(DesignSystem.Typography.captionSmall)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.head)
                }
            }
            
            Spacer()
            
            // Action type badge
            Text(item.actionType.rawValue)
                .font(DesignSystem.Typography.captionSmall)
                .padding(.horizontal, DesignSystem.Spacing.xs)
                .padding(.vertical, 2)
                .background(actionColor.opacity(0.12))
                .foregroundColor(actionColor)
                .cornerRadius(DesignSystem.CornerRadius.xs)
            
            // Reveal in Finder button (on hover)
            if isHovering, let currentPath = item.currentPath {
                Button(action: { onRevealInFinder?(currentPath) }) {
                    Image(systemName: "folder")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .background(isHovering ? Color.secondary.opacity(0.05) : Color.clear)
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .onHover { hovering in
            isHovering = hovering
        }
    }
    
    private var outcomeIcon: String {
        switch item.outcome {
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .skipped:
            return "minus.circle.fill"
        }
    }
    
    private var outcomeColor: Color {
        switch item.outcome {
        case .success:
            return .green
        case .failed:
            return .red
        case .skipped:
            return .secondary
        }
    }
    
    private var actionColor: Color {
        switch item.actionType {
        case .moved:
            return .blue
        case .copied:
            return .green
        case .deleted:
            return .orange
        case .renamed:
            return .purple
        case .skipped:
            return .secondary
        }
    }
}
